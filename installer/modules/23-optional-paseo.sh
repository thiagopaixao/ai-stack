#!/usr/bin/env bash
# 23-optional-paseo — Paseo CLI via npm global

module_optional_paseo() {
  if is_dry; then dryrun "npm install -g @getpaseo/cli@${PASEO_VERSION}"; return 0; fi
  ai_env
  need_cmd npm || return 1
  if npm ls -g --depth=0 2>/dev/null | grep -q "@getpaseo/cli@${PASEO_VERSION}\$"; then
    ok "paseo ${PASEO_VERSION} já instalado"
    return 0
  fi
  info "Instalando @getpaseo/cli@${PASEO_VERSION}..."
  npm install -g --no-audit --no-fund "@getpaseo/cli@${PASEO_VERSION}"
  ok "paseo instalado"
}
