# Componentes — ai-stack

Versões observadas na instalação de referência (live). `$AI_STACK_HOME` = `~/ai-stack` por padrão.

## Obrigatórios

| Componente | Versão observada | Como é instalado | Onde fica a configuração |
|------------|------------------|------------------|--------------------------|
| OpenCode | 1.18.31 | Instalador oficial (`curl`) em `~/.opencode`, que é symlink para `$AI_STACK_HOME/platform/opencode/install` | `~/.config/opencode` → `$AI_STACK_HOME/platform/config/opencode` (`config/opencode/` no repo) |
| Node.js | v24.16.0 | via nvm local em `$AI_STACK_HOME/platform/runtime/nvm` | `NVM_DIR` definido por `load-env.sh` |
| uv | 0.12.17 | instalador oficial; binário em `~/.local/bin` | dados em `~/.local/share/uv` → `platform/runtime/python/share` |
| Serena | 1.5.1 | `uv tool install serena-agent` | `~/.serena/serena_config.yml` (`config/serena/serena_config.yml.tmpl`) |
| Bitloops CLI | 0.0.30 | instalador oficial, binário em `$AI_STACK_HOME/platform/bitloops/bin` | `~/.config/bitloops/config.toml` (`config/bitloops/config.toml.tmpl`) |
| ripgrep | 14.1.1 | binário local (`@vscode/ripgrep` / runtime) | — |
| mcp-ripgrep | ^0.4.0 | `npm install` em `$AI_STACK_HOME/platform/mcp` (deps: `mcp-ripgrep`, `@vscode/ripgrep`) | `config/mcp/package.json`, `config/mcp/opencode-mcp.json.tmpl` |
| oh-my-opencode-slim | atual (`@latest`) | plugin do OpenCode (declarado em `opencode.json`/`tui.json`) | `oh-my-opencode-slim.json`, `presets/`, `skills/` |
| bun | 1.4.2 | instalador oficial em `~/.bun` | `BUN_INSTALL=$HOME/.bun` (bashrc snippet) |

## Legado

| Componente | Observação |
|------------|-----------|
| oh-my-openagent | Plugin anterior. Apenas `oh-my-openagent.json` é mantido no repo; não é registrado em `opencode.json`. |

## Opcionais

| Componente | Versão observada | Como é instalado | Notas |
|------------|------------------|------------------|-------|
| 9router | 0.5.95 | `npm install -g 9router` | Roteador local OpenAI-compatível em `127.0.0.1:20128`; provedor `9router` em `opencode.json`. Requer `NINEROUTER_API_KEY`. |
| headroom-ai | 0.38.0 | `uv tool install headroom-ai` | Proxy de compressão de contexto em `:8787`. |
| herdr | 0.6.8 | binário em `~/.local/bin` | Instala o plugin `plugins/herdr-agent-state.js` no OpenCode (gerenciado pelo herdr). |
| @getpaseo/cli | 0.7.2 | `npm install -g @getpaseo/cli` | CLI do Paseo. |

## Mapa de symlinks

| Symlink | Destino |
|---------|---------|
| `~/.config/opencode` | `$AI_STACK_HOME/platform/config/opencode` |
| `~/.local/share/opencode` | `$AI_STACK_HOME/platform/opencode/data` |
| `~/.cache/opencode` | `$AI_STACK_HOME/platform/opencode/cache` |
| `~/.local/state/opencode` | `$AI_STACK_HOME/platform/opencode/state` |
| `~/.opencode` | `$AI_STACK_HOME/platform/opencode/install` |
| `~/.local/share/bitloops` | `$AI_STACK_HOME/memory/bitloops` |
| `~/.local/share/uv` | `$AI_STACK_HOME/platform/runtime/python/share` |
| `~/.config/bitloops/bitloops` | `$AI_STACK_HOME/platform/config/bitloops` |

## Segredos (configuração manual pós-instalação)

Nada disso é versionado ou instalado automaticamente:

1. **`NINEROUTER_API_KEY`** — crie `$AI_STACK_HOME/secrets.env` (chmod 600) a partir de `.env.example`.
   Carregado por `load-env.sh`; referenciado em `opencode.json` como `{env:NINEROUTER_API_KEY}`.
   (Opcionais: `CONTEXT7_API_KEY`, `EXA_API_KEY`.)
2. **GitHub Copilot** — `opencode auth login` (selecionar `github-copilot`). Credenciais ficam em
   `~/.local/share/opencode/auth.json` (nunca versionar).
3. **9router** (se usado) — faça login no dashboard do 9router e gere/obtenha a chave de API.
4. **GitHub CLI** — `gh auth login` (usado por skills/MCP `gh_grep` e fluxos de worktree).

Antes de qualquer commit: `scripts/check-secrets.sh`. Para re-exportar a stack local: `scripts/sync-from-live.sh`.
