#!/usr/bin/env bash
# 13-scripts — platform/scripts/*.sh -> $AI_STACK_HOME/platform/scripts (chmod +x)

module_scripts() {
  local src="$REPO_DIR/platform/scripts" dst="$AI_STACK_HOME/platform/scripts" f n=0
  if [ ! -d "$src" ]; then
    warn "assets ausentes: $src"
    is_dry && return 0
    return 1
  fi
  run mkdir -p "$dst"
  for f in "$src"/*.sh; do
    [ -f "$f" ] || continue
    deploy_file "$f" "$dst/$(basename "$f")" 755 || return 1
    n=$((n + 1))
  done
  ok "$n scripts em $dst"
}
