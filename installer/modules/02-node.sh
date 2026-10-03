#!/usr/bin/env bash
# 02-node — nvm + Node.js (versão fixa) em platform/runtime/nvm

module_node() {
  export NVM_DIR="$AI_STACK_HOME/platform/runtime/nvm"

  if is_dry; then
    dryrun "instalar nvm ${NVM_VERSION} em $NVM_DIR (se ausente)"
    dryrun "nvm install ${NODE_VERSION}; nvm alias default ${NODE_VERSION}"
    return 0
  fi

  need_cmd curl
  mkdir -p "$NVM_DIR"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    ok "nvm já instalado"
  else
    info "Baixando nvm ${NVM_VERSION}..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
      | NVM_DIR="$NVM_DIR" PROFILE=/dev/null bash
  fi

  ai_env
  if ! command -v nvm >/dev/null 2>&1; then
    err "nvm não carregou a partir de $NVM_DIR/nvm.sh"
    return 1
  fi

  local want="${NODE_VERSION#v}" cur=""
  cur="$(nvm version "$want" 2>/dev/null || true)"
  if [ -n "$cur" ] && [ "$cur" != "N/A" ]; then
    ok "Node.js $want já instalado"
  else
    info "Instalando Node.js $want..."
    nvm install "$want"
  fi
  nvm alias default "$want" >/dev/null
  nvm use "$want" >/dev/null
  ok "node $(node --version) / npm $(npm --version)"
}
