#!/usr/bin/env bash
# 20-optional-9router — 9router (proxy/roteador de modelos local) via npm global
# (global dentro do nvm da stack: nada de sudo)

module_optional_9router() {
  if is_dry; then dryrun "npm install -g 9router@${NINEROUTER_VERSION}"; return 0; fi
  ai_env
  need_cmd npm || return 1
  if npm ls -g --depth=0 2>/dev/null | grep -q "9router@${NINEROUTER_VERSION}\$"; then
    ok "9router ${NINEROUTER_VERSION} já instalado"
    return 0
  fi
  info "Instalando 9router@${NINEROUTER_VERSION}..."
  npm install -g --no-audit --no-fund "9router@${NINEROUTER_VERSION}"
  ok "9router instalado (inicie com: 9router; porta padrão 20128)"
}
