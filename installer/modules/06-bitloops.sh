#!/usr/bin/env bash
# 06-bitloops — CLI do Bitloops (binário de release do GitHub)
#
# Dados em ~/.local/share/bitloops -> memory/bitloops.
# O runtime de embeddings local (bitloops-local-embeddings) é baixado pelo
# próprio Bitloops quando um workspace roda:
#   bitloops init --embeddings-runtime local ...
# (ver docs/configuracao.md). Nada é pré-instalado aqui.

module_bitloops() {
  local bin="$AI_STACK_HOME/platform/bitloops/bin/bitloops"
  local ver="${BITLOOPS_VERSION#v}"

  ensure_symlink "$HOME/.local/share/bitloops" "$AI_STACK_HOME/memory/bitloops"

  if [ -x "$bin" ] && "$bin" --version 2>&1 | grep -q "CLI v${ver}"; then
    ok "bitloops ${ver} já instalado"
    return 0
  fi

  detect_target || return 1
  local plat ext
  case "${OS_NAME}:${ARCH_NAME}" in
    linux:x86_64)   plat="x86_64-unknown-linux-musl";  ext="tar.gz" ;;
    linux:aarch64)  plat="aarch64-unknown-linux-musl"; ext="tar.gz" ;;
    darwin:x86_64)  plat="x86_64-apple-darwin";        ext="zip" ;;
    darwin:aarch64) plat="aarch64-apple-darwin";       ext="zip" ;;
  esac
  local asset="bitloops-${plat}.${ext}"
  local url="https://github.com/bitloops/bitloops/releases/download/v${ver}/${asset}"

  if is_dry; then
    dryrun "baixar $url -> $bin"
    return 0
  fi

  need_cmd curl
  local tmp found; tmp="$(mktemp -d)"
  info "Baixando Bitloops v${ver} (${plat})..."
  if ! curl -fsSL "$url" -o "$tmp/$asset"; then
    rm -rf "$tmp"; err "Falha ao baixar $url"; return 1
  fi
  if [ "$ext" = "tar.gz" ]; then
    tar xzf "$tmp/$asset" -C "$tmp"
  else
    need_cmd unzip || { rm -rf "$tmp"; return 1; }
    unzip -oq "$tmp/$asset" -d "$tmp"
  fi
  found="$(find "$tmp" -name bitloops -type f | head -1)"
  if [ -z "$found" ]; then
    rm -rf "$tmp"; err "Binário bitloops não encontrado no archive"; return 1
  fi
  mkdir -p "$(dirname "$bin")"
  cp "$found" "$bin"; chmod +x "$bin"
  rm -rf "$tmp"
  ok "bitloops v${ver} instalado em $bin"
}
