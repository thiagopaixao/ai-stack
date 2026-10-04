#!/usr/bin/env bash
# reindex-workspace.sh <name> — Reindex a workspace with Serena
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

NAME="${1:?Usage: reindex-workspace.sh <name>}"
WS_DIR="$AI_STACK_HOME/workspaces/$NAME"

if [ ! -d "$WS_DIR" ]; then
  echo "[error] Workspace '$NAME' not found"
  exit 1
fi

echo "[ai-stack] Reindexing workspace: $NAME"
cd "$WS_DIR"
serena init 2>&1 || echo "[warn] Serena init completed with warnings"
echo "[ai-stack] Reindex complete."
