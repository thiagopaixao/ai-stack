#!/usr/bin/env bash
# 25-optional-oh-my-openagent — plugin legado (OFF por padrão; use --with oh-my-openagent)
# Implanta oh-my-openagent.json, registra "oh-my-openagent@latest" em opencode.json
# e pré-instala o plugin (com dependências) no cache do OpenCode.
# Obs.: reaplicar o módulo opencode-config regenera opencode.json (sem o plugin legado,
# com backup); rode este módulo de novo depois.

module_optional_oh_my_openagent() {
  local cfg="$AI_STACK_HOME/platform/config/opencode"
  local pkg="$AI_STACK_HOME/platform/opencode/cache/packages/oh-my-openagent@latest"

  deploy_file_once "$REPO_DIR/config/opencode/oh-my-openagent.json" "$cfg/oh-my-openagent.json" || return 1

  # registrar plugin em opencode.json
  if [ -f "$cfg/opencode.json" ] && grep -q 'oh-my-openagent' "$cfg/opencode.json"; then
    ok "oh-my-openagent já registrado em opencode.json"
  elif is_dry; then
    dryrun "adicionar 'oh-my-openagent@latest' a plugin[] em $cfg/opencode.json"
  elif [ -f "$cfg/opencode.json" ]; then
    backup_file "$cfg/opencode.json"
    if have_cmd jq; then
      local tmp; tmp="$(mktemp)"
      jq '.plugin = ((.plugin // []) + ["oh-my-openagent@latest"] | unique)' "$cfg/opencode.json" > "$tmp" \
        && cat "$tmp" > "$cfg/opencode.json"
      rm -f "$tmp"
    elif have_cmd python3; then
      python3 - "$cfg/opencode.json" <<'PY'
import json, sys
p = sys.argv[1]
c = json.load(open(p))
pl = c.setdefault("plugin", [])
if "oh-my-openagent@latest" not in pl:
    pl.append("oh-my-openagent@latest")
json.dump(c, open(p, "w"), indent=2); open(p, "a").write("\n")
PY
    else
      err "jq/python3 ausentes: registre 'oh-my-openagent@latest' em plugin[] manualmente"; return 1
    fi
    ok "oh-my-openagent registrado em opencode.json"
  else
    warn "opencode.json ausente; rode o módulo opencode-config primeiro"
    return 1
  fi

  # pré-instalar plugin + dependências (zod/v3 etc.)
  if [ -d "$pkg/node_modules/oh-my-openagent" ]; then
    ok "oh-my-openagent já no cache"
    return 0
  fi
  if is_dry; then dryrun "npm install oh-my-openagent@latest em $pkg"; return 0; fi
  ai_env
  need_cmd npm || return 1
  mkdir -p "$pkg"
  printf '{"private":true,"dependencies":{"oh-my-openagent":"latest"}}\n' > "$pkg/package.json"
  (cd "$pkg" && npm install --no-audit --no-fund 2>&1 | tail -3)
  [ -f "$pkg/node_modules/oh-my-openagent/dist/index.js" ] \
    || { err "oh-my-openagent/dist/index.js ausente após instalação"; return 1; }
  ok "oh-my-openagent pré-instalado"
}
