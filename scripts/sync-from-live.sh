#!/usr/bin/env bash
# sync-from-live.sh — re-export the live ai-stack into this repository, scrubbing
# secrets and machine-specific paths.
#
# Usage: scripts/sync-from-live.sh [--live <path>] [--dry-run]
#   --live <path>  live ai-stack root (default: ${AI_STACK_HOME:-$HOME/ai-stack})
#   --dry-run      print what would be copied; change nothing
#
# Scrubbing applied:
#   - provider apiKey literals            -> "{env:NINEROUTER_API_KEY}"
#   - <live path> -> __AI_STACK_HOME__ and $HOME -> __HOME__ (only in *.tmpl targets)
#   - serena `projects:` list             -> `projects: []`
#   - bitloops absolute embeddings command -> bare "bitloops-local-embeddings"
# Never copied: workspaces, backup, memory, indexes, investigations, node_modules,
#   lock files, *.bak, *.before-9router*, plugin state (.oh-my-opencode-slim), auth/secrets.
# platform/scripts/*.sh and docs/ are maintained in this repo; only scripts that do
# not yet exist in the repo are imported from live.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE="${AI_STACK_HOME:-$HOME/ai-stack}"
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --live) LIVE="${2:?--live requires a path}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

LIVE="${LIVE%/}"
[ -d "$LIVE" ] || { echo "[sync] live dir not found: $LIVE" >&2; exit 1; }

LC="$LIVE/platform/config"
HAVE_RSYNC=0; command -v rsync >/dev/null 2>&1 && HAVE_RSYNC=1

esc() { printf '%s' "$1" | sed 's/[][\.*^$|/]/\\&/g'; }
LIVE_ESC="$(esc "$LIVE")"
HOME_ESC="$(esc "$HOME")"

# scrub_stream <tmpl:0|1> — stdin → stdout
scrub_stream() {
  local tmpl="$1"
  sed -E 's/("apiKey"[[:space:]]*:[[:space:]]*)"[^{"][^"]*"/\1"{env:NINEROUTER_API_KEY}"/' |
  if [ "$tmpl" = 1 ]; then
    sed -e "s|$LIVE_ESC|__AI_STACK_HOME__|g" -e "s|$HOME_ESC|__HOME__|g"
  else
    cat
  fi
}

say() { printf '[sync]%s %s\n' "$([ "$DRY" = 1 ] && echo ' (dry-run)')" "$*"; }

# put_file <src> <repo-relative dst> [extra sed expr]
put_file() {
  local src="$1" dst="$REPO/$2" extra="${3:-}" tmpl=0
  case "$2" in *.tmpl|*.template) tmpl=1 ;; esac
  if [ ! -f "$src" ]; then say "skip (missing): $src"; return 0; fi
  say "$src -> $2"
  [ "$DRY" = 1 ] && return 0
  mkdir -p "$(dirname "$dst")"
  if [ -n "$extra" ]; then
    scrub_stream "$tmpl" < "$src" | sed -E "$extra" > "$dst"
  else
    scrub_stream "$tmpl" < "$src" > "$dst"
  fi
}

# put_dir <src dir> <repo-relative dst dir>   (with exclusions)
put_dir() {
  local src="$1" dst="$REPO/$2"
  if [ ! -d "$src" ]; then say "skip (missing): $src"; return 0; fi
  say "$src/ -> $2/"
  local -a EXC=(node_modules bun.lock package-lock.json '*.bak' '*.before-9router*' '.oh-my-opencode-slim' '.DS_Store')
  if [ "$HAVE_RSYNC" = 1 ]; then
    local -a args=(-a --delete)
    local e; for e in "${EXC[@]}"; do args+=(--exclude "$e"); done
    if [ "$DRY" = 1 ]; then rsync "${args[@]}" -n -i "$src/" "$dst/" | sed 's/^/    /'; else mkdir -p "$dst"; rsync "${args[@]}" "$src/" "$dst/"; fi
  else
    if [ "$DRY" = 1 ]; then
      (cd "$src" && find . -type f ! -path '*/node_modules/*' ! -name '*.bak' ! -name 'bun.lock' \
        ! -name 'package-lock.json' ! -name '*.before-9router*' ! -path '*/.oh-my-opencode-slim/*' | sed 's/^/    /')
    else
      rm -rf "$dst"; mkdir -p "$dst"; cp -a "$src/." "$dst/"
      find "$dst" \( -name node_modules -o -name .oh-my-opencode-slim \) -prune -exec rm -rf {} + 2>/dev/null || true
      find "$dst" \( -name '*.bak' -o -name bun.lock -o -name package-lock.json -o -name '*.before-9router*' \) -type f -delete
    fi
  fi
}

say "live = $LIVE"
say "repo = $REPO"

# --- OpenCode config ---
put_file "$LC/opencode/opencode.json"                    config/opencode/opencode.json.tmpl
put_file "$LC/opencode/oh-my-opencode-slim.json"         config/opencode/oh-my-opencode-slim.json
put_file "$LC/opencode/oh-my-opencode-slim.json_sem-github" config/opencode/presets/oh-my-opencode-slim.no-github.json
put_file "$LC/opencode/tui.json"                         config/opencode/tui.json
put_file "$LC/opencode/oh-my-openagent.json"             config/opencode/oh-my-openagent.json
put_file "$LC/opencode/package.json"                     config/opencode/package.json
put_file "$LC/opencode/.gitignore"                       config/opencode/dot-gitignore
put_file "$LC/opencode/plugins/herdr-agent-state.js"     config/opencode/plugins/herdr-agent-state.js
put_dir  "$LC/opencode/skills"                           config/opencode/skills

# --- MCP ---
put_file "$LC/mcp/opencode-mcp.json"                     config/mcp/opencode-mcp.json.tmpl
put_file "$LIVE/platform/mcp/package.json"               config/mcp/package.json

# --- Bitloops (embeddings command must be the bare name, resolved via PATH) ---
put_file "$LC/bitloops/config.toml" config/bitloops/config.toml.tmpl \
  's|^(command = ")[^"]*bitloops-local-embeddings"|\1bitloops-local-embeddings"|'

# --- Serena (projects list removed) ---
SERENA_SRC="$HOME/.serena/serena_config.yml"
if [ -f "$SERENA_SRC" ]; then
  say "$SERENA_SRC -> config/serena/serena_config.yml.tmpl (projects: [])"
  if [ "$DRY" = 0 ]; then
    mkdir -p "$REPO/config/serena"
    scrub_stream 1 < "$SERENA_SRC" | awk '
      /^projects:/ { print "projects: []"; skip=1; next }
      skip && /^[[:space:]]*-/ { next }
      { skip=0; print }
    ' > "$REPO/config/serena/serena_config.yml.tmpl"
  fi
else
  say "skip (missing): $SERENA_SRC"
fi

# --- Templates ---
if [ -d "$LIVE/templates" ]; then
  for f in "$LIVE"/templates/*.md; do
    [ -f "$f" ] && put_file "$f" "templates/$(basename "$f")"
  done
  put_file "$LIVE/templates/opencode.json.template" templates/opencode.json.template 's/__AI_STACK__/__AI_STACK_HOME__/g'
fi

# --- Scripts: repo versions are path-agnostic and authoritative; import only new ones ---
if [ -d "$LIVE/platform/scripts" ]; then
  for f in "$LIVE"/platform/scripts/*.sh; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    if [ -e "$REPO/platform/scripts/$b" ]; then
      say "keep repo version of platform/scripts/$b"
    else
      say "$f -> platform/scripts/$b (new)"
      if [ "$DRY" = 0 ]; then
        sed -E 's|^AI_STACK_HOME="\$HOME/ai-stack"|AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"|' "$f" > "$REPO/platform/scripts/$b"
        chmod +x "$REPO/platform/scripts/$b"
      fi
    fi
  done
fi

if [ "$DRY" = 1 ]; then
  say "dry-run complete; check-secrets not run"
  exit 0
fi

say "running check-secrets"
"$REPO/scripts/check-secrets.sh"
