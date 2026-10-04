#!/usr/bin/env bash
# check-secrets.sh — scan the repo (excluding .git) for secrets and hardcoded home paths.
# Exit 1 with findings; exit 0 if clean.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

# name|ERE pattern
PATTERNS=(
  'openai-style key (sk-...)|sk-[A-Za-z0-9-]{10,}'
  'GitHub token ghp_|ghp_[A-Za-z0-9]+'
  'GitHub token gho_|gho_[A-Za-z0-9]+'
  'GitHub fine-grained PAT|github_pat_[A-Za-z0-9_]+'
  'literal apiKey|"apiKey"[[:space:]]*:[[:space:]]*"([^{"]|\{[^e])[^"]*"'
  'AWS access key|AKIA[0-9A-Z]{8,}'
  'private key block|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'Slack token|xox[bp]-[A-Za-z0-9-]+'
  'hardcoded home path|/home/th'"iago\\.paixao"
)

found=0
use_rg=0
command -v rg >/dev/null 2>&1 && use_rg=1

for entry in "${PATTERNS[@]}"; do
  name="${entry%%|*}"
  pat="${entry#*|}"
  if [ "$use_rg" = 1 ]; then
    out="$(rg -n --no-heading --hidden -g '!.git' -g '!scripts/check-secrets.sh' -e "$pat" . 2>/dev/null)"
  else
    out="$(grep -rnE --exclude-dir=.git --exclude=check-secrets.sh -e "$pat" . 2>/dev/null)"
  fi
  if [ -n "$out" ]; then
    found=1
    echo "[check-secrets] FOUND: $name"
    echo "$out" | sed 's/^/    /'
  fi
done

if [ "$found" = 1 ]; then
  echo "[check-secrets] FAILED: potential secrets / hardcoded paths found."
  exit 1
fi
echo "[check-secrets] OK: no secrets or hardcoded home paths found."
exit 0
