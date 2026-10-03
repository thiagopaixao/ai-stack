#!/usr/bin/env bash
# 03-uv — uv/uvx em ~/.local/bin; ~/.local/share/uv -> platform/runtime/python/share

module_uv() {
  local bin="$HOME/.local/bin/uv"
  local share="$AI_STACK_HOME/platform/runtime/python/share"

  if is_dry; then
    dryrun "instalar uv/uvx em $HOME/.local/bin (astral installer, UV_INSTALL_DIR)"
    dryrun "symlink $HOME/.local/share/uv -> $share"
    return 0
  fi

  # Symlink first so uv tools/pythons land inside the stack
  mkdir -p "$share" "$HOME/.local/bin"
  ensure_symlink "$HOME/.local/share/uv" "$share"

  if [ -x "$bin" ]; then
    ok "uv já instalado: $("$bin" --version)"
    return 0
  fi
  if have_cmd uv; then
    ok "uv já disponível no PATH: $(uv --version)"
    return 0
  fi

  need_cmd curl
  info "Baixando uv (astral)..."
  curl -LsSf https://astral.sh/uv/install.sh \
    | env UV_INSTALL_DIR="$HOME/.local/bin" INSTALLER_NO_MODIFY_PATH=1 sh
  ok "uv instalado: $("$bin" --version)"
}
