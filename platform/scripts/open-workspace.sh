#!/usr/bin/env bash
# open-workspace.sh <name> — Open a workspace with OpenCode
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

NAME="${1:?Usage: open-workspace.sh <name>}"
WS_DIR="$AI_STACK_HOME/workspaces/$NAME"

if [ ! -d "$WS_DIR" ]; then
  echo "[error] Workspace '$NAME' not found at $WS_DIR"
  exit 1
fi

echo "[ai-stack] Opening workspace: $NAME"
cd "$WS_DIR"
exec opencode
