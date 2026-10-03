#!/usr/bin/env bash
# 07-opencode — OpenCode via instalador oficial
# ~/.opencode é linkado ANTES para que o binário caia em platform/opencode/install.

module_opencode() {
  local bin="$HOME/.opencode/bin/opencode"
  local ver="${OPENCODE_VERSION#v}"

  link_opencode_dirs

  if [ -x "$bin" ] && [ "$("$bin" --version 2>/dev/null || true)" = "$ver" ]; then
    ok "opencode ${ver} já instalado"
    return 0
  fi

  if is_dry; then
    dryrun "curl -fsSL https://opencode.ai/install | bash -s -- --version ${ver} --no-modify-path"
    return 0
  fi

  need_cmd curl
  info "Instalando opencode ${ver}..."
  curl -fsSL https://opencode.ai/install | bash -s -- --version "$ver" --no-modify-path
  if [ -x "$bin" ]; then
    ok "opencode $("$bin" --version 2>/dev/null || echo '?') em $bin"
  else
    err "opencode não encontrado em $bin após instalação"
    return 1
  fi
}
