#!/usr/bin/env bash
# 05-serena — Serena MCP server via `uv tool install`

module_serena() {
  ai_env
  if is_dry; then
    dryrun "uv tool install -p ${SERENA_PYTHON} '${SERENA_SPEC}' --prerelease=allow"
    return 0
  fi
  need_cmd uv || { err "uv ausente — rode o módulo 'uv' antes"; return 1; }

  if uv tool list 2>/dev/null | grep -q "^serena-agent v${SERENA_VERSION}\b"; then
    ok "serena-agent ${SERENA_VERSION} já instalado"
  else
    info "Instalando ${SERENA_SPEC}..."
    uv tool install -p "$SERENA_PYTHON" "$SERENA_SPEC" --prerelease=allow --force
  fi

  if [ -x "$HOME/.local/bin/serena" ]; then
    ok "serena em $HOME/.local/bin/serena"
  else
    warn "serena não encontrada em ~/.local/bin (verifique: uv tool list; uv tool update-shell)"
  fi
}
