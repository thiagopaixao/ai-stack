#!/usr/bin/env bash
# ============================================================================
# ai-stack uninstaller — NÃO destrutivo por padrão.
#   - remove symlinks criados (somente se apontarem para dentro de $AI_STACK_HOME)
#   - remove o bloco ai-stack do ~/.bashrc
#   - NÃO apaga $AI_STACK_HOME (dados, memória, workspaces) sem --purge
# ============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR
# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
PURGE=0

usage() {
  cat <<'USAGE'
Uso: ./uninstall.sh [opções]

  --home <dir>   Stack a remover (padrão: $AI_STACK_HOME ou ~/ai-stack)
  --dry-run      Mostra o que seria feito
  -y, --yes      Não pergunta
  --purge        Também remove $AI_STACK_HOME (pede confirmação; recusa se
                 workspaces/ não estiver vazio, a menos que use --force)
  --force        Permite --purge com workspaces/ não vazio
  -h, --help     Esta ajuda

Obs.: o conteúdo dos diretórios linkados (dados do OpenCode, memória do
Bitloops etc.) permanece em $AI_STACK_HOME; os symlinks são apenas removidos.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --home)    [ $# -ge 2 ] || { err "--home requer um diretório"; exit 2; }
               AI_STACK_HOME="$2"; shift 2 ;;
    --home=*)  AI_STACK_HOME="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -y|--yes)  ASSUME_YES=1; shift ;;
    --purge)   PURGE=1; shift ;;
    --force)   FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)         err "Opção desconhecida: $1"; usage >&2; exit 2 ;;
  esac
done
export AI_STACK_HOME DRY_RUN FORCE ASSUME_YES

header "ai-stack uninstall"
info "Stack: $AI_STACK_HOME"
is_dry && warn "DRY-RUN: nada será alterado"

LINKS=(
  "$HOME/.config/opencode"
  "$HOME/.local/share/opencode"
  "$HOME/.cache/opencode"
  "$HOME/.local/state/opencode"
  "$HOME/.opencode"
  "$HOME/.local/share/bitloops"
  "$HOME/.local/share/uv"
  "$HOME/.config/bitloops/bitloops"
)

for l in "${LINKS[@]}"; do
  if [ -L "$l" ]; then
    tgt="$(readlink "$l")"
    case "$tgt" in
      "$AI_STACK_HOME"/*|"$AI_STACK_HOME")
        run rm -f "$l"; is_dry || ok "removido symlink $l" ;;
      *) warn "ignorado (aponta para fora da stack): $l -> $tgt" ;;
    esac
  fi
done

remove_block "$HOME/.bashrc" "# >>> ai-stack >>>" "# <<< ai-stack <<<"

if [ "$PURGE" = "1" ]; then
  # sanity: never purge /, $HOME or empty
  case "$AI_STACK_HOME" in
    ""|"/"|"$HOME"|"$HOME/") err "Recusado: caminho perigoso para --purge: '$AI_STACK_HOME'"; exit 1 ;;
  esac
  if [ ! -d "$AI_STACK_HOME" ]; then
    info "$AI_STACK_HOME não existe; nada a remover"
  else
    if [ -d "$AI_STACK_HOME/workspaces" ] && [ -n "$(ls -A "$AI_STACK_HOME/workspaces" 2>/dev/null)" ] \
       && [ "$FORCE" != "1" ]; then
      err "workspaces/ não está vazio; recusando --purge (use --force se tem certeza)"
      exit 1
    fi
    if ! is_dry && ! confirm "REMOVER DEFINITIVAMENTE $AI_STACK_HOME (inclui memória, índices, secrets.env)?" n; then
      info "Purge cancelado."; exit 0
    fi
    run rm -rf "$AI_STACK_HOME"
    is_dry || ok "removido $AI_STACK_HOME"
  fi
else
  info "Dados mantidos em $AI_STACK_HOME (use --purge para remover)."
fi
info "Binários em ~/.local/bin (uv, serena, herdr...) e ~/.serena não foram tocados."
