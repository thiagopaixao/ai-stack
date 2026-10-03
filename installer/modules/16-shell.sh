#!/usr/bin/env bash
# 16-shell — bloco ai-stack no ~/.bashrc (somente com --shell ou confirmação interativa)

module_shell() {
  local snippet="$REPO_DIR/config/shell/bashrc.snippet"
  local rc="$HOME/.bashrc"
  local begin="# >>> ai-stack >>>" end="# <<< ai-stack <<<"

  if [ "${SHELL_FLAG:-0}" != "1" ]; then
    if [ "${ASSUME_YES:-0}" = "1" ] || [ ! -t 0 ] || is_dry; then
      info "bashrc não alterado (use --shell para instalar o bloco)"
      return 0
    fi
    confirm "Adicionar o ambiente ai-stack ao ~/.bashrc?" n || { info "bashrc não alterado"; return 0; }
  fi

  if [ ! -f "$snippet" ]; then
    warn "assets ausentes: $snippet"
    is_dry && return 0
    return 1
  fi

  local tmp inner
  tmp="$(mktemp)"
  _render_to_tmp "$snippet" "$tmp"
  # extrai somente o conteúdo entre os marcadores (se presentes)
  if grep -qF "$begin" "$tmp"; then
    inner="$(awk -v b="$begin" -v e="$end" 'index($0,e){f=0} f{print} index($0,b){f=1}' "$tmp")"
  else
    inner="$(cat "$tmp")"
  fi
  rm -f "$tmp"
  append_block "$rc" "$begin" "$end" "$inner"
}
