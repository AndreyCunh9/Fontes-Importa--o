# Arquivos de Instruções para Agentes

Esta pasta contém **arquivos de instruções globais** que orientam assistentes de IA ao trabalhar em workspaces de **TOTVS Protheus ERP** (AdvPL/TLPP). Os arquivos definem convenções de linguagem, estrutura de projeto, padrões de código, type system e referenciam o catálogo de skills disponíveis em [`../skills/advpl-tlpp/`](../skills/advpl-tlpp/).

---

## Arquivos

| Arquivo | Destinatário | Descrição |
|---------|--------------|-----------|
| [AGENTS.md](AGENTS.md) | Agentes genéricos (GitHub Copilot, Codex, Cursor, etc. que seguem o padrão `AGENTS.md`) | Diretrizes de desenvolvimento AdvPL/TLPP para o ecossistema Protheus. |
| [CLAUDE.md](CLAUDE.md) | Claude Code e variantes que seguem o padrão `CLAUDE.md` | Mesmo conteúdo de `AGENTS.md`, replicado para compatibilidade com agentes que esperam o nome `CLAUDE.md`. |

> Atualmente os dois arquivos são **idênticos** — mantenha-os sincronizados ao editar.

---

## Conteúdo Coberto

Ambos os arquivos abrangem:

- **Linguagem e Ecossistema** — AdvPL (`.prw`, `.prg`, `.prx`), TLPP (`.tlpp`) e testes Python TIR. Idioma padrão de interação: **Português do Brasil**.
- **Estrutura de Projeto** — Layout de `Fontes_Doc/`, `Testes/Automação Protheus/` e `.agents/skills/`.
- **Convenções de Código** — Notação Húngara obrigatória, nomes de fontes (prefixo de 4 chars + 3 dígitos), nomes de tabelas/campos e constantes multilíngue (`STR0001`–`STR9999`).
- **Type System** — Tipos AdvPL (C, M, N, L, D, F, A, B, U, O) e tipos TLPP (`numeric`, `integer`, `double`, `decimal`, `character`, `logical`, `date`, `array`, `object`, `json`, `codeblock`, `variant`, `variadic`) com sintaxe de declaração e principais diferenças entre as linguagens.
- **Catálogo de Skills** — Índice das skills disponíveis em [`../skills/advpl-tlpp/`](../skills/advpl-tlpp/) para geração de código, migração, revisão, testes, documentação e planejamento.

---

## Como Usar

Copie ou referencie o arquivo apropriado para a raiz do seu workspace Protheus de acordo com o agente utilizado:

- **GitHub Copilot / Codex / Cursor / outros agentes com padrão `AGENTS.md`** → usar [AGENTS.md](AGENTS.md)
- **Claude Code** → usar [CLAUDE.md](CLAUDE.md)

Os agentes carregam automaticamente esses arquivos como contexto inicial ao iniciar uma sessão, garantindo aderência às convenções TOTVS desde a primeira interação.

---

## Manutenção

Ao alterar regras de codificação, type system ou estrutura de projeto:

1. Edite **ambos** os arquivos (`AGENTS.md` e `CLAUDE.md`) para mantê-los em sincronia.
2. Verifique a equivalência com `diff instructions/AGENTS.md instructions/CLAUDE.md` — o comando deve retornar vazio.
3. Atualize as referências ao catálogo de skills em [`../skills/advpl-tlpp/references/advpl-tlpp-skills-reference.md`](../skills/advpl-tlpp/references/advpl-tlpp-skills-reference.md) quando novas skills forem adicionadas.
