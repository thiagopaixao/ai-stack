#!/usr/bin/env bash
# ============================================================================
# ai-stack installer — recria a stack de codificação com IA em $AI_STACK_HOME
# Uso: ./install.sh [opções]      (veja --help)
# ============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR

# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"
# shellcheck source=lib/versions.sh
. "$REPO_DIR/lib/versions.sh"

AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
DRY_RUN=0; FORCE=0; ASSUME_YES=0
CONFIG_ONLY=0; ALL_OPTIONAL=0; SHELL_FLAG=0
WITH_LIST=""; ONLY_LIST=""; SKIP_LIST=""
LIST_ONLY=0

usage() {
  cat <<'USAGE'
ai-stack installer

Uso: ./install.sh [opções]

  --home <dir>        Destino da stack (padrão: $AI_STACK_HOME ou ~/ai-stack)
  -y, --yes           Não-interativo (sem perguntas)
  --dry-run           Mostra o que seria feito, sem alterar nada
  --force             Sobrescreve arquivos protegidos (serena_config.yml) e
                      substitui symlinks estrangeiros (sempre com backup)
  --config-only       Só configuração, sem downloads: módulos 01,09,11,12,13,14,15
  --with <lista>      Módulos opcionais, separados por vírgula:
                      9router,headroom,herdr,paseo,bun,oh-my-openagent
  --all-optional      Todos os opcionais (exceto o legado oh-my-openagent)
  --only <módulos>    Executa somente estes módulos (nome ou número, vírgulas)
  --skip <módulos>    Pula estes módulos
  --shell             Instala o bloco ai-stack no ~/.bashrc
  --list              Lista os módulos disponíveis
  -h, --help          Esta ajuda

Versões são fixadas em lib/versions.sh e podem ser sobrescritas por ambiente
(ex.: NODE_VERSION=22.11.0 ./install.sh).
USAGE
}

# ------------------------------------------------------------ module registry
MODULE_FILES=()   # ordenados
MODULE_NUMS=()
MODULE_NAMES=()

load_registry() {
  local f base num name
  for f in "$REPO_DIR"/installer/modules/[0-9][0-9]-*.sh; do
    [ -f "$f" ] || continue
    base="$(basename "$f" .sh)"
    num="${base%%-*}"; name="${base#*-}"
    MODULE_FILES+=("$f"); MODULE_NUMS+=("$num"); MODULE_NAMES+=("$name")
    # shellcheck disable=SC1090
    . "$f"
  done
}

# resolve_token TOKEN -> prints module number; returns 1 if unknown
resolve_token() {
  local t="$1" i
  for i in "${!MODULE_NUMS[@]}"; do
    if [ "$t" = "${MODULE_NUMS[$i]}" ] || [ "$t" = "${MODULE_NAMES[$i]}" ] \
       || [ "$t" = "${MODULE_NAMES[$i]#optional-}" ] \
       || [ "$t" = "${MODULE_NUMS[$i]}-${MODULE_NAMES[$i]}" ]; then
      echo "${MODULE_NUMS[$i]}"; return 0
    fi
  done
  return 1
}

# resolve_list "a,b,c" -> prints module numbers (return 2 on unknown token)
resolve_list() {
  local list="$1" tok num out=""
  local IFS=','
  for tok in $list; do
    tok="${tok// /}"
    [ -n "$tok" ] || continue
    if ! num="$(resolve_token "$tok")"; then
      err "Módulo desconhecido: '$tok' (veja --list)"; return 2
    fi
    out="$out $num"
  done
  echo "$out"
}

list_modules() {
  local i kind
  printf '%-4s %-26s %s\n' "NUM" "NOME" "PADRÃO"
  for i in "${!MODULE_NUMS[@]}"; do
    case "${MODULE_NUMS[$i]}" in
      2?) kind="opcional (--with ${MODULE_NAMES[$i]#optional-})" ;;
      16) kind="com --shell (ou pergunta interativa)" ;;
      *)  kind="sim" ;;
    esac
    printf '%-4s %-26s %s\n' "${MODULE_NUMS[$i]}" "${MODULE_NAMES[$i]}" "$kind"
  done
}

# --------------------------------------------------------------------- args
while [ $# -gt 0 ]; do
  case "$1" in
    --home)         [ $# -ge 2 ] || { err "--home requer um diretório"; exit 2; }
                    AI_STACK_HOME="$2"; shift 2 ;;
    --home=*)       AI_STACK_HOME="${1#*=}"; shift ;;
    -y|--yes)       ASSUME_YES=1; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    --force)        FORCE=1; shift ;;
    --config-only)  CONFIG_ONLY=1; shift ;;
    --with)         [ $# -ge 2 ] || { err "--with requer uma lista"; exit 2; }
                    WITH_LIST="${WITH_LIST:+$WITH_LIST,}$2"; shift 2 ;;
    --with=*)       WITH_LIST="${WITH_LIST:+$WITH_LIST,}${1#*=}"; shift ;;
    --all-optional) ALL_OPTIONAL=1; shift ;;
    --only)         [ $# -ge 2 ] || { err "--only requer uma lista"; exit 2; }
                    ONLY_LIST="${ONLY_LIST:+$ONLY_LIST,}$2"; shift 2 ;;
    --only=*)       ONLY_LIST="${ONLY_LIST:+$ONLY_LIST,}${1#*=}"; shift ;;
    --skip)         [ $# -ge 2 ] || { err "--skip requer uma lista"; exit 2; }
                    SKIP_LIST="${SKIP_LIST:+$SKIP_LIST,}$2"; shift 2 ;;
    --skip=*)       SKIP_LIST="${SKIP_LIST:+$SKIP_LIST,}${1#*=}"; shift ;;
    --shell)        SHELL_FLAG=1; shift ;;
    --list)         LIST_ONLY=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              err "Opção desconhecida: $1"; usage >&2; exit 2 ;;
  esac
done

case "$AI_STACK_HOME" in
  "~"|"~/"*) AI_STACK_HOME="$HOME${AI_STACK_HOME#\~}" ;;
esac
case "$AI_STACK_HOME" in
  /*) ;;
  *) AI_STACK_HOME="$PWD/$AI_STACK_HOME" ;;
esac
export AI_STACK_HOME DRY_RUN FORCE ASSUME_YES CONFIG_ONLY SHELL_FLAG TS

load_registry
if [ "$LIST_ONLY" = "1" ]; then list_modules; exit 0; fi

# ---------------------------------------------------------------- selection
declare -A SEL=()
if [ -n "$ONLY_LIST" ]; then
  RES="$(resolve_list "$ONLY_LIST")" || exit 2
  for n in $RES; do SEL[$n]=1; done
else
  if [ "$CONFIG_ONLY" = "1" ]; then
    for n in 01 09 11 12 13 14 15; do SEL[$n]=1; done
    [ "$SHELL_FLAG" = "1" ] && SEL[16]=1
  else
    for n in "${MODULE_NUMS[@]}"; do
      case "$n" in 2?) ;; *) SEL[$n]=1 ;; esac
    done
  fi
  if [ "$ALL_OPTIONAL" = "1" ]; then
    for n in 20 21 22 23 24; do SEL[$n]=1; done
  fi
  if [ -n "$WITH_LIST" ]; then
    RES="$(resolve_list "$WITH_LIST")" || exit 2
    for n in $RES; do
      case "$n" in 2?) SEL[$n]=1 ;; *) warn "--with: '$n' não é módulo opcional (ignorado)" ;; esac
    done
  fi
fi
if [ -n "$SKIP_LIST" ]; then
  RES="$(resolve_list "$SKIP_LIST")" || exit 2
  for n in $RES; do unset 'SEL[$n]'; done
fi

# ------------------------------------------------------------------ logging
if [ "$DRY_RUN" != "1" ]; then
  mkdir -p "$AI_STACK_HOME/platform/logs"
  LOG_FILE="$AI_STACK_HOME/platform/logs/install-$TS.log"
  exec > >(tee -a "$LOG_FILE") 2>&1
fi

header "ai-stack installer"
info "Repo:    $REPO_DIR"
info "Destino: $AI_STACK_HOME"
[ "$DRY_RUN" = "1" ] && warn "DRY-RUN: nada será alterado"
[ "$CONFIG_ONLY" = "1" ] && info "Modo --config-only (sem downloads)"
[ -n "${LOG_FILE:-}" ] && info "Log:     $LOG_FILE"

PLAN=""
for i in "${!MODULE_NUMS[@]}"; do
  [ -n "${SEL[${MODULE_NUMS[$i]}]:-}" ] && PLAN="$PLAN ${MODULE_NUMS[$i]}-${MODULE_NAMES[$i]}"
done
info "Módulos:${PLAN:- (nenhum)}"

if [ "$ASSUME_YES" != "1" ] && [ "$DRY_RUN" != "1" ] && [ -t 0 ]; then
  confirm "Continuar?" y || { info "Abortado."; exit 0; }
fi

# ---------------------------------------------------------------------- run
OK_MODS=(); FAILED_MODS=()
for i in "${!MODULE_NUMS[@]}"; do
  num="${MODULE_NUMS[$i]}"; name="${MODULE_NAMES[$i]}"
  [ -n "${SEL[$num]:-}" ] || continue
  fn="module_${name//-/_}"
  header "$num — $name"
  if ! declare -F "$fn" >/dev/null; then
    err "Função $fn não definida em ${MODULE_FILES[$i]}"
    FAILED_MODS+=("$num-$name"); continue
  fi
  set +e
  ( set -e; "$fn" )
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    OK_MODS+=("$num-$name")
  else
    err "Módulo $num-$name falhou (rc=$rc)"
    FAILED_MODS+=("$num-$name")
    case "$num" in
      00|01) err "Módulo essencial falhou; abortando."; break ;;
    esac
  fi
done

header "Resumo"
ok "Concluídos: ${#OK_MODS[@]}"
if [ "${#FAILED_MODS[@]}" -gt 0 ]; then
  err "Falharam: ${FAILED_MODS[*]}"
  exit 1
fi
[ "$DRY_RUN" = "1" ] && info "Dry-run concluído."
exit 0
