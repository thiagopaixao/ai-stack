#!/usr/bin/env bash
# 22-optional-herdr — herdr (runtime/multiplexador para agentes) em ~/.local/bin
# Binário único publicado em https://github.com/herdrdev/herdr/releases
# (assets: herdr-{linux,macos}-{x86_64,aarch64}). O plugin OpenCode
# herdr-agent-state.js já é implantado pelo módulo opencode-config.

module_optional_herdr() {
  local bin="$HOME/.local/bin/herdr" ver="${HERDR_VERSION#v}"

  if [ -x "$bin" ] && "$bin" --version 2>&1 | grep -q "$ver"; then
    ok "herdr ${ver} já instalado"
    return 0
  fi

  detect_target || return 1
  local os="$OS_NAME"
  [ "$os" = "darwin" ] && os="macos"
  local url="https://github.com/herdrdev/herdr/releases/download/v${ver}/herdr-${os}-${ARCH_NAME}"

  if is_dry; then dryrun "baixar $url -> $bin"; return 0; fi

  need_cmd curl
  local tmp; tmp="$(mktemp)"
  info "Baixando herdr v${ver}..."
  if ! curl -fsSL "$url" -o "$tmp"; then
    rm -f "$tmp"
    warn "Download falhou ($url). Instalação manual:"
    warn "  https://github.com/herdrdev/herdr/releases  -> salve como ~/.local/bin/herdr (chmod +x)"
    return 0
  fi
  mkdir -p "$(dirname "$bin")"
  install -m 755 "$tmp" "$bin"
  rm -f "$tmp"
  ok "herdr instalado em $bin"
}
