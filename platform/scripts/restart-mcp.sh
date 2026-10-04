#!/usr/bin/env bash
# restart-mcp.sh — Restart MCP servers (kill existing, they restart on-demand)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/stop-platform.sh"
echo "[ai-stack] MCP servers will restart on next OpenCode session."
