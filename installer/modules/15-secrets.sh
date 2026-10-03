#!/usr/bin/env bash
# 15-secrets — cria $AI_STACK_HOME/secrets.env a partir de .env.example (nunca sobrescreve)

module_secrets() {
  local dst="$AI_STACK_HOME/secrets.env" src="$REPO_DIR/.env.example"
  if [ -e "$dst" ]; then
    ok "secrets.env já existe (mantido; não lido)"
    is_dry || chmod 600 "$dst"
    return 0
  fi
  if [ ! -f "$src" ]; then
    warn "assets ausentes: $src"
    is_dry && return 0
    return 1
  fi
  if is_dry; then dryrun "copiar $src -> $dst (chmod 600)"; return 0; fi
  mkdir -p "$AI_STACK_HOME"
  cp "$src" "$dst"
  chmod 600 "$dst"
  ok "criado $dst (preencha NINEROUTER_API_KEY)"
}
