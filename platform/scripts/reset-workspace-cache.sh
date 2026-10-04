#!/usr/bin/env bash
# reset-workspace-cache.sh <name>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

NAME="${1:?Usage: reset-workspace-cache.sh <name>}"

echo "[ai-stack] Resetting cache for workspace: $NAME"
rm -rf "$AI_STACK_HOME/indexes/serena/$NAME"
rm -rf "$AI_STACK_HOME/platform/cache/$NAME"
mkdir -p "$AI_STACK_HOME/indexes/serena/$NAME"
echo "[ai-stack] Cache reset complete."
