#!/usr/bin/env bash
# 14-templates-docs — templates/ e docs/ -> $AI_STACK_HOME

module_templates_docs() {
  local rc=0
  if [ -d "$REPO_DIR/templates" ]; then
    deploy_tree "$REPO_DIR/templates" "$AI_STACK_HOME/templates" || rc=1
  else
    warn "assets ausentes: $REPO_DIR/templates"
  fi
  if [ -d "$REPO_DIR/docs" ]; then
    deploy_tree "$REPO_DIR/docs" "$AI_STACK_HOME/docs" || rc=1
  else
    warn "assets ausentes: $REPO_DIR/docs"
  fi
  is_dry && return 0
  return "$rc"
}
