#!/usr/bin/env bash
# 12-bitloops-config — config.toml em platform/config/bitloops e ~/.config/bitloops
#   ~/.config/bitloops/config.toml  (arquivo real, lido pelo daemon)
#   ~/.config/bitloops/bitloops -> platform/config/bitloops

module_bitloops_config() {
  local src="$REPO_DIR/config/bitloops/config.toml.tmpl"
  local plat="$AI_STACK_HOME/platform/config/bitloops"

  run mkdir -p "$plat" "$HOME/.config/bitloops"
  render_template "$src" "$plat/config.toml" || return 1
  render_template "$src" "$HOME/.config/bitloops/config.toml" || return 1
  ensure_symlink "$HOME/.config/bitloops/bitloops" "$plat"
}
