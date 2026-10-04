#!/usr/bin/env bash
# start-platform.sh — Start MCP servers and platform services
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

LOGS="$AI_STACK_HOME/platform/logs"
PIDS="$AI_STACK_HOME/platform/tmp"

echo "[ai-stack] Starting platform services..."

# MCP servers are started on-demand by OpenCode via stdio transport
# This script validates readiness

echo "[ai-stack] Verifying runtimes..."
node --version > /dev/null 2>&1 && echo "  ✓ Node.js $(node --version)"
serena --version > /dev/null 2>&1 && echo "  ✓ Serena available"
bitloops --version > /dev/null 2>&1 && echo "  ✓ Bitloops available"

echo "[ai-stack] Platform ready. MCP servers will start on-demand via OpenCode."
