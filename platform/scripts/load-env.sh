#!/usr/bin/env bash
# load-env.sh — Loads the ai-stack local environment
# Source this file: . "${AI_STACK_HOME:-$HOME/ai-stack}/platform/scripts/load-env.sh"
# Safe to source multiple times and from `set -u` callers.

export AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export NVM_DIR="$AI_STACK_HOME/platform/runtime/nvm"

# Prepend a directory to PATH only if it is not already present (idempotent)
_ai_stack_path_prepend() {
  case ":${PATH:-}:" in
    *":$1:"*) ;;
    *) export PATH="$1${PATH:+:$PATH}" ;;
  esac
}

_ai_stack_path_prepend "$AI_STACK_HOME/platform/runtime/python"
_ai_stack_path_prepend "$AI_STACK_HOME/platform/runtime/node"
_ai_stack_path_prepend "$AI_STACK_HOME/platform/bitloops/bin"
_ai_stack_path_prepend "$HOME/.bun/bin"
_ai_stack_path_prepend "$HOME/.opencode/bin"
_ai_stack_path_prepend "$HOME/.local/bin"
unset -f _ai_stack_path_prepend

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

# Load NVM (nvm.sh is not `set -u` safe; relax it temporarily)
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _ai_stack_u_was_set=0
  case "$-" in *u*) _ai_stack_u_was_set=1; set +u ;; esac
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  [ "$_ai_stack_u_was_set" = "1" ] && set -u
  unset _ai_stack_u_was_set
fi

# Oh-My-OpenAgent — disable telemetry
export OMO_SEND_ANONYMOUS_TELEMETRY=0
export OMO_DISABLE_POSTHOG=1

# OpenCode / oh-my-opencode-slim
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
export OPENCODE_ENABLE_EXA=1

# MCP runtime paths
export MCP_RIPGREP_BIN="$AI_STACK_HOME/platform/mcp/node_modules/.bin/mcp-ripgrep"
export SERENA_BIN="$HOME/.local/bin/serena"
export BITLOOPS_BIN="$AI_STACK_HOME/platform/bitloops/bin/bitloops"

# Secrets (never committed): API keys such as NINEROUTER_API_KEY
if [ -f "$AI_STACK_HOME/secrets.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$AI_STACK_HOME/secrets.env"
  set +a
fi

echo "[ai-stack] Environment loaded (node=$(node --version 2>/dev/null || echo 'N/A'), uv=$(uv --version 2>/dev/null || echo 'N/A'))"
