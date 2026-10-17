# skillmanager3x

[![skillmanager3x — skills de sessão](guia/assets/banner.jpg)](https://inematds.github.io/skillmanager3x/guia/)

**🇧🇷 [Português](README.md) · 🇺🇸 [English](README.en.md) · 🇪🇸 [Español](README.es.md)**

## O que é

O skillmanager3x é um conjunto de skills (instruções prontas em arquivos de texto) para quem usa o Claude Code e trabalha em sessões longas. Elas resolvem o problema de perder o fio quando a conversa enche: o `session-handoff` grava o estado num arquivo, você limpa com `/clear` e o `prime` retoma lendo esse arquivo. Há ainda um checkpoint rápido, uma auditoria da memória e uma barra de status. Para usar, basta copiar as pastas para `~/.claude/skills`.

Biblioteca de **skills de gestão de sessão** para o [Claude Code](https://claude.ai/code). Templates pequenos e disjuntos que ajudam a manter contexto, memória e transições entre sessões sob controle.

## 📖 Guia de uso

Guia completo (landing + passo a passo): **https://inematds.github.io/skillmanager3x/guia/**

## ⭐ Troca de sessão: handoff → `/clear` → `/prime`

Quando o contexto enche ou a sessão já compactou, não insista na mesma conversa:

1. **`/session-handoff`** grava o que foi feito, o que está em andamento, a próxima ação exata e o que depende de você em `handoffs/history/<UTC>.md` (nunca sobrescreve) e atualiza `handoffs/latest.md`.
2. **`/clear`** zera a conversa (no Codex, abra uma sessão nova). Nada se perde: o estado está no arquivo.
3. **`/prime`** lê `CLAUDE.md`/`AGENTS.md`, `context/`, `tasks/current.md` e `handoffs/latest.md` e devolve um briefing curto. Só lê; não retoma deploy, publicação ou envio sozinho.

> **Existem duas `session-handoff`.** A versão antiga deste repositório (e a que circula em outros kits) só mostrava o resumo no chat: ao dar `/clear` ele sumia e o `/prime` não tinha o que ler. A versão atual, em `skill/pt` e `skill/en`, é a mesma do kit [agente-claude-codex](https://github.com/inematds/agente-claude-codex) 1.5.2 e **grava em arquivo** pelo script `scripts/handoff-grava.py` (carimbo do relógio da máquina, commit só do handoff, sem push). Desde a 1.4.1 o `handoffs/latest.md` é um **índice de trabalhos abertos por assunto** + cópia do mais novo, e o `prime` lista todos os abertos; é o mesmo formato que o hook do Execução Longa lê. Para conferir a sua: `grep -c "handoffs/history" ~/.claude/skills/session-handoff/SKILL.md` (0 = versão só chat). Desde a 1.5.2 o handoff traz um **bloco de estado gravado pelo script** (commit + sha256 dos arquivos; `handoff-grava.py --conferir` diz se o handoff ficou velho), evidência em cada `[confirmed]` e **5 perguntas-teste** que o `prime` responde pelos arquivos e pontua (N/5).

Para trabalho de horas ou dias, veja o **[Execução Longa](https://inematds.github.io/execucao-longa/guia/)** ([repo](https://github.com/inematds/execucao-longa)): o hook que grava o handoff sozinho em ~70% e ~85% do contexto e depois de compactar, os arquivos de estado, o `/goal` e a pesquisa por trás das faixas de contexto.

Não há build, dependências nem código executável: cada skill é uma pasta com um `SKILL.md` (markdown + frontmatter YAML) que o Claude Code carrega quando o usuário fala um dos gatilhos.

## Estrutura

```
skill/
├── en/                  versões em inglês  (+ README detalhado)
│   ├── session-handoff/SKILL.md  (+ scripts/handoff-grava.py)
│   ├── prime/SKILL.md
│   ├── session-statusline/SKILL.md
│   └── memory-audit/SKILL.md
└── pt/                  versões em português (+ README detalhado)
    ├── session-handoff/SKILL.md  (+ scripts/handoff-grava.py)
    ├── prime/SKILL.md
    ├── session-statusline/SKILL.md
    └── memory-audit/SKILL.md

statusline-cmd/          barra de status do terminal (bash, opcional)
├── statusline-command.sh   barra (com "→ projeto ativo")
├── install.sh
├── cc-projeto.sh           função `cc <projeto>`: entra na pasta e abre o Claude
├── cc.sh  cc.bat           lançador do Claude Code (Linux / Windows)
├── cx.sh  cx.bat           lançador do Codex CLI (Linux / Windows)
└── README.md
```

Os READMEs em `skill/en/` e `skill/pt/` cobrem decisões de design, mudanças vs. versões anteriores e dicas avançadas. Este README do raiz é a porta de entrada.

## As skills

Cada uma tem **um trabalho só** e gatilhos que não se sobrepõem. Use a tabela abaixo pra escolher:

| Skill | Quando usar | Gatilhos típicos |
|---|---|---|
| `session-handoff` | fim de sessão, antes de `/clear` ou troca de agente | "handoff", "vou dar /clear", "encerrar sessão", "passar para outro agente", "wrap up", "resumo final antes de limpar" |
| `prime` | início da sessão nova, depois do `/clear` | "prime", "retoma", "continua de onde parou", "lê o handoff" |
| `session-statusline` | checkpoint rápido **durante** o trabalho | "statusline", "checkpoint", "onde estamos", "como está a sessão", "próximos passos", "organiza/otimiza a sessão" |
| `memory-audit` | revisar o que está/deveria estar em memória | "analise a memória", "analise CLAUDE.md", "o que foi guardado", "memória inchada", "limpa memória" |

Regra de bolso: **fim de sessão → handoff. Sessão nova → prime. "Como estamos?" → statusline. "O que tem na memória?" → audit.**

---

### 1. `session-handoff` — passar o bastão antes de limpar contexto

Produz um resumo estruturado da sessão para um agente futuro pegar de onde você parou — terso, com caminhos, IDs de processos em background, verificação real e marcadores de confiança (`[confirmed]`, `[unverified]`, `[?]`). Mostra no chat **e grava** em `handoffs/history/<UTC>.md` + `handoffs/latest.md` quando a raiz do projeto tem `handoffs/`, `AGENTS.md` ou `CLAUDE.md`.

**Quando invocar:**
- Antes de `/clear`.
- Antes de trocar de agente (ex: passar trabalho para um subagente em outra janela).
- Quando a conversa atinge >50 turns e você quer recomeçar enxuto.

**Exemplo de uso:**

```
Usuário: vou dar /clear, faz handoff antes
```

O Claude mostra no chat e grava em `handoffs/history/2026-10-13T014500Z.md` (e copia para `handoffs/latest.md`), no formato:

```
# Handoff — 2026-10-13 — refatoração do middleware de auth

## Projeto e escopo
~/projetos/api. Extrair a validação de JWT do middleware monolítico, mantendo tokens v1.

## Estado aceito
- [confirmed] auth/jwt_validator.py extraído de middleware.py:45-180

## Proposto / tentado, não confirmado
- [unverified] cache de chaves públicas com TTL de 5min — código pronto, sem teste
- [?] migração v1→v2 — usuário queria revisar antes de mergear

## Verificação
- Rodado: `pytest tests/auth/ -v` → 12 passed
- Não rodado: teste de carga — sem ambiente

## Estado em execução
- Processos em segundo plano: shell_a3f → pytest --watch (kill: KillShell shell_a3f)

## Próxima ação exata
Revisar com o usuário se a migração v1→v2 entra agora (precisa do ok dele).

## Mapa de retomada
- `auth/jwt_validator.py` — núcleo da extração

## Checagem de compartilhamento
- Sem segredos, tokens ou dados pessoais: sim
```

**Na sessão nova**, depois do `/clear`, rode `/prime`: ele lê `handoffs/latest.md` (e `CLAUDE.md`/`AGENTS.md`, `context/`, `tasks/current.md`) e devolve objetivo, regra principal com fonte, última decisão, próxima ação e conflitos.

---

### 2. `session-statusline` — checkpoint rápido durante o trabalho

Snapshot operacional curto: foco atual, contexto, decisões recentes, candidatos a memória e qual o próximo movimento (continuar, compactar, auditar, dar handoff ou limpar). Use quando quer ver o estado sem encerrar.

**Quando invocar:**
- Sessão começou a parecer ruidosa e você quer um norte.
- Acabou uma fase do trabalho e quer decidir se continua ou troca de tática.
- Quer saber o que o Claude já guardou na memória **nesta sessão**.

**Exemplo de uso:**

```
Usuário: statusline
```

O Claude responde:

```
# Statusline

## Estado
- Foco atual: ajustar paginação do endpoint /users
- Contexto: moderado
- Risco principal: ainda não rodamos teste de carga com >10k registros

## O que ficou guardado na memória
- Guardado confirmado: none
- Candidatos para memória: usuário prefere keyset pagination sobre offset (decisão dessa sessão)
- Não guardar: greps falhos no início, tentativa descartada com cursor base64

## Histórico curto
- Feito agora: implementado keyset em users_repo.py, ajustado schema da resposta
- Decisões recentes: descartado offset por instabilidade com inserts concorrentes
- Arquivos relevantes: /api/users.py, /repo/users_repo.py

## Próximos passos
1. Rodar teste com 50k registros e medir latência
2. Atualizar OpenAPI schema
3. Decidir se vale guardar a preferência por keyset na memória

## Recomendação
continuar
```

A linha **Recomendação** no fim te diz qual skill (ou nenhuma) faz sentido em seguida.

---

### 3. `memory-audit` — revisar o que está em memória

Auditoria do que está (ou deveria estar) em `~/.claude/projects/<projeto>/memory/` e no `CLAUDE.md` do projeto. Distingue **fato durável** (mantém), **estado de curto prazo** (descarta) e **ruído** (remove).

**Quando invocar:**
- Memória parece inchada ou contraditória.
- Vai começar projeto novo e quer enxugar antes.
- Saiu uma sessão grande e você quer revisar o que ficou registrado.

**Exemplo de uso:**

```
Usuário: analise a memória do projeto, tá bagunçada
```

O Claude responde com inventário tipo:

```
# Memory Audit

## Manter (fatos duráveis)
- user_role.md → user é eng. backend Go, novo em React
- feedback_testing.md → testes de integração devem bater no Postgres real (incidente Q3/2025)

## Considerar mover pro CLAUDE.md
- project_auth_rewrite.md → contexto de motivação (compliance) — vale na doc do projeto

## Remover (curto prazo / ruído)
- session_2026-04-15.md → estado de sessão antiga, irrelevante
- bug_fix_recipe_xyz.md → fix já aplicado, código fala por si

## Pontos de atenção
- Duplicação: feedback_pr_size.md e feedback_review_style.md cobrem tema parecido
- Stale: reference_grafana.md aponta pra dashboard que mudou de URL
```

A saída é **recomendação, não execução**. Se quiser que o Claude aplique os cortes, peça em uma segunda etapa: "ok, aplica isso".

---

## Instalação

Para o Claude Code reconhecer as skills, copie a pasta de cada skill para uma das pastas que o harness varre:

- **Global (todas as sessões):** `~/.claude/skills/<skill>/`
- **Por projeto:** `<projeto>/.claude/skills/<skill>/`

Exemplo (instalação global das skills em português):

```bash
mkdir -p ~/.claude/skills
cp -r skill/pt/session-handoff   ~/.claude/skills/
cp -r skill/pt/prime             ~/.claude/skills/
cp -r skill/pt/session-statusline ~/.claude/skills/
cp -r skill/pt/memory-audit       ~/.claude/skills/
```

> Cada pasta vai inteira, com o `SKILL.md` dentro — não achate.

Para verificar que registrou, use `/skills` no Claude Code.

## Bônus: `statusline-cmd` — a barra de status do terminal

Além das skills, o repo traz uma **statusline** para o Claude Code: a linha fixa que aparece abaixo do input, mostrando onde você está, com qual modelo, quanto de contexto sobrou e quanto do seu limite já foi.

```
nmaldaner@spark-922b:~/projetos/wifi → portal Opus 5.5/medium ctx 24% 5h:30%→03:59 w:62% F:1%→19/10 20:59 d:28.8M
```

| Campo | Significado |
|---|---|
| `user@host:cwd` | usuário, máquina e pasta onde a sessão foi aberta (fica fixa) |
| `→ portal` | **projeto ativo**: em amarelo quando o Claude está mexendo em outro projeto de `~/projetos` (sem gastar crédito) |
| `Opus 5.5/medium` | modelo e nível de esforço da sessão (acompanha o `/model`) |
| `ctx 24%` | quanto da janela de contexto já foi usado |
| `5h:30%→03:59` | limite de 5 horas usado e hora do reset |
| `w:62%` | limite semanal geral usado |
| `F:1%→19/10 20:59` | limite semanal **por modelo** (inicial do modelo) e reset |
| `d:28.8M` | tokens somados hoje, em todas as sessões locais |

Junto vêm a função **`cc <projeto>`** (entra na pasta do projeto e abre o Claude; aceita nome parcial) e os lançadores **`cc.sh`/`cc.bat`** (Claude Code) e **`cx.sh`/`cx.bat`** (Codex CLI) para Linux e Windows.

**O comando:**

```bash
git clone https://github.com/inematds/skillmanager3x
bash skillmanager3x/statusline-cmd/install.sh
```

O instalador copia o script para `~/.claude/statusline-command.sh`, registra o bloco `statusLine` no `~/.claude/settings.json` **preservando o resto do arquivo** (com backup `.bak`) e mostra uma prévia. A barra aparece no próximo render — não precisa reiniciar sessão.

Remover: `bash statusline-cmd/install.sh --uninstall`.

Requisitos: `jq`, `curl`, `python3` e o `date` do GNU. Os limites 5h/semanal vêm do endpoint `api/oauth/usage` usando **as suas próprias credenciais** (`~/.claude/.credentials.json`) — nada de token vai no repo. Detalhes e personalização em [`statusline-cmd/README.md`](statusline-cmd/README.md).

> A skill `session-statusline` e a pasta `statusline-cmd` têm nomes parecidos e propósitos diferentes: a skill escreve um **checkpoint em texto** quando você pede; a pasta instala a **barra fixa** do terminal.

## Convenção en/pt

`skill/en/` e `skill/pt/` têm a mesma estrutura. O `name` é igual nas duas; a `description` **inclui gatilhos em português** quando aplicável (`"vou dar /clear"`, `"encerrar sessão"`, `"retoma"`, etc.). `session-handoff` e `prime` em `skill/pt/` são cópia exata das versões do kit [agente-claude-codex](https://github.com/inematds/agente-claude-codex) 1.5.2; as de `skill/en/` são a tradução fiel.

Ao editar uma skill, sincronize as duas versões.
