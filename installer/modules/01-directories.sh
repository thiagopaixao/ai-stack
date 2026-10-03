#!/usr/bin/env bash
# 01-directories — cria a estrutura de diretórios em $AI_STACK_HOME

module_directories() {
  local h="$AI_STACK_HOME" d
  local dirs=(
    platform/opencode/data platform/opencode/cache platform/opencode/state platform/opencode/install
    platform/serena platform/bitloops/bin
    platform/mcp/configs platform/mcp/runtime platform/mcp/logs
    platform/runtime/nvm platform/runtime/node platform/runtime/java platform/runtime/python
    platform/config/mcp platform/config/opencode platform/config/bitloops
    platform/scripts platform/cache platform/logs platform/tmp
    memory/bitloops memory/sessions memory/reasoning memory/context
    indexes/serena indexes/retrieval
    workspaces templates docs
  )
  local paths=()
  for d in "${dirs[@]}"; do paths+=("$h/$d"); done
  if is_dry; then
    dryrun "mkdir -p (${#paths[@]} diretórios sob $h)"
  else
    mkdir -p "${paths[@]}"
  fi
  ok "Estrutura criada em $h"
}
