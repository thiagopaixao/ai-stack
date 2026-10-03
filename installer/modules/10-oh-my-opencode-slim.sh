#!/usr/bin/env bash
# 10-oh-my-opencode-slim — pré-aquece o plugin no cache do OpenCode (não fatal)
# O plugin é declarado em opencode.json ("plugin": ["oh-my-opencode-slim"]);
# o OpenCode o instala sozinho na primeira execução. Aqui só adiantamos.

module_oh_my_opencode_slim() {
  local pkg="$AI_STACK_HOME/platform/opencode/cache/packages/oh-my-opencode-slim@latest"

  if [ -d "$pkg/node_modules/oh-my-opencode-slim" ]; then
    ok "oh-my-opencode-slim já presente no cache"
    return 0
  fi
  if is_dry; then
    dryrun "npm install oh-my-opencode-slim@${OH_MY_OPENCODE_SLIM_VERSION} em $pkg"
    return 0
  fi
  ai_env
  if ! have_cmd npm; then
    warn "npm ausente; OpenCode instalará o plugin sozinho na 1ª execução"
    return 0
  fi
  mkdir -p "$pkg"
  printf '{"private":true,"dependencies":{"oh-my-opencode-slim":"%s"}}\n' \
    "$OH_MY_OPENCODE_SLIM_VERSION" > "$pkg/package.json"
  if (cd "$pkg" && npm install --no-audit --no-fund 2>&1 | tail -3) \
     && [ -d "$pkg/node_modules/oh-my-opencode-slim" ]; then
    ok "oh-my-opencode-slim pré-instalado"
  else
    warn "pré-instalação falhou (não fatal): OpenCode tentará na 1ª execução"
  fi
  return 0
}
