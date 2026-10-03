#!/usr/bin/env bash
# 99-finalize — healthcheck + próximos passos

module_finalize() {
  local hc="$AI_STACK_HOME/platform/scripts/healthcheck.sh"
  if is_dry; then
    dryrun "executar $hc"
  elif [ -x "$hc" ]; then
    info "Healthcheck:"
    bash "$hc" || warn "healthcheck reportou falhas (veja acima)"
  else
    warn "healthcheck.sh não encontrado em $hc (módulo 'scripts' não executado?)"
  fi

  cat <<MSG

Próximos passos:
  1. Preencha a chave do 9router:
       \$EDITOR $AI_STACK_HOME/secrets.env     # NINEROUTER_API_KEY=...
  2. Carregue o ambiente (ou reabra o shell / use --shell):
       source $AI_STACK_HOME/platform/scripts/load-env.sh
  3. Autentique o GitHub Copilot no OpenCode:
       opencode auth login
  4. Se usar 9router (--with 9router): inicie-o antes do OpenCode (http://127.0.0.1:20128/v1).
  5. Crie um workspace:
       $AI_STACK_HOME/platform/scripts/create-workspace.sh <nome> <git-url>
MSG
  return 0
}
