#!/usr/bin/env bash
# stop-platform.sh — Stop any running platform processes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

echo "[ai-stack] Stopping platform services..."

# Kill any lingering MCP server processes
pkill -f "mcp-ripgrep" 2>/dev/null && echo "  ✓ mcp-ripgrep stopped" || true
pkill -f "serena" 2>/dev/null && echo "  ✓ serena stopped" || true

echo "[ai-stack] Platform stopped."
