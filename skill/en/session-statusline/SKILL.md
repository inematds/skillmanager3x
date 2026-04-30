---
name: session-statusline
description: Use during active work for a quick operational checkpoint. Triggers include "statusline", "checkpoint", "where are we", "session status", "next steps", "organize session", "optimize session", "clean session", "session health". Produces a compact snapshot of current focus, what was saved, recent decisions, next actions, and context health. Not for end-of-session — use session-handoff for that.
---

# Session Statusline

Quick operational checkpoint during active work. Helps the user see current state and decide whether to continue, compact, audit memory, or hand off.

This is a **diagnostic snapshot**, not an end-of-session artifact. Use `session-handoff` when the user is wrapping up. Use `memory-audit` for deep memory inventory.

## When to invoke

User says any of: "statusline", "checkpoint", "where are we", "session status", "next steps", "organize session", "optimize session", "clean session", "session health", "summarize current context".

Do NOT invoke for explicit end-of-session signals ("about to /clear", "handoff", "wrap up") — those go to `session-handoff`. Do NOT invoke for "audit CLAUDE.md" / "memory bloated" — those go to `memory-audit`.

## How to produce the statusline

- Review the full conversation, not just the last few turns.
- Never invent state. If something is unknown, write "unknown" or "none".
- Distinguish:
  - **Saved (confirmed)** — the assistant actually wrote to memory or files this session.
  - **Memory candidates** — durable facts/decisions worth saving but not yet saved.
  - **Do not save** — temporary details, noise.
- Prefer terse, concrete output over narrative.
- If you cannot confirm something was saved (e.g., memory writes), say "candidate" — do not claim it as saved.

## Output template

```
# Statusline

## State
- Current focus: <one line>
- Context: <lean | moderate | noisy | overloaded>
- Main risk: <none or one line>

## What was saved to memory
- Saved (confirmed): <items actually written this session, or "none">
- Memory candidates: <durable facts/decisions/preferences worth saving>
- Do not save: <temporary details/noise>

## Recent history
- Done now: <1-3 bullets>
- Recent decisions: <1-3 bullets>
- Relevant files/areas: <paths/names if known, or "none">

## Next steps
1. <single best next action>
2. <optional next action>
3. <optional next action>

## Recommendation
<continue | compact | audit memory | hand off | clear session>
```

## Rules

1. **Chat output only.** Do not write files. Do not update memory.
2. **No quota fabrication.** Claude Code does not expose quota usage to the model. Do not include "daily quota" or "weekly quota" lines — they would always be guesses. If the user wants quota tracking, that belongs in the Claude Code statusline config (`update-config` skill), not here.
3. **Distinguish confirmed vs. candidate memory.** Never claim something was saved unless you actually saved it this session.
4. **No emojis, no hype.** Terse and operational.
5. **Keep it compact.** This is a quick checkpoint, not a deep audit. For deep memory analysis, the user should invoke `memory-audit`. For end-of-session, `session-handoff`.
