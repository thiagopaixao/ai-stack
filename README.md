# ai-stack

Automação para **recriar do zero** a stack local de codificação assistida por IA:
OpenCode + oh-my-opencode-slim, Serena (análise semântica de código), Bitloops
(memória/contexto), MCP de ripgrep e utilitários — tudo isolado em um único
diretório (`~/ai-stack` por padrão), **sem sudo e sem Docker**.

Este repositório contém somente *código e configuração versionável*. Segredos,
memória, índices e workspaces ficam fora (veja [O que não é versionado](#o-que-não-é-versionado)).

## Componentes

| Componente | Papel | Instalação | Padrão |
|---|---|---|---|
| nvm + Node.js `24.16.0` | runtime JS (plugins, MCP) | `platform/runtime/nvm` | sim |
| uv / uvx | gerenciador Python | `~/.local/bin` (dados em `platform/runtime/python/share`) | sim |
| ripgrep `14.1.1` | busca rápida | `platform/runtime/node/rg` | sim |
| Serena `1.5.1` | MCP de análise semântica (LSP) | `uv tool install serena-agent` | sim |
| Bitloops `0.0.30` | memória/contexto de código | `platform/bitloops/bin` | sim |
| OpenCode `1.18.31` | agente de código (CLI/TUI) | instalador oficial → `platform/opencode/install` | sim |
| mcp-ripgrep | MCP de busca | npm em `platform/mcp` | sim |
| oh-my-opencode-slim | plugin de agentes/orquestração | declarado em `opencode.json`, pré-aquecido no cache | sim |
| 9router `0.5.95` | proxy/roteador de modelos (`http://127.0.0.1:20128/v1`) | npm global (nvm) | `--with 9router` |
| headroom-ai `0.38.0` | compressão de contexto | `uv tool install` | `--with headroom` |
| herdr `0.6.8` | runtime/multiplexador de agentes | binário em `~/.local/bin` | `--with herdr` |
| Paseo CLI `0.7.2` | `@getpaseo/cli` | npm global (nvm) | `--with paseo` |
| Bun `1.4.2` | runtime JS | `~/.bun` | `--with bun` |
| oh-my-openagent | plugin legado | `platform/opencode/cache` | `--with oh-my-openagent` (off) |

Versões ficam em [`lib/versions.sh`](lib/versions.sh) e podem ser sobrescritas por
ambiente: `NODE_VERSION=22.11.0 ./install.sh`.

## Pré-requisitos

`bash`, `curl`, `git`, `tar`. Recomendados: `jq`, `python3`; `unzip` (somente macOS,
para o Bitloops). Suporta Linux e macOS (x86_64/arm64).

## Início rápido

```bash
git clone <url-deste-repo> ai-stack-repo && cd ai-stack-repo
./install.sh            # instalação completa em ~/ai-stack
```

Algumas variações:

```bash
./install.sh --dry-run -y                    # mostra o que seria feito
./install.sh --config-only -y                # só configs/scripts/templates (sem downloads)
./install.sh --home /opt/ai-stack --shell    # outro destino + bloco no ~/.bashrc
./install.sh --with herdr,9router            # + opcionais
./install.sh --all-optional                  # todos os opcionais (exceto o legado)
./install.sh --only opencode-config,scripts  # somente alguns módulos
./install.sh --skip bitloops,serena          # pular módulos
./install.sh --list                          # lista módulos
```

### Flags

| Flag | Efeito |
|---|---|
| `--home <dir>` | destino (`AI_STACK_HOME`; padrão `~/ai-stack`) |
| `-y`, `--yes` | não-interativo |
| `--dry-run` | só imprime as ações |
| `--force` | sobrescreve arquivos protegidos (`~/.serena/serena_config.yml`) e substitui symlinks estrangeiros — sempre com backup |
| `--config-only` | módulos `01,09,11,12,13,14,15` (sem rede) |
| `--with <lista>` | opcionais: `9router,headroom,herdr,paseo,bun,oh-my-openagent` |
| `--all-optional` | todos os opcionais, exceto `oh-my-openagent` |
| `--only <lista>` / `--skip <lista>` | seleciona/pula módulos (nome ou número) |
| `--shell` | adiciona o bloco `# >>> ai-stack >>>` ao `~/.bashrc` |
| `--list` | lista módulos |

### Módulos (`installer/modules/NN-nome.sh`)

`00` prereqs · `01` directories · `02` node · `03` uv · `04` ripgrep · `05` serena ·
`06` bitloops · `07` opencode · `08` mcp · `09` opencode-config · `10` oh-my-opencode-slim ·
`11` serena-config · `12` bitloops-config · `13` scripts · `14` templates-docs ·
`15` secrets · `16` shell · `20`–`25` opcionais · `99` finalize.

Execução em ordem numérica, idempotente: o que já está na versão certa é pulado.
O log vai para `$AI_STACK_HOME/platform/logs/install-<timestamp>.log`.

### Política de arquivos

- Arquivo de destino diferente do repo → **backup** `<arquivo>.bak-<timestamp>` e sobrescrita.
- Diretório real que deveria ser symlink (ex.: `~/.config/opencode`) → movido para
  `<dir>.bak-<timestamp>`, conteúdo migrado (sem sobrescrever) para dentro da stack, symlink criado.
- `~/.serena/serena_config.yml` e `secrets.env` **nunca** são sobrescritos sem `--force` (secrets.env nunca).
- Templates `*.tmpl` têm `__AI_STACK_HOME__` e `__HOME__` substituídos na instalação (nenhum caminho de usuário fica fixo).

## Passos manuais pós-instalação

1. **Segredos**: edite `~/ai-stack/secrets.env` (criado a partir de `.env.example`, `chmod 600`) e preencha
   `NINEROUTER_API_KEY` (e opcionalmente `CONTEXT7_API_KEY`, `EXA_API_KEY`).
2. **Carregar ambiente**: `source ~/ai-stack/platform/scripts/load-env.sh` (ou instale com `--shell`).
   O `load-env.sh` carrega o `secrets.env` automaticamente.
3. **Login no GitHub Copilot**: `opencode auth login` (o token fica em `~/.local/share/opencode/auth.json`, fora do repo).
4. **9router** (se usado): inicie-o e configure o login/combos no painel; o OpenCode usa a chave via `{env:NINEROUTER_API_KEY}`.
5. **Workspace**: `~/ai-stack/platform/scripts/create-workspace.sh <nome> <git-url>`.
6. Healthcheck: `~/ai-stack/platform/scripts/healthcheck.sh`.

Embeddings locais do Bitloops (`bitloops-local-embeddings`) são baixados pelo próprio Bitloops
no primeiro `bitloops init --embeddings-runtime local` de um workspace — ver [docs/configuracao.md](docs/configuracao.md).

## O que não é versionado

| Item | Motivo |
|---|---|
| `secrets.env`, `auth.json` (OpenCode), `~/.9router/*`, `jwt-secret`, `~/.git-credentials` | credenciais/tokens |
| `workspaces/` | repositórios de trabalho (clones próprios, potencialmente privados) |
| `backup/` | cópias geradas localmente |
| `memory/` (Bitloops, sessões, raciocínio, contexto) | dados pessoais/de projeto, crescem sem limite |
| `indexes/` | derivados; regenerados por `reindex-workspace.sh` |
| `platform/runtime/`, `node_modules`, caches, logs | artefatos reconstruíveis pelo instalador |

`scripts/check-secrets.sh` (rodado em `make verify`) falha se algo parecido com segredo entrar no repo.

## Estrutura do repositório

```
install.sh / uninstall.sh      entrypoints
lib/                           common.sh (helpers), versions.sh (pins)
installer/modules/NN-*.sh      módulos (função module_<nome>)
config/                        opencode, mcp, bitloops, serena, shell (fonte de verdade das configs)
platform/scripts/              scripts operacionais → ~/ai-stack/platform/scripts
templates/  docs/              → ~/ai-stack/{templates,docs}
scripts/                       verify.sh, check-secrets.sh, sync-from-live.sh
.env.example                   modelo do secrets.env
```

Layout resultante em `~/ai-stack`: `platform/{opencode,serena,bitloops,mcp,runtime,config,scripts,…}`,
`memory/`, `indexes/`, `workspaces/`, `templates/`, `docs/`. Symlinks criados:
`~/.config/opencode`, `~/.local/share/opencode`, `~/.cache/opencode`, `~/.local/state/opencode`,
`~/.opencode`, `~/.local/share/bitloops`, `~/.local/share/uv`, `~/.config/bitloops/bitloops`.

## Atualizar o repo a partir da máquina viva

```bash
make sync     # scripts/sync-from-live.sh: copia configs/skills/scripts da stack viva para o repo (sem segredos)
git diff      # revise antes de commitar
```

## Verificar

```bash
make verify   # bash -n, shellcheck (se houver), JSON, check-secrets e instalação em sandbox ($HOME temporário)
```

## Desinstalar

```bash
./uninstall.sh --dry-run          # simula
./uninstall.sh                    # remove symlinks e o bloco do ~/.bashrc (dados permanecem)
./uninstall.sh --purge            # também apaga ~/ai-stack (confirma; recusa se workspaces/ não estiver vazio, salvo --force)
```

## Documentação

- [docs/arquitetura.md](docs/arquitetura.md) — visão geral e fluxo entre componentes
- [docs/configuracao.md](docs/configuracao.md) — configuração de OpenCode, Bitloops, Serena, MCP
- [docs/componentes.md](docs/componentes.md) — detalhes de cada componente
