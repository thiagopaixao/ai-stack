#!/usr/bin/env bash
# 04-ripgrep — binário rg em platform/runtime/node/rg

module_ripgrep() {
  local rg="$AI_STACK_HOME/platform/runtime/node/rg"
  local ver="$RIPGREP_VERSION"

  if [ -x "$rg" ] && "$rg" --version 2>/dev/null | head -1 | grep -q "ripgrep ${ver}"; then
    ok "ripgrep ${ver} já instalado"
    return 0
  fi

  detect_target || return 1
  local target
  case "${OS_NAME}:${ARCH_NAME}" in
    linux:x86_64)  target="x86_64-unknown-linux-musl" ;;
    linux:aarch64) target="aarch64-unknown-linux-gnu" ;;
    darwin:x86_64) target="x86_64-apple-darwin" ;;
    darwin:aarch64) target="aarch64-apple-darwin" ;;
  esac
  local archive="ripgrep-${ver}-${target}.tar.gz"
  local url="https://github.com/BurntSushi/ripgrep/releases/download/${ver}/${archive}"

  if is_dry; then
    dryrun "baixar $url -> $rg"
    return 0
  fi

  need_cmd curl; need_cmd tar
  local tmp; tmp="$(mktemp -d)"
  info "Baixando ripgrep ${ver} (${target})..."
  if ! curl -fsSL "$url" -o "$tmp/rg.tar.gz"; then
    rm -rf "$tmp"; err "Falha ao baixar $url"; return 1
  fi
  tar xzf "$tmp/rg.tar.gz" -C "$tmp"
  mkdir -p "$(dirname "$rg")"
  cp "$tmp/ripgrep-${ver}-${target}/rg" "$rg"
  chmod +x "$rg"
  rm -rf "$tmp"
  ok "ripgrep instalado: $("$rg" --version | head -1)"
}
