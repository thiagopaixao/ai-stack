# Guia de Configuração — ai-stack

## Auto-contenção (Symlinks)

Toda a plataforma é auto-contida em `$AI_STACK_HOME` (padrão `~/ai-stack/`). O instalador deste repositório cria esses diretórios e symlinks. Ferramentas que gravam em locais padrão XDG são redirecionadas via symlinks:

| Symlink | Destino real em ai-stack |
|---------|--------------------------|
| `~/.config/opencode` | `platform/config/opencode/` |
| `~/.config/bitloops` | `platform/config/bitloops/` |
| `~/.local/share/opencode` | `platform/opencode/data/` |
| `~/.cache/opencode` | `platform/opencode/cache/` |
| `~/.local/state/opencode` | `platform/opencode/state/` |
| `~/.local/share/uv` | `platform/runtime/python/share/` |
| `~/.local/share/bitloops` | `memory/bitloops/` |
| `~/.opencode` | `platform/opencode/install/` |
| `~/.config/bitloops/bitloops` | `platform/config/bitloops/` |

Para remover tudo: use `uninstall.sh` ou delete `$AI_STACK_HOME` e os symlinks acima.

---

## Configuração do Bitloops

### Config principal

Template: `config/bitloops/config.toml.tmpl` (o instalador substitui `__HOME__`). Localização instalada: `$AI_STACK_HOME/platform/config/bitloops/config.toml` (acessível via `~/.config/bitloops/config.toml`). O runtime de embeddings usa `command = "bitloops-local-embeddings"` (resolvido via PATH).

```toml
[runtime]
local_dev = false
cli_version = "0.0.30"

[stores]

[stores.relational]
sqlite_path = "__HOME__/.local/share/bitloops/stores/relational/relational.db"

[stores.events]
duckdb_path = "__HOME__/.local/share/bitloops/stores/event/events.duckdb"

[stores.blob]
local_path = "__HOME__/.local/share/bitloops/stores/blob"

[logging]

[telemetry]
enabled = false

[inference.runtimes.bitloops_local_embeddings]
command = "bitloops-local-embeddings"
```

### Flags de inicialização por workspace

```bash
bitloops init \
  --no-telemetry \
  --embeddings-runtime local \
  --no-context-guidance \
  --no-summaries \
  --sync=true \
  --ingest=false \
  --force
```

| Flag | Propósito |
|------|-----------|
| `--embeddings-runtime local` | Embeddings computados localmente (sem API) |
| `--no-context-guidance` | Não usa LLM para resumos de contexto |
| `--no-summaries` | Não gera resumos automáticos |
| `--no-telemetry` | Zero dados enviados para fora |
| `--sync=true` | Sincroniza codebase no init |
| `--ingest=false` | Não ingere histórico Git (mais rápido) |

### Habilitar ingest histórico

Para projetos com histórico relevante:

```bash
bitloops init --ingest=true --backfill=100
```

Isso analisa os últimos 100 commits para construir contexto.

---

## Configuração do Serena

### Config global

Template: `config/serena/serena_config.yml.tmpl` (com `projects: []`; o Serena registra projetos automaticamente). Instalada em `~/.serena/serena_config.yml`.

### Config por workspace

Arquivo: `<workspace>/.serena/config.yaml`

```yaml
project_root: .
language_server:
  java:
    enabled: true
memory:
  enabled: true
```

### Detecção automática de projeto

O Serena usa `--project-from-cwd` para detectar automaticamente o projeto a partir do diretório corrente.
Isso elimina a necessidade de configurar o projeto manualmente — basta abrir o OpenCode dentro do workspace.

| Contexto (Serena) | Uso |
|----------|-----|
| `desktop-app` (padrão) | Completo. Para exploração arquitetural. |
| `agent` | Otimizado para agentes CLI. |
| `ide` | Para integração com IDEs. |

Especificar no `opencode.json`:
```json
"args": ["start-mcp-server", "--project-from-cwd"]
```

---

## Configuração do OpenCode MCP

### Arquivo global: `$AI_STACK_HOME/platform/config/opencode/opencode.json`

Template no repositório: `config/opencode/opencode.json.tmpl` (o instalador substitui `__AI_STACK_HOME__`).
MCPs são declarados globalmente (não por workspace). O plugin principal é `oh-my-opencode-slim`;
o 9router é um provedor **opcional** cuja chave vem da variável de ambiente `NINEROUTER_API_KEY`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "9router": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "9Router",
      "options": {
        "baseURL": "http://127.0.0.1:20128/v1",
        "apiKey": "{env:NINEROUTER_API_KEY}"
      },
      "models": { "go-coding": { "name": "Go Coding" } }
    }
  },
  "mcp": {
    "serena": {
      "type": "local",
      "command": ["serena", "start-mcp-server", "--project-from-cwd"],
      "enabled": true
    },
    "ripgrep": {
      "type": "local",
      "command": ["node", "__AI_STACK_HOME__/platform/mcp/node_modules/mcp-ripgrep/dist/index.js"],
      "enabled": true
    }
  },
  "plugin": ["oh-my-opencode-slim"]
}
```

### Plugin oh-my-opencode-slim

- Config: `oh-my-opencode-slim.json` (preset ativo `java-spring-legacy`, modelos `github-copilot/*` com fallback `9router/*`).
- Preset alternativo sem GitHub Copilot: `config/opencode/presets/oh-my-opencode-slim.no-github.json`
  (copie sobre `~/.config/opencode/oh-my-opencode-slim.json` para usar apenas 9router).
- Skills locais: `config/opencode/skills/` (create-microservice, simplify, clonedeps, verification-planning,
  reflect, worktrees, codemap, deepwork, oh-my-opencode-slim).
- `oh-my-openagent` é **legado/opcional**: `oh-my-openagent.json` é mantido apenas para quem optar por esse plugin.

### Adicionar novos MCP servers

Basta adicionar mais entradas no `~/ai-stack/platform/config/opencode/opencode.json`:

```json
{
  "mcp": {
    "serena": { ... },
    "ripgrep": { ... },
    "meu-mcp": {
      "type": "stdio",
      "command": "path/to/binary",
      "args": ["--flag"]
    }
  }
}
```

---

## Variáveis de Ambiente

Definidas pelo `load-env.sh`:

| Variável | Valor |
|----------|-------|
| `AI_STACK_HOME` | `~/ai-stack` (sobrescrevível via ambiente) |
| `NVM_DIR` | `~/ai-stack/platform/runtime/nvm` |
| `MCP_RIPGREP_BIN` | `~/ai-stack/platform/mcp/node_modules/.bin/mcp-ripgrep` |
| `SERENA_BIN` | `~/.local/bin/serena` |
| `BITLOOPS_BIN` | `~/ai-stack/platform/bitloops/bin/bitloops` |
| `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS` | `true` |
| `OPENCODE_ENABLE_EXA` | `1` |
| `NINEROUTER_API_KEY` (e outras) | lidas de `$AI_STACK_HOME/secrets.env` se existir |

### secrets.env

Arquivo opcional `$AI_STACK_HOME/secrets.env` (chmod 600, **nunca versionado**), carregado por `load-env.sh`
com `set -a`. Modelo em `.env.example`:

```bash
NINEROUTER_API_KEY=...      # chave do 9router (provedor opcional)
CONTEXT7_API_KEY=           # opcional
EXA_API_KEY=                # opcional
```

---

## Shell Integration (Opcional)

Para carregar automaticamente em novos terminais, o bloco abaixo é adicionado ao `~/.bashrc` ou `~/.zshrc`:

```bash
# >>> ai-stack >>>
[ -f "$HOME/ai-stack/platform/scripts/load-env.sh" ] && source "$HOME/ai-stack/platform/scripts/load-env.sh"
export PATH="$HOME/.opencode/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
export OPENCODE_ENABLE_EXA=1
# <<< ai-stack <<<
```

O instalador adiciona esse bloco automaticamente (`config/shell/bashrc.snippet`).

---

## Atualização de Componentes

### Serena

```bash
source ~/ai-stack/platform/scripts/load-env.sh
uv tool upgrade serena-agent
```

### Bitloops

```bash
curl -fsSL https://bitloops.com/install.sh | sed 's|INSTALL_DIR="/usr/local/bin"|INSTALL_DIR="$HOME/ai-stack/platform/bitloops/bin"|' | bash
```

### mcp-ripgrep

```bash
source ~/ai-stack/platform/scripts/load-env.sh
cd ~/ai-stack/platform/mcp && npm update mcp-ripgrep
```

### oh-my-openagent (legado/opcional)

```bash
source ~/ai-stack/platform/scripts/load-env.sh
cd ~/ai-stack/platform/opencode/cache/packages/oh-my-openagent@latest
npm install
```

### Node.js

```bash
source ~/ai-stack/platform/scripts/load-env.sh
nvm install --lts
nvm alias default lts/*
```

---

## Troubleshooting — oh-my-openagent (legado/opcional)

> O plugin principal é `oh-my-opencode-slim`. Esta seção só se aplica a quem registrar o `oh-my-openagent` manualmente.

### Plugin não carrega / sem efeito visível no OpenCode

**Sintoma:** MCPs funcionam mas oh-my-openagent não mostra agentes, slash commands, ou routing inteligente.

**Causa raiz:** O OpenCode resolve plugins em `~/.cache/opencode/packages/<plugin>@latest/node_modules/`. Se esse diretório está vazio ou faltam dependências transitivas (ex: `zod/v3`), o plugin falha silenciosamente.

**Diagnóstico:**

```bash
# Verificar nos logs do OpenCode
grep -i "oh-my-openagent\|plugin" ~/.local/share/opencode/log/*.log | grep -i error

# Erro típico:
# Cannot find module 'zod/v3' from '.../oh-my-openagent/dist/index.js'
```

**Solução:**

```bash
source ~/ai-stack/platform/scripts/load-env.sh
cd ~/ai-stack/platform/opencode/cache/packages/oh-my-openagent@latest
npm install
# Reiniciar OpenCode
```

**Verificação:**

```bash
node -e "require.resolve('zod/v3', {paths: ['$HOME/ai-stack/platform/opencode/cache/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/dist']})" && echo OK
```

### Plugin instalado mas config não existe

O arquivo `~/.config/opencode/oh-my-openagent.json` deve existir com a configuração dos agentes. Sem ele, o plugin carrega mas não tem routing configurado.

```bash
# Copiar a config do repositório:
cp config/opencode/oh-my-openagent.json ~/.config/opencode/oh-my-openagent.json
```
