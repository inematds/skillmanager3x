# Session-management skills

Three separate skills, each with one clear job and disjoint triggers. They replace the
old monolithic `session-handoff` and the combined `session-memory-manager` package.

## Layout

```
skill\
├── session-handoff\SKILL.md       end-of-session (before /clear or agent swap)
├── session-statusline\SKILL.md    operational checkpoint during active work
└── memory-audit\SKILL.md          deep audit of memory / CLAUDE.md
```

## When to use which

| Skill | When | Typical triggers |
|---|---|---|
| `session-handoff` | clearing context or swapping agents | "handoff", "wrap up", "vou dar /clear", "encerrar sessão", "passar para outro agente", "summarize before clear" |
| `session-statusline` | quick diagnostic during work | "statusline", "checkpoint", "onde estamos", "organiza a sessão", "otimiza a sessão", "limpa a sessão", "próximos passos" |
| `memory-audit` | reviewing what is / should be in memory | "analise a memória", "analise CLAUDE.md", "o que foi guardado", "contexto grande", "memória inchada", "limpa memória" |

Rule of thumb: **end of session → handoff. "Where are we now?" → statusline. "What's in memory?" → audit.**

## What changed in `session-handoff` vs the original version

### Triggers (description)
- **Removed:** "otimiza a sessão", "organiza a sessão", "limpa a sessão" — moved to `session-statusline`.
- **Added:** "vou dar /clear", "encerrar sessão", "passar para outro agente", "resumo final antes de limpar".
- **New:** explicit "Do NOT invoke for X" block making the boundary with the other two skills clear.

### `/clear` behavior
- Clear intent ("vou dar /clear", "vou limpar agora") → run handoff directly.
- Vague intent ("talvez eu limpe") → ask once before running.

The old rule was generic ("invoke proactively if user says they're about to /clear"); the new rule distinguishes clear vs vague, avoiding unnecessary friction.

### Long conversations
- New rule: for >50 turns, focus on **inflection points** (direction changes, reverted decisions, current state) instead of chronological narration.

### Confidence markers
New section. Instead of just "none" or confident assertion, prefix uncertain items:

- `[confirmed]` — fact verified this session
- `[unverified]` — likely but not confirmed
- `[?]` — uncertain, requires verification

### Output template
The `Decisions locked + what shipped` section was **split in two**:

- `## Applied / shipped` — what was actually applied
- `## Proposed / attempted but not confirmed` — proposed or partial, with reason

This prevents the next agent from treating a proposal as a fact.

`Pick up here` changed from "1-2 sentences" to "1-3 lines" with explicit branching when applicable (e.g., "A if test passes, B if it fails").

### Sources to pull from
- "TodoWrite state" → "Task list state" (TodoWrite was renamed to the current task system).
- Added: "Don't include exploration noise" — failed greps, discarded attempts, context the next agent reconstructs by reading the listed files.

### Structure
- Hard rules + Anti-patterns **merged** into a single list (`## Rules`). The old version had overlap between the two sections.

### Paths
- `C:\Users\nateh\...` → `C:\Users\neima\...` (residue from the original skill, now fixed).

### Cosmetic
- Removed broken markdown escapes from the original (`\---`, `run\_in\_background`, `\~/.claude`, doubled `\\` in paths).

## What was NOT included (and why)

- **Daily/weekly quota** (was in `session-memory-manager`): Claude Code doesn't expose quota usage to the model. Lines like "Daily 5h: ok | warning | critical" can only ever be `unknown`. To track quota, use Claude Code's own statusline (`update-config` skill), not a session-management skill.
- **A 4th skill `ai-session-discipline`** (proposed in one iteration): a skill that never fires is just markdown with frontmatter inflating the registry. General philosophy goes in the project's `CLAUDE.md`, not a skill.
- **Parameterized path `<user>`**: these skills are personal and local. Hardcoding `neima` is more useful — the agent uses it directly without variable substitution.

## Usage tips

### To make handoff work well
1. **Be explicit** when wrapping up: "vou dar /clear" or "faz handoff" — avoids wrong dispatch.
2. **Mention the plan** if there is one: "let's hand off plan X" — the skill prioritizes listing the plan first under "Key files".
3. **Check shell IDs** in the output: if you started background processes, they must appear under "Running state" with the kill command — without this, the next agent can't manage them.
4. **Saves to a file** (since Oct/2026) — besides the chat, it writes `handoffs/history/<UTC>.md` + `handoffs/latest.md`. In the new session, after `/clear`, run `/prime` to resume. The old version was chat-only.

### To make statusline work well
1. Use it **during** work, not at the end. If you've already decided to wrap up, go straight to handoff.
2. The "Recomendação" line at the bottom points to the next move (continue / compact / audit / handoff / clear) — use it to decide, don't ignore it.
3. If you see lots of "candidato para memória" and little "guardado confirmado", consider running `memory-audit` next.

### To make memory-audit work well
1. **Point at the file** if specific: "audit my CLAUDE.md at <path>" — without an explicit path it only audits what's visible in the conversation.
2. Output is recommendation, not execution. If you want it to apply the cuts ("save this", "remove that"), ask explicitly as a second step.
3. Use periodically, not every session. Audit is for reviewing accumulation — running it constantly is the noise it's trying to prevent.

## Installation

For the Claude Code harness to recognize the skills, they need to live in one of the recognized folders:

- **Global (all sessions):** `C:\Users\neima\.claude\skills\`
- **Per project:** `<project>\.claude\skills\`

Copy the four folders (`session-handoff`, `prime`, `session-statusline`, `memory-audit`) to the chosen destination. Each folder with its `SKILL.md` inside — don't flatten.

To verify they were registered, use `/skills` in Claude Code (or check the registry at the start of the conversation).
