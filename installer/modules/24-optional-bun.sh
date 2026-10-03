#!/usr/bin/env bash
# 24-optional-bun — Bun runtime em ~/.bun
# Atenção: o instalador oficial do Bun pode editar ~/.bashrc por conta própria.

module_optional_bun() {
  local bin="${BUN_INSTALL:-$HOME/.bun}/bin/bun"
  if [ -x "$bin" ] && [ "$("$bin" --version 2>/dev/null || true)" = "${BUN_VERSION#v}" ]; then
    ok "bun ${BUN_VERSION} já instalado"
    return 0
  fi
  if is_dry; then
    dryrun "curl -fsSL https://bun.sh/install | bash -s bun-v${BUN_VERSION#v}"
    return 0
  fi
  need_cmd curl
  warn "O instalador do Bun pode adicionar linhas ao ~/.bashrc (o load-env.sh já cobre ~/.bun/bin)"
  curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION#v}"
  ok "bun instalado"
}
