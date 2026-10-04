#!/usr/bin/env bash
# verify.sh — valida o repositório e roda um teste de instalação em sandbox.
#   1. bash -n em todos os *.sh
#   2. shellcheck (se disponível; avisos não são fatais)
#   3. validação JSON (*.json, *.json.tmpl, *.json.template)
#   4. scripts/check-secrets.sh (se existir)
#   5. sandbox: HOME temporário + install.sh --config-only -y, com asserts
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

FAILS=0; WARNS=0
pass() { printf '  [ok] %s\n' "$*"; }
fail() { printf '  [FAIL] %s\n' "$*" >&2; FAILS=$((FAILS + 1)); }
note() { printf '  [warn] %s\n' "$*" >&2; WARNS=$((WARNS + 1)); }
section() { printf '\n== %s ==\n' "$*"; }

list_files() { # list_files GLOB...  (ignora .git, node_modules)
  find . \( -path ./.git -o -name node_modules \) -prune -o -type f \( "$@" \) -print | sort
}

# ---------------------------------------------------------------- 1. syntax
section "bash -n"
mapfile -t SH_FILES < <(list_files -name '*.sh')
for f in "${SH_FILES[@]}"; do
  if bash -n "$f" 2>/tmp/verify-bashn.$$; then :; else fail "sintaxe: $f: $(cat /tmp/verify-bashn.$$)"; fi
done
rm -f /tmp/verify-bashn.$$
pass "${#SH_FILES[@]} scripts verificados"

# ------------------------------------------------------------- 2. shellcheck
section "shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -x -S warning "${SH_FILES[@]}" >/tmp/verify-sc.$$ 2>&1; then
    pass "shellcheck limpo"
  else
    note "shellcheck reportou avisos (não fatal):"
    head -40 /tmp/verify-sc.$$ >&2
  fi
  rm -f /tmp/verify-sc.$$
else
  note "shellcheck não instalado; pulando"
fi

# ------------------------------------------------------------------ 3. JSON
section "JSON"
mapfile -t JSON_FILES < <(list_files -name '*.json' -o -name '*.json.tmpl' -o -name '*.json.template')
json_ok() {
  if command -v jq >/dev/null 2>&1; then jq -e . "$1" >/dev/null 2>&1
  elif command -v python3 >/dev/null 2>&1; then python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1
  else return 2; fi
}
if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  note "nem jq nem python3: validação JSON pulada"
else
  for f in "${JSON_FILES[@]}"; do
    json_ok "$f" || fail "JSON inválido: $f"
  done
  pass "${#JSON_FILES[@]} arquivos JSON verificados"
fi

# -------------------------------------------------------------- 4. secrets
section "check-secrets"
if [ -x scripts/check-secrets.sh ] || [ -f scripts/check-secrets.sh ]; then
  if bash scripts/check-secrets.sh >/tmp/verify-secrets.$$ 2>&1; then
    pass "check-secrets.sh ok"
  else
    fail "check-secrets.sh falhou:"; cat /tmp/verify-secrets.$$ >&2
  fi
  rm -f /tmp/verify-secrets.$$
else
  note "scripts/check-secrets.sh ausente; pulando"
fi

# --------------------------------------------------------------- 5. sandbox
section "sandbox (install --config-only)"
SANDBOX="$(mktemp -d)"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT
SB_HOME="$SANDBOX/home"; mkdir -p "$SB_HOME"
SB_STACK="$SB_HOME/ai-stack"

if env -i PATH="$PATH" HOME="$SB_HOME" AI_STACK_HOME="$SB_STACK" \
     bash "$REPO_DIR/install.sh" --config-only -y >"$SANDBOX/install.log" 2>&1; then
  pass "install.sh --config-only terminou sem erro"
else
  fail "install.sh --config-only falhou (últimas linhas):"; tail -20 "$SANDBOX/install.log" >&2
fi

assert_file() { [ -f "$1" ] && pass "existe: ${1#"$SB_HOME"/}" || fail "ausente: ${1#"$SB_HOME"/}"; }
CFG="$SB_STACK/platform/config/opencode"
assert_file "$CFG/opencode.json"
assert_file "$SB_STACK/platform/scripts/load-env.sh"
assert_file "$SB_HOME/.serena/serena_config.yml"
assert_file "$SB_STACK/secrets.env"
assert_file "$SB_STACK/platform/config/bitloops/config.toml"
assert_file "$SB_HOME/.config/bitloops/config.toml"
[ -x "$SB_STACK/platform/scripts/load-env.sh" ] && pass "load-env.sh executável" || fail "load-env.sh não executável"

if [ -L "$SB_HOME/.config/opencode" ] && [ "$(readlink "$SB_HOME/.config/opencode")" = "$CFG" ]; then
  pass "symlink ~/.config/opencode"
else
  fail "symlink ~/.config/opencode incorreto"
fi

if [ -f "$CFG/opencode.json" ]; then
  if grep -Eq '__[A-Z][A-Z_]*__' "$CFG/opencode.json"; then
    fail "opencode.json ainda contém placeholders"
  else
    pass "opencode.json sem placeholders"
  fi
  grep -q "$SB_STACK" "$CFG/opencode.json" && pass "opencode.json aponta para o AI_STACK_HOME do sandbox" \
    || note "opencode.json não referencia AI_STACK_HOME (ok se o template não usar)"
fi
grep -Eq '__[A-Z][A-Z_]*__' "$SB_HOME/.config/bitloops/config.toml" 2>/dev/null \
  && fail "bitloops config.toml com placeholders" || true
if [ "$(stat -c %a "$SB_STACK/secrets.env" 2>/dev/null)" = "600" ]; then pass "secrets.env chmod 600"; else fail "secrets.env sem chmod 600"; fi

# idempotência: segunda execução não deve falhar
if env -i PATH="$PATH" HOME="$SB_HOME" AI_STACK_HOME="$SB_STACK" \
     bash "$REPO_DIR/install.sh" --config-only -y >"$SANDBOX/install2.log" 2>&1; then
  pass "segunda execução idempotente"
else
  fail "segunda execução falhou"; tail -20 "$SANDBOX/install2.log" >&2
fi

# --------------------------------------------------------------------------
section "resultado"
echo "  falhas: $FAILS  avisos: $WARNS"
[ "$FAILS" -eq 0 ]
