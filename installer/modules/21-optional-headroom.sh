#!/usr/bin/env bash
# 21-optional-headroom — headroom-ai via uv tool

module_optional_headroom() {
  ai_env
  if is_dry; then dryrun "uv tool install headroom-ai==${HEADROOM_VERSION}"; return 0; fi
  need_cmd uv || return 1
  if uv tool list 2>/dev/null | grep -q "^headroom-ai v${HEADROOM_VERSION}\$"; then
    ok "headroom-ai ${HEADROOM_VERSION} já instalado"
    return 0
  fi
  info "Instalando headroom-ai==${HEADROOM_VERSION}..."
  uv tool install "headroom-ai==${HEADROOM_VERSION}" --force
  ok "headroom-ai instalado"
}
