# Arquitetura da Plataforma — ai-stack

## Filosofia

A plataforma segue três princípios fundamentais:

1. **Workspace isolation** — cada microserviço é um contexto isolado
2. **Local-first** — tudo roda na máquina, dados ficam locais
3. **Composable intelligence** — ferramentas especializadas cooperam via MCP

---

## Camadas

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE INTERAÇÃO                        │
│  OpenCode (CLI) + oh-my-opencode-slim (orquestração)         │
│    ←→ LLM (GitHub Copilot; 9router opcional como fallback)   │
│  IntelliJ IDEA                                               │
└──────────────────────────────┬──────────────────────────────┘
                               │ MCP (stdio)
┌──────────────────────────────▼──────────────────────────────┐
│                    CAMADA DE INTELIGÊNCIA                     │
│  Serena (navegação semântica, LSP)                           │
│  Ripgrep MCP (busca textual rápida)                          │
│  Bitloops (memória, embeddings, provenance)                  │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    CAMADA DE DADOS                            │
│  Workspace (código fonte, Git)                               │
│  SQLite / DuckDB (Bitloops stores)                           │
│  Serena indexes (language server state)                      │
│  Embeddings locais                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Fluxo de Dados

### Edição assistida

```
Usuário → OpenCode → LLM (gera código)
                   → Serena MCP (navega, edita semanticamente)
                   → Ripgrep MCP (busca contexto)
                   → Bitloops (captura decisão automaticamente)
```

### Retrieval

```
OpenCode pergunta "como funciona X?"
  → Serena: find_symbol, get_references
  → Ripgrep: busca textual complementar
  → Bitloops: DevQL (queries estruturadas)
  → LLM: sintetiza resposta
```

### Memória

```
Sessão de trabalho
  → Bitloops hooks capturam conversas
  → Embeddings locais indexam mudanças
  → Checkpoint criado por commit
  → Próxima sessão: Bitloops serve contexto relevante
```

---

## Boundaries

### Active Context (edição permitida)

- O workspace corrente (`pwd`)
- Arquivos dentro do diretório do workspace
- Serena opera SOMENTE neste escopo

### Passive Context (somente leitura)

- Outros workspaces em `$AI_STACK_HOME/workspaces/` (padrão `~/ai-stack/workspaces/`)
- Acessíveis via ripgrep (busca textual)
- Não editáveis pelo agente

### Shared Intelligence

- Bitloops daemon é global (1 por máquina)
- Cada workspace tem estado independente
- DevQL pode consultar cross-workspace (read-only)

---

## MCP Protocol

### Por que MCP?

MCP (Model Context Protocol) é o padrão aberto para conectar LLMs a ferramentas. Vantagens:

- Agnóstico de LLM — funciona com qualquer modelo
- Stdio transport — sem servidor HTTP, sem porta exposta
- On-demand — processos iniciam quando necessários
- Isolado — cada tool é um processo separado

### Transport

Usamos **stdio** (não HTTP). O OpenCode spawna os processos e se comunica via stdin/stdout. Zero configuração de rede.

---

## Orquestração de agentes e provedores de modelo

- **Plugin principal:** `oh-my-opencode-slim` (declarado em `opencode.json` e `tui.json`). Define os agentes
  (orchestrator, oracle, librarian, explorer, designer, fixer) e seus presets em `oh-my-opencode-slim.json`.
  O preset alternativo `presets/oh-my-opencode-slim.no-github.json` usa apenas modelos do 9router.
- **Plugin legado/opcional:** `oh-my-openagent` (`oh-my-openagent.json`). Mantido apenas por compatibilidade;
  não está registrado em `opencode.json`.
- **Provedores de modelo:** `github-copilot` (login via `opencode auth login`) é o principal.
  O **9router** (`127.0.0.1:20128`) é um provedor OpenAI-compatível **opcional**, usado como fallback nos
  presets; sua chave vem de `NINEROUTER_API_KEY` (arquivo `$AI_STACK_HOME/secrets.env`, nunca versionado).

---

## Segredos

Nenhum segredo é versionado. O `opencode.json` referencia `{env:NINEROUTER_API_KEY}`; o valor real fica em
`$AI_STACK_HOME/secrets.env` (chmod 600), carregado automaticamente por `platform/scripts/load-env.sh`.
Use `scripts/check-secrets.sh` antes de qualquer commit. Veja `.env.example` e `docs/componentes.md`.

---

## Decisões Arquiteturais

| Decisão | Motivo |
|---------|--------|
| NVM local (não global) | Isolamento, removibilidade |
| uv (não pip global) | Instala Serena sem poluir sistema |
| Bitloops sem summaries | Evita dependência de API externa |
| Embeddings locais | Funciona offline |
| 1 workspace = 1 repo | Previne contaminação cross-context |
| Serena `--project-from-cwd` | Auto-detecta projeto, menos configuração manual |
| Ripgrep binário local | Não depende de pacote do sistema |
| Segredos em `secrets.env` (fora do Git) | Configs versionáveis sem credenciais |
| oh-my-opencode-slim como plugin principal | Orquestração leve com presets por agente |
