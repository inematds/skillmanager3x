# skillmanager3x

[![skillmanager3x — session skills](guia/assets/banner-en.jpg)](https://inematds.github.io/skillmanager3x/guia/en/)

**🇧🇷 [Português](README.md) · 🇺🇸 [English](README.en.md) · 🇪🇸 [Español](README.es.md)**

## What it is

skillmanager3x is a set of skills (ready-made instructions in text files) for people who use Claude Code in long sessions. They solve the problem of losing the thread when the conversation fills up: `session-handoff` saves the state to a file, you clear with `/clear`, and `prime` picks up by reading that file. There is also a quick checkpoint, a memory audit, and a status bar. To use them, just copy the folders to `~/.claude/skills`.

A library of **session-management skills** for [Claude Code](https://claude.ai/code). Small, disjoint templates that help keep context, memory, and transitions between sessions under control.

## 📖 User guide

Full guide (landing + step by step): **https://inematds.github.io/skillmanager3x/guia/en/**

## ⭐ Switching sessions: handoff → `/clear` → `/prime`

When the context fills up or the session has already compacted, don't insist on the same conversation:

1. **`/session-handoff`** records what was done, what is in progress, the exact next action, and what depends on you in `handoffs/history/<UTC>.md` (never overwrites) and updates `handoffs/latest.md`.
2. **`/clear`** wipes the conversation (in Codex, open a new session). Nothing is lost: the state is in the file.
3. **`/prime`** reads `CLAUDE.md`/`AGENTS.md`, `context/`, `tasks/current.md`, and `handoffs/latest.md` and returns a short briefing. It only reads; it does not resume deploys, publishing, or sending on its own.

> **There are two `session-handoff` versions.** The old version of this repository (and the one circulating in other kits) only showed the summary in the chat: when you ran `/clear` it vanished and `/prime` had nothing to read. The current version, in `skill/pt` and `skill/en`, is the same as in the [agente-claude-codex](https://github.com/inematds/agente-claude-codex) kit 1.5.2 and **writes to a file** through the `scripts/handoff-grava.py` script (machine-clock timestamp, commits only the handoff, no push). Since 1.4.1, `handoffs/latest.md` is an **index of open work by subject** + a copy of the newest, and `prime` lists every open item; it is the same format the Long Execution hook reads. To check yours: `grep -c "handoffs/history" ~/.claude/skills/session-handoff/SKILL.md` (0 = chat-only version). Since 1.5.2 the handoff carries a **state block written by the script** (commit + sha256 of the files; `handoff-grava.py --conferir` tells whether the handoff went stale), evidence on every `[confirmed]` and **5 test questions** that `prime` answers from the files and scores (N/5).

For work lasting hours or days, see **[Long Execution](https://inematds.github.io/execucao-longa/guia/en/)** ([repo](https://github.com/inematds/execucao-longa)): the hook that writes the handoff on its own at ~70% and ~85% of the context and after compaction, the state files, `/goal`, and the research behind the context bands.

There is no build, no dependencies, and no executable code: each skill is a folder with a `SKILL.md` (markdown + YAML frontmatter) that Claude Code loads when the user says one of the triggers.

## Structure

```
skill/
├── en/                  English versions  (+ detailed README)
│   ├── session-handoff/SKILL.md  (+ scripts/handoff-grava.py)
│   ├── prime/SKILL.md
│   ├── session-statusline/SKILL.md
│   └── memory-audit/SKILL.md
└── pt/                  Portuguese versions (+ detailed README)
    ├── session-handoff/SKILL.md  (+ scripts/handoff-grava.py)
    ├── prime/SKILL.md
    ├── session-statusline/SKILL.md
    └── memory-audit/SKILL.md

statusline-cmd/          terminal status bar (bash, optional)
├── statusline-command.sh
├── install.sh
└── README.md
```

The READMEs in `skill/en/` and `skill/pt/` cover design decisions, changes vs. earlier versions, and advanced tips. This root README is the front door.

## The skills

Each one has **a single job** and triggers that do not overlap. Use the table below to choose:

| Skill | When to use | Typical triggers |
|---|---|---|
| `session-handoff` | end of session, before `/clear` or switching agents | "handoff", "vou dar /clear", "encerrar sessão", "passar para outro agente", "wrap up", "resumo final antes de limpar" |
| `prime` | start of the new session, after `/clear` | "prime", "retoma", "continua de onde parou", "lê o handoff" |
| `session-statusline` | quick checkpoint **during** the work | "statusline", "checkpoint", "onde estamos", "como está a sessão", "próximos passos", "organiza/otimiza a sessão" |
| `memory-audit` | review what is/should be in memory | "analise a memória", "analise CLAUDE.md", "o que foi guardado", "memória inchada", "limpa memória" |

Rule of thumb: **end of session → handoff. New session → prime. "How are we doing?" → statusline. "What's in memory?" → audit.**

---

### 1. `session-handoff` — pass the baton before clearing context

Produces a structured summary of the session so a future agent can pick up where you left off — terse, with paths, background process IDs, real verification, and confidence markers (`[confirmed]`, `[unverified]`, `[?]`). Shows it in the chat **and saves it** to `handoffs/history/<UTC>.md` + `handoffs/latest.md` when the project root has `handoffs/`, `AGENTS.md`, or `CLAUDE.md`.

**When to invoke:**
- Before `/clear`.
- Before switching agents (e.g. handing work to a subagent in another window).
- When the conversation reaches >50 turns and you want to restart lean.

**Usage example:**

```
User: I'm going to /clear, do a handoff first
```

Claude shows it in the chat and saves it to `handoffs/history/2026-10-13T014500Z.md` (and copies it to `handoffs/latest.md`), in this format:

```
# Handoff — 2026-10-13 — auth middleware refactor

## Project and scope
~/projetos/api. Extract JWT validation from the monolithic middleware, keeping v1 tokens.

## Accepted state
- [confirmed] auth/jwt_validator.py extracted from middleware.py:45-180

## Proposed / attempted, not confirmed
- [unverified] public key cache with 5min TTL — code ready, untested
- [?] v1→v2 migration — user wanted to review before merging

## Verification
- Run: `pytest tests/auth/ -v` → 12 passed
- Not run: load test — no environment

## Running state
- Background processes: shell_a3f → pytest --watch (kill: KillShell shell_a3f)

## Exact next action
Review with the user whether the v1→v2 migration goes in now (needs their ok).

## Resume map
- `auth/jwt_validator.py` — core of the extraction

## Sharing check
- No secrets, tokens, or personal data: yes
```

**In the new session**, after `/clear`, run `/prime`: it reads `handoffs/latest.md` (and `CLAUDE.md`/`AGENTS.md`, `context/`, `tasks/current.md`) and returns the goal, the main rule with its source, the last decision, the next action, and conflicts.

---

### 2. `session-statusline` — quick checkpoint during the work

Short operational snapshot: current focus, context, recent decisions, memory candidates, and the next move (continue, compact, audit, hand off, or clear). Use it when you want to see the state without ending the session.

**When to invoke:**
- The session started to feel noisy and you want a bearing.
- A phase of the work just ended and you want to decide whether to continue or change tactics.
- You want to know what Claude has already saved to memory **in this session**.

**Usage example:**

```
User: statusline
```

Claude replies:

```
# Statusline

## State
- Current focus: adjust pagination on the /users endpoint
- Context: moderate
- Main risk: we haven't run a load test with >10k records yet

## What was saved to memory
- Confirmed saved: none
- Memory candidates: user prefers keyset pagination over offset (decision from this session)
- Do not save: failed greps at the start, discarded attempt with base64 cursor

## Short history
- Done now: implemented keyset in users_repo.py, adjusted response schema
- Recent decisions: dropped offset due to instability with concurrent inserts
- Relevant files: /api/users.py, /repo/users_repo.py

## Next steps
1. Run a test with 50k records and measure latency
2. Update the OpenAPI schema
3. Decide whether the keyset preference is worth saving to memory

## Recommendation
continue
```

The **Recommendation** line at the end tells you which skill (if any) makes sense next.

---

### 3. `memory-audit` — review what is in memory

Audit of what is (or should be) in `~/.claude/projects/<project>/memory/` and in the project's `CLAUDE.md`. It distinguishes **durable fact** (keep), **short-term state** (discard), and **noise** (remove).

**When to invoke:**
- Memory looks bloated or contradictory.
- You are about to start a new project and want to trim first.
- A big session just ended and you want to review what got recorded.

**Usage example:**

```
User: audit the project memory, it's a mess
```

Claude replies with an inventory like:

```
# Memory Audit

## Keep (durable facts)
- user_role.md → user is a Go backend engineer, new to React
- feedback_testing.md → integration tests must hit the real Postgres (Q3/2025 incident)

## Consider moving to CLAUDE.md
- project_auth_rewrite.md → motivation context (compliance) — belongs in the project docs

## Remove (short-term / noise)
- session_2026-04-15.md → old session state, irrelevant
- bug_fix_recipe_xyz.md → fix already applied, the code speaks for itself

## Points of attention
- Duplication: feedback_pr_size.md and feedback_review_style.md cover a similar topic
- Stale: reference_grafana.md points to a dashboard whose URL changed
```

The output is a **recommendation, not execution**. If you want Claude to apply the cuts, ask in a second step: "ok, apply that".

---

## Installation

For Claude Code to recognize the skills, copy each skill's folder into one of the folders the harness scans:

- **Global (all sessions):** `~/.claude/skills/<skill>/`
- **Per project:** `<project>/.claude/skills/<skill>/`

Example (global install of the English skills):

```bash
mkdir -p ~/.claude/skills
cp -r skill/en/session-handoff   ~/.claude/skills/
cp -r skill/en/prime             ~/.claude/skills/
cp -r skill/en/session-statusline ~/.claude/skills/
cp -r skill/en/memory-audit       ~/.claude/skills/
```

> Each folder goes in whole, with the `SKILL.md` inside — don't flatten.

To verify it registered, use `/skills` in Claude Code.

## Bonus: `statusline-cmd` — the terminal status bar

Besides the skills, the repo ships a **statusline** for Claude Code: the fixed line that appears below the input, showing where you are, with which model, how much context is left, and how much of your limit is already used.

```
nmaldaner@spark-922b:~/projetos/wifi Opus 5/low ctx 10% 5h:24%→00:10 w:29%→10/08 21:00 d:109.6M
```

| Field | Meaning |
|---|---|
| `user@host:cwd` | user, machine, and current directory |
| `Opus 5/low` | model and effort level of the session (follows `/model`) |
| `ctx 10%` | how much of the context window has been used |
| `5h:24%→00:10` | 5-hour limit used and reset time |
| `w:29%→10/08 21:00` | weekly limit used and reset |
| `d:109.6M` | tokens summed today, across all local sessions |

**The command:**

```bash
git clone https://github.com/inematds/skillmanager3x
bash skillmanager3x/statusline-cmd/install.sh
```

The installer copies the script to `~/.claude/statusline-command.sh`, registers the `statusLine` block in `~/.claude/settings.json` **preserving the rest of the file** (with a `.bak` backup), and shows a preview. The bar appears on the next render — no need to restart the session.

Remove: `bash statusline-cmd/install.sh --uninstall`.

Requirements: `jq`, `curl`, `python3`, and GNU `date`. The 5h/weekly limits come from the `api/oauth/usage` endpoint using **your own credentials** (`~/.claude/.credentials.json`) — no token goes in the repo. Details and customization in [`statusline-cmd/README.md`](statusline-cmd/README.md) (in Portuguese).

> The `session-statusline` skill and the `statusline-cmd` folder have similar names and different purposes: the skill writes a **text checkpoint** when you ask; the folder installs the terminal's **fixed bar**.

## en/pt convention

`skill/en/` and `skill/pt/` have the same structure. The `name` is the same in both; the `description` **includes Portuguese triggers** where applicable (`"vou dar /clear"`, `"encerrar sessão"`, `"retoma"`, etc.). `session-handoff` and `prime` in `skill/pt/` are an exact copy of the versions in the [agente-claude-codex](https://github.com/inematds/agente-claude-codex) kit 1.5.2; those in `skill/en/` are the faithful translation.

When editing a skill, keep both versions in sync.
