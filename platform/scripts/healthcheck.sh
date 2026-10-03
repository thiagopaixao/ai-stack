#!/usr/bin/env bash
# healthcheck.sh — Verify platform health
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

echo "═══════════════════════════════════════"
echo "  ai-stack Health Check"
echo "═══════════════════════════════════════"

check() {
  if eval "$2" > /dev/null 2>&1; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1"
  fi
}

check "NVM loaded" "command -v nvm"
check "Node.js" "node --version"
check "npm" "npm --version"
check "uv" "uv --version"
check "Serena" "serena --version"
check "Bitloops" "bitloops --version"
check "mcp-ripgrep module" "test -f $AI_STACK_HOME/platform/mcp/node_modules/.bin/mcp-ripgrep"
check "ripgrep (rg)" "command -v rg"
check "OpenCode" "command -v opencode"
check "oh-my-opencode-slim (registered)" "grep -q oh-my-opencode-slim $HOME/.config/opencode/opencode.json"
check "oh-my-opencode-slim (config)" "test -f $HOME/.config/opencode/oh-my-opencode-slim.json"
check "secrets.env (optional, 9router key)" "test -f $AI_STACK_HOME/secrets.env"
check "Memory dir" "test -d $AI_STACK_HOME/memory"
check "Indexes dir" "test -d $AI_STACK_HOME/indexes"
check "Workspaces dir" "test -d $AI_STACK_HOME/workspaces"

echo "═══════════════════════════════════════"
