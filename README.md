# skillmanager3x

Biblioteca de **skills de gestão de sessão** para o [Claude Code](https://claude.ai/code). Três templates pequenos e disjuntos que ajudam a manter contexto, memória e transições entre sessões sob controle.

## 📖 Guia de uso

Guia completo (landing + passo a passo): **https://inematds.github.io/skillmanager3x/guia/**

Não há build, dependências nem código executável: cada skill é uma pasta com um `SKILL.md` (markdown + frontmatter YAML) que o Claude Code carrega quando o usuário fala um dos gatilhos.

## Estrutura

```
skill/
├── en/                  versões em inglês  (+ README detalhado)
│   ├── session-handoff/SKILL.md
│   ├── session-statusline/SKILL.md
│   └── memory-audit/SKILL.md
└── pt/                  versões em português (+ README detalhado)
    ├── session-handoff/SKILL.md
    ├── session-statusline/SKILL.md
    └── memory-audit/SKILL.md

statusline-cmd/          barra de status do terminal (bash, opcional)
├── statusline-command.sh
├── install.sh
└── README.md
```

Os READMEs em `skill/en/` e `skill/pt/` cobrem decisões de design, mudanças vs. versões anteriores e dicas avançadas. Este README do raiz é a porta de entrada.

## As três skills

Cada uma tem **um trabalho só** e gatilhos que não se sobrepõem. Use a tabela abaixo pra escolher:

| Skill | Quando usar | Gatilhos típicos |
|---|---|---|
| `session-handoff` | fim de sessão, antes de `/clear` ou troca de agente | "handoff", "vou dar /clear", "encerrar sessão", "passar para outro agente", "wrap up", "resumo final antes de limpar" |
| `session-statusline` | checkpoint rápido **durante** o trabalho | "statusline", "checkpoint", "onde estamos", "como está a sessão", "próximos passos", "organiza/otimiza a sessão" |
| `memory-audit` | revisar o que está/deveria estar em memória | "analise a memória", "analise CLAUDE.md", "o que foi guardado", "memória inchada", "limpa memória" |

Regra de bolso: **fim de sessão → handoff. "Como estamos?" → statusline. "O que tem na memória?" → audit.**

---

### 1. `session-handoff` — passar o bastão antes de limpar contexto

Produz um resumo estruturado da sessão para um agente futuro pegar de onde você parou. Pensado para ser lido **só por outra instância do Claude**, não por humano — terso, com paths absolutos, IDs de processos em background, e marcadores de confiança (`[confirmed]`, `[unverified]`, `[?]`).

**Quando invocar:**
- Antes de `/clear`.
- Antes de trocar de agente (ex: passar trabalho para um subagente em outra janela).
- Quando a conversa atinge >50 turns e você quer recomeçar enxuto.

**Exemplo de uso:**

```
Usuário: vou dar /clear, faz handoff antes
```

O Claude responde com algo no formato:

```
# Session Handoff — refatoração do middleware de auth

## Where it started
Usuário pediu pra extrair lógica de validação de JWT do middleware monolítico.
Decidimos manter compatibilidade com tokens v1 enquanto v2 não vira default.

## Applied / shipped
- [confirmed] /auth/jwt_validator.py extraído de middleware.py:45-180
- [confirmed] testes em /tests/auth/test_jwt_validator.py — 12/12 passando

## Proposed / attempted but not confirmed
- [unverified] cache de chaves públicas com TTL de 5min — código pronto, sem teste
- [?] migração v1→v2 — usuário queria revisar antes de mergear

## Key files for next session
- /auth/jwt_validator.py — núcleo da extração
- Plan file: ~/.claude/plans/auth-refactor.md

## Running state
- Background processes: shell_a3f → pytest --watch (kill: KillShell shell_a3f)
- Dev servers: none

## Verification
- pytest tests/auth/ -v → todos verdes
- curl localhost:8000/health → 200

## Pick up here
Revisar com usuário se a migração v1→v2 entra agora ou fica pra próxima.
```

**Saída é só chat** — o handoff nunca grava arquivo. Se quiser persistir, copie o texto manualmente.

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

Exemplo (instalação global das três skills em português):

```bash
mkdir -p ~/.claude/skills
cp -r skill/pt/session-handoff   ~/.claude/skills/
cp -r skill/pt/session-statusline ~/.claude/skills/
cp -r skill/pt/memory-audit       ~/.claude/skills/
```

> Cada pasta vai inteira, com o `SKILL.md` dentro — não achate.

Para verificar que registrou, use `/skills` no Claude Code.

## Bônus: `statusline-cmd` — a barra de status do terminal

Além das skills, o repo traz uma **statusline** para o Claude Code: a linha fixa que aparece abaixo do input, mostrando onde você está, com qual modelo, quanto de contexto sobrou e quanto do seu limite já foi.

```
nmaldaner@spark-922b:~/projetos/wifi Opus 5/low ctx 10% 5h:24%→00:10 w:29%→10/08 21:00 d:109.6M
```

| Campo | Significado |
|---|---|
| `user@host:cwd` | usuário, máquina e diretório atual |
| `Opus 5/low` | modelo e nível de esforço da sessão (acompanha o `/model`) |
| `ctx 10%` | quanto da janela de contexto já foi usado |
| `5h:24%→00:10` | limite de 5 horas usado e hora do reset |
| `w:29%→10/08 21:00` | limite semanal usado e reset |
| `d:109.6M` | tokens somados hoje, em todas as sessões locais |

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

`skill/en/` e `skill/pt/` têm a mesma estrutura. Os campos `name` e `description` do frontmatter ficam em inglês nas duas (pra triggering consistente do harness), mas a `description` **inclui gatilhos em português** quando aplicável (`"vou dar /clear"`, `"encerrar sessão"`, etc.).

Ao editar uma skill, sincronize as duas versões.
