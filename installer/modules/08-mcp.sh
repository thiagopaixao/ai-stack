#!/usr/bin/env bash
# 08-mcp — mcp-ripgrep (npm local em platform/mcp) + config MCP renderizada

module_mcp() {
  local mcp="$AI_STACK_HOME/platform/mcp"

  deploy_file "$REPO_DIR/config/mcp/package.json" "$mcp/package.json" || return 1
  render_template "$REPO_DIR/config/mcp/opencode-mcp.json.tmpl" \
    "$AI_STACK_HOME/platform/config/mcp/opencode-mcp.json" || return 1

  if [ -f "$mcp/node_modules/mcp-ripgrep/dist/index.js" ]; then
    ok "mcp-ripgrep já instalado"
    return 0
  fi
  if is_dry; then
    dryrun "(cd $mcp && npm install --no-audit --no-fund)"
    return 0
  fi
  ai_env
  need_cmd npm || { err "npm ausente — rode o módulo 'node' antes"; return 1; }
  info "npm install em $mcp..."
  (cd "$mcp" && npm install --no-audit --no-fund 2>&1 | tail -3)
  [ -f "$mcp/node_modules/mcp-ripgrep/dist/index.js" ] || { err "mcp-ripgrep não instalado"; return 1; }
  ok "mcp-ripgrep instalado"
}
