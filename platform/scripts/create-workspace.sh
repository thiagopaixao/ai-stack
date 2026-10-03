#!/usr/bin/env bash
# create-workspace.sh <name> [git-url]
# Creates a new isolated workspace
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

NAME="${1:?Usage: create-workspace.sh <name> [git-url]}"
GIT_URL="${2:-}"

WS_DIR="$AI_STACK_HOME/workspaces/$NAME"

if [ -d "$WS_DIR" ]; then
  echo "[error] Workspace '$NAME' already exists at $WS_DIR"
  exit 1
fi

echo "[ai-stack] Creating workspace: $NAME"

if [ -n "$GIT_URL" ]; then
  echo "  Cloning $GIT_URL ..."
  git clone "$GIT_URL" "$WS_DIR"
else
  mkdir -p "$WS_DIR"
  echo "  Empty workspace created."
fi

# Create workspace-local Serena config
mkdir -p "$WS_DIR/.serena"
cat > "$WS_DIR/.serena/config.yaml" << 'EOF'
# Serena workspace configuration
project_root: .
language_server:
  java:
    enabled: true
memory:
  enabled: true
EOF

# Create workspace-local indexes dir
mkdir -p "$AI_STACK_HOME/indexes/serena/$NAME"

# Create OpenCode MCP config for this workspace
cat > "$WS_DIR/opencode.json" << OPENCODE
{
  "mcp": {
    "serena": {
      "type": "stdio",
      "command": "serena",
      "args": ["start-mcp-server", "--project-from-cwd"]
    },
    "ripgrep": {
      "type": "stdio",
      "command": "node",
      "args": ["$AI_STACK_HOME/platform/mcp/node_modules/mcp-ripgrep/dist/index.js"]
    }
  }
}
OPENCODE

# Initialize Bitloops (local-only, no external API)
cd "$WS_DIR"
bitloops init --no-telemetry --embeddings-runtime local --no-context-guidance --no-summaries --install-default-daemon --sync=true --ingest=false --force 2>&1 | tail -3

# Register in memory
mkdir -p "$AI_STACK_HOME/memory/context"
echo "{\"workspace\": \"$NAME\", \"created\": \"$(date -Iseconds)\", \"path\": \"$WS_DIR\"}" \
  >> "$AI_STACK_HOME/memory/context/workspaces.jsonl"

echo "[ai-stack] Workspace '$NAME' ready at: $WS_DIR"
echo "  Open with: cd $WS_DIR && opencode"
