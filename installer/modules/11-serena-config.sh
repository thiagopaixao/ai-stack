#!/usr/bin/env bash
# 11-serena-config — ~/.serena/serena_config.yml (somente se ausente, ou --force)

module_serena_config() {
  local dst="$HOME/.serena/serena_config.yml"
  local src="$REPO_DIR/config/serena/serena_config.yml.tmpl"

  if [ -e "$dst" ] && [ "${FORCE:-0}" != "1" ]; then
    if [ -f "$src" ]; then
      local tmp; tmp="$(mktemp)"
      _render_to_tmp "$src" "$tmp"
      cmp -s "$tmp" "$dst" || warn "$dst existe e difere do template; mantido (use --force para sobrescrever, com backup)"
      rm -f "$tmp"
    fi
    return 0
  fi
  render_template_once "$src" "$dst"
}
