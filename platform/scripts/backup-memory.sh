#!/usr/bin/env bash
# backup-memory.sh — Backup memory and indexes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_HOME="${AI_STACK_HOME:-$HOME/ai-stack}"
export AI_STACK_HOME
source "$SCRIPT_DIR/load-env.sh"

BACKUP_DIR="$AI_STACK_HOME/platform/tmp/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "[ai-stack] Backing up memory..."
cp -r "$AI_STACK_HOME/memory" "$BACKUP_DIR/memory"
cp -r "$AI_STACK_HOME/indexes" "$BACKUP_DIR/indexes"

echo "[ai-stack] Backup saved to: $BACKUP_DIR"
