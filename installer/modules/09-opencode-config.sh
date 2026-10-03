#!/usr/bin/env bash
# 09-opencode-config — symlinks XDG + deploy de config/opencode/* em platform/config/opencode

module_opencode_config() {
  local src="$REPO_DIR/config/opencode"
  local dst="$AI_STACK_HOME/platform/config/opencode"

  link_opencode_dirs

  if [ ! -d "$src" ]; then
    warn "assets ausentes: $src (nada a implantar)"
    is_dry && return 0
    return 1
  fi

  render_template "$src/opencode.json.tmpl" "$dst/opencode.json" || return 1

  local f
  for f in oh-my-opencode-slim.json tui.json package.json; do
    deploy_file "$src/$f" "$dst/$f" || return 1
  done
  deploy_file "$src/dot-gitignore" "$dst/.gitignore" || return 1
  deploy_tree "$src/presets" "$dst/presets" || return 1
  deploy_tree "$src/plugins" "$dst/plugins" || return 1
  deploy_tree "$src/skills"  "$dst/skills"  || return 1

  # Dependências do plugin SDK (opcional, não fatal; pulado em --config-only)
  if [ "${CONFIG_ONLY:-0}" = "1" ] || is_dry; then
    is_dry && dryrun "instalar dependências em $dst (bun/npm install), se disponível"
    return 0
  fi
  if [ ! -d "$dst/node_modules/@opencode-ai/plugin" ]; then
    ai_env
    if have_cmd bun; then
      (cd "$dst" && bun install) || warn "bun install falhou em $dst (não fatal)"
    elif have_cmd npm; then
      (cd "$dst" && npm install --no-audit --no-fund 2>&1 | tail -3) \
        || warn "npm install falhou em $dst (não fatal)"
    else
      warn "nem bun nem npm disponíveis; pulando install de @opencode-ai/plugin"
    fi
  fi
  return 0
}
