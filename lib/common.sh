#!/usr/bin/env bash
# common.sh — Shared helpers for install.sh / uninstall.sh / modules.
# (sourced; do not execute)
#
# Global switches (exported by the entrypoints):
#   DRY_RUN=1     print what would happen, change nothing
#   FORCE=1       overwrite "protected" user files (serena config) and replace
#                 foreign symlinks; also bypasses uninstall safety checks
#   ASSUME_YES=1  never prompt
#
# File deployment policy (deploy_file / render_template):
#   - dst missing            -> copy
#   - dst identical          -> skip (no-op)
#   - dst differs            -> backup to <dst>.bak-<timestamp>, then overwrite
#   FORCE does not disable backups: nothing is ever overwritten without a copy.
#   Files that must never be clobbered silently (serena_config.yml, secrets.env)
#   use deploy_file_once / render_template_once: only written when missing,
#   or when FORCE=1 (still with backup).

: "${DRY_RUN:=0}" "${FORCE:=0}" "${ASSUME_YES:=0}"
: "${TS:=$(date +%Y%m%d-%H%M%S)}"

# ---------------------------------------------------------------- output ----
if [ -t 1 ]; then
  C_RED=$'\033[0;31m'; C_GREEN=$'\033[0;32m'; C_YELLOW=$'\033[1;33m'
  C_BLUE=$'\033[0;34m'; C_NC=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_NC=""
fi

info()   { printf '%s[ai-stack]%s %s\n' "$C_BLUE" "$C_NC" "$*"; }
ok()     { printf '%s[ok]%s %s\n' "$C_GREEN" "$C_NC" "$*"; }
warn()   { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_NC" "$*" >&2; }
err()    { printf '%s[x]%s %s\n' "$C_RED" "$C_NC" "$*" >&2; }
dryrun() { printf '%s[dry-run]%s %s\n' "$C_YELLOW" "$C_NC" "$*"; }
header() {
  printf '\n%s== %s ==%s\n' "$C_BLUE" "$*" "$C_NC"
}

is_dry() { [ "${DRY_RUN:-0}" = "1" ]; }

# ------------------------------------------------------------------ exec ----
# run CMD ARGS...  — executes (or prints under DRY_RUN)
run() {
  if is_dry; then
    dryrun "$*"
    return 0
  fi
  "$@"
}

# run_sh "shell string" — same as run, for pipelines / redirections
run_sh() {
  if is_dry; then
    dryrun "$1"
    return 0
  fi
  bash -c "$1"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Comando obrigatório não encontrado: $1"; return 1; }
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  # confirm "question" [default y|n] — honors ASSUME_YES; non-tty => default
  local q="$1" def="${2:-n}" reply
  if [ "${ASSUME_YES:-0}" = "1" ]; then return 0; fi
  if [ ! -t 0 ]; then [ "$def" = "y" ]; return; fi
  read -r -p "$q [$([ "$def" = y ] && echo Y/n || echo y/N)] " reply || return 1
  reply="${reply:-$def}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ---------------------------------------------------------------- files -----
# backup_file FILE — copy to FILE.bak-<ts> if FILE exists (differs check is done by callers)
backup_file() {
  local f="$1"
  [ -e "$f" ] || return 0
  if is_dry; then dryrun "backup $f -> $f.bak-$TS"; return 0; fi
  cp -a "$f" "$f.bak-$TS"
  info "backup: $f.bak-$TS"
}

# deploy_file SRC DST [MODE] — see policy at top of file
deploy_file() {
  local src="$1" dst="$2" mode="${3:-}"
  if [ ! -f "$src" ]; then
    warn "asset ausente: $src (ignorado)"
    is_dry && return 0
    return 1
  fi
  if [ -e "$dst" ] && cmp -s "$src" "$dst"; then
    [ -n "$mode" ] && ! is_dry && chmod "$mode" "$dst"
    return 0
  fi
  if is_dry; then
    dryrun "deploy $src -> $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_file "$dst"
    rm -f "$dst"
  fi
  cp "$src" "$dst"
  [ -n "$mode" ] && chmod "$mode" "$dst"
  ok "deploy: $dst"
}

# deploy_file_once SRC DST [MODE] — only when DST is missing (or FORCE=1)
deploy_file_once() {
  local src="$1" dst="$2" mode="${3:-}"
  if [ -e "$dst" ] && [ "${FORCE:-0}" != "1" ]; then
    info "já existe (mantido): $dst"
    return 0
  fi
  deploy_file "$src" "$dst" "$mode"
}

# deploy_tree SRC_DIR DST_DIR — deploy every file recursively (never deletes extras)
deploy_tree() {
  local src="$1" dst="$2" f rel
  if [ ! -d "$src" ]; then
    warn "diretório de assets ausente: $src (ignorado)"
    is_dry && return 0
    return 1
  fi
  while IFS= read -r -d '' f; do
    rel="${f#"$src"/}"
    deploy_file "$f" "$dst/$rel" || return 1
  done < <(find "$src" -type f -print0 | sort -z)
}

_sed_escape() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }

# render_template SRC DST — replaces __AI_STACK_HOME__ and __HOME__, then deploy_file
# render_template_once is the same but follows deploy_file_once.
_render_to_tmp() {
  local src="$1" tmp="$2" h s
  h="$(_sed_escape "$HOME")"
  s="$(_sed_escape "$AI_STACK_HOME")"
  sed -e "s|__AI_STACK_HOME__|$s|g" -e "s|__HOME__|$h|g" "$src" > "$tmp"
  if grep -Eq '__[A-Z][A-Z_]*__' "$tmp"; then
    warn "placeholders não resolvidos em $src: $(grep -Eo '__[A-Z][A-Z_]*__' "$tmp" | sort -u | tr '\n' ' ')"
  fi
}

_render_with() {
  local fn="$1" src="$2" dst="$3" mode="${4:-}" tmp rc=0
  if [ ! -f "$src" ]; then
    warn "template ausente: $src (ignorado)"
    is_dry && return 0
    return 1
  fi
  tmp="$(mktemp)"
  _render_to_tmp "$src" "$tmp"
  "$fn" "$tmp" "$dst" "$mode" || rc=$?
  rm -f "$tmp"
  return "$rc"
}
render_template()      { _render_with deploy_file "$@"; }
render_template_once() { _render_with deploy_file_once "$@"; }

# ensure_symlink LINK TARGET
#  - LINK already a symlink to TARGET        -> ok
#  - LINK is a foreign symlink               -> warn, keep (replace with FORCE=1)
#  - LINK is a real dir/file                 -> mv to LINK.bak-<ts>, copy content
#                                               into TARGET (no clobber), symlink
#  - LINK missing                            -> mkdir -p TARGET, symlink
ensure_symlink() {
  local link="$1" target="$2" cur
  if [ -L "$link" ]; then
    cur="$(readlink "$link")"
    if [ "$cur" = "$target" ]; then
      return 0
    fi
    if [ "${FORCE:-0}" != "1" ]; then
      warn "symlink $link -> $cur (esperado: $target); mantido (use --force para substituir)"
      return 0
    fi
    if is_dry; then dryrun "replace symlink $link -> $target"; return 0; fi
    rm -f "$link"
  elif [ -e "$link" ]; then
    if is_dry; then
      dryrun "backup $link -> $link.bak-$TS; migrar conteúdo para $target; symlink $link -> $target"
      return 0
    fi
    mkdir -p "$target"
    mv "$link" "$link.bak-$TS"
    info "backup: $link.bak-$TS"
    if [ -d "$link.bak-$TS" ]; then
      cp -an "$link.bak-$TS"/. "$target"/ 2>/dev/null || true
    fi
  fi
  if is_dry; then dryrun "symlink $link -> $target"; return 0; fi
  mkdir -p "$target" "$(dirname "$link")"
  ln -s "$target" "$link"
  ok "symlink: $link -> $target"
}

# append_block FILE BEGIN_MARKER END_MARKER CONTENT
# Idempotent: replaces the block between markers (inclusive) or appends it.
# CONTENT is the text between the markers (markers are added here).
append_block() {
  local file="$1" begin="$2" end="$3" content="$4" tmp blk
  if is_dry; then dryrun "bloco '$begin' em $file"; return 0; fi
  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || : > "$file"
  blk="$(mktemp)"; tmp="$(mktemp)"
  { printf '%s\n' "$begin"; printf '%s\n' "$content"; printf '%s\n' "$end"; } > "$blk"
  if grep -qF "$begin" "$file" && grep -qF "$end" "$file"; then
    BEGIN="$begin" END="$end" BLK="$blk" awk '
      BEGIN { b=ENVIRON["BEGIN"]; e=ENVIRON["END"]; inblk=0; done=0 }
      index($0,b) && !inblk && !done {
        inblk=1
        while ((getline line < ENVIRON["BLK"]) > 0) print line
        close(ENVIRON["BLK"]); next
      }
      inblk { if (index($0,e)) { inblk=0; done=1 } ; next }
      { print }
    ' "$file" > "$tmp"
  else
    cp "$file" "$tmp"
    [ -s "$tmp" ] && [ -n "$(tail -c1 "$tmp")" ] && echo >> "$tmp"
    cat "$blk" >> "$tmp"
  fi
  if cmp -s "$tmp" "$file"; then
    rm -f "$tmp" "$blk"; return 0
  fi
  backup_file "$file"
  cat "$tmp" > "$file"
  rm -f "$tmp" "$blk"
  ok "bloco atualizado em $file"
}

# remove_block FILE BEGIN_MARKER END_MARKER
remove_block() {
  local file="$1" begin="$2" end="$3" tmp
  [ -f "$file" ] || return 0
  grep -qF "$begin" "$file" || return 0
  if is_dry; then dryrun "remover bloco '$begin' de $file"; return 0; fi
  backup_file "$file"
  tmp="$(mktemp)"
  BEGIN="$begin" END="$end" awk '
    BEGIN { b=ENVIRON["BEGIN"]; e=ENVIRON["END"]; inblk=0 }
    index($0,b) && !inblk { inblk=1; next }
    inblk { if (index($0,e)) inblk=0; next }
    { print }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"; rm -f "$tmp"
  ok "bloco removido de $file"
}

# --------------------------------------------------------------- toolchain --
# ai_env — put the stack's runtimes on PATH and load nvm (idempotent).
ai_env() {
  export NVM_DIR="$AI_STACK_HOME/platform/runtime/nvm"
  local d
  for d in "$HOME/.local/bin" "$HOME/.opencode/bin" "$HOME/.bun/bin" \
           "$AI_STACK_HOME/platform/bitloops/bin" "$AI_STACK_HOME/platform/runtime/node" \
           "$AI_STACK_HOME/platform/runtime/python"; do
    case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
  done
  export PATH
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    local had_u=0
    case "$-" in *u*) had_u=1; set +u ;; esac
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
    [ "$had_u" = "1" ] && set -u
  fi
  return 0
}

# link_opencode_dirs — symlinks for every OpenCode XDG/home dir (idempotent)
link_opencode_dirs() {
  local p="$AI_STACK_HOME/platform"
  ensure_symlink "$HOME/.opencode"                "$p/opencode/install"
  ensure_symlink "$HOME/.config/opencode"         "$p/config/opencode"
  ensure_symlink "$HOME/.local/share/opencode"    "$p/opencode/data"
  ensure_symlink "$HOME/.cache/opencode"          "$p/opencode/cache"
  ensure_symlink "$HOME/.local/state/opencode"    "$p/opencode/state"
}

# detect_target — sets OS_NAME / ARCH_NAME (linux|darwin, x86_64|aarch64)
detect_target() {
  case "$(uname -s)" in Linux) OS_NAME=linux ;; Darwin) OS_NAME=darwin ;; *) OS_NAME=unknown ;; esac
  case "$(uname -m)" in
    x86_64|amd64) ARCH_NAME=x86_64 ;;
    aarch64|arm64) ARCH_NAME=aarch64 ;;
    *) ARCH_NAME=unknown ;;
  esac
  if [ "$OS_NAME" = unknown ] || [ "$ARCH_NAME" = unknown ]; then
    err "Plataforma não suportada: $(uname -s)/$(uname -m)"
    return 1
  fi
}
