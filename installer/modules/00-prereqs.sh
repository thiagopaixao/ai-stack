#!/usr/bin/env bash
# 00-prereqs — verifica pré-requisitos do sistema (sem sudo, sem instalar nada)

module_prereqs() {
  local missing=0 c
  for c in curl git tar bash; do
    if have_cmd "$c"; then :; else err "Comando obrigatório ausente: $c"; missing=1; fi
  done
  [ "$missing" = "0" ] || return 1
  ok "Pré-requisitos: curl git tar bash"

  have_cmd python3 || warn "python3 não encontrado (opcional; usado em alguns ajustes de JSON)"
  have_cmd jq      || warn "jq não encontrado (recomendado; usado por verify.sh e healthchecks)"
  have_cmd unzip   || warn "unzip não encontrado (necessário só para Bitloops em macOS)"
  return 0
}
