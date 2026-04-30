---
name: session-statusline
description: Use during active work for a quick operational checkpoint. Triggers include "statusline", "checkpoint", "onde estamos", "resume contexto", "organiza a sessão", "otimiza a sessão", "limpa a sessão", "próximos passos", "como está a sessão". Produces a compact snapshot of current focus, what was saved, recent decisions, next actions, and context health. Not for end-of-session — use session-handoff for that.
---

# Session Statusline

Quick operational checkpoint during active work. Helps the user see current state and decide whether to continue, compact, audit memory, or hand off.

This is a **diagnostic snapshot**, not an end-of-session artifact. Use `session-handoff` when the user is wrapping up. Use `memory-audit` for deep memory inventory.

## When to invoke

User says any of: "statusline", "checkpoint", "onde estamos", "resume contexto", "organiza a sessão", "otimiza a sessão", "limpa a sessão", "próximos passos", "como está a sessão".

Do NOT invoke for explicit end-of-session signals ("vou dar /clear", "handoff", "wrap up") — those go to `session-handoff`. Do NOT invoke for "analise CLAUDE.md" / "memória inchada" — those go to `memory-audit`.

## How to produce the statusline

- Review the full conversation, not just the last few turns.
- Never invent state. If something is unknown, write "unknown" or "none".
- Distinguish:
  - **Guardado confirmado** — the assistant actually wrote to memory or files this session.
  - **Candidatos para memória** — durable facts/decisions worth saving but not yet saved.
  - **Não guardar** — temporary details, noise.
- Prefer terse, concrete output over narrative.
- If you cannot confirm something was saved (e.g., memory writes), say "candidate" — do not claim it as saved.

## Output template

```
# Statusline

## Estado
- Foco atual: <one line>
- Contexto: <enxuto | moderado | ruidoso | sobrecarregado>
- Risco principal: <none or one line>

## O que ficou guardado na memória
- Guardado confirmado: <items actually written this session, or "none">
- Candidatos para memória: <durable facts/decisions/preferences worth saving>
- Não guardar: <temporary details/noise>

## Histórico curto
- Feito agora: <1-3 bullets>
- Decisões recentes: <1-3 bullets>
- Arquivos/áreas relevantes: <paths/names if known, or "none">

## Próximos passos
1. <single best next action>
2. <optional next action>
3. <optional next action>

## Recomendação
<continuar | compactar | auditar memória | fazer handoff | limpar sessão>
```

## Rules

1. **Chat output only.** Do not write files. Do not update memory.
2. **No quota fabrication.** Claude Code does not expose quota usage to the model. Do not include "daily quota" or "weekly quota" lines — they would always be guesses. If the user wants quota tracking, that belongs in the Claude Code statusline config (`update-config` skill), not here.
3. **Distinguish confirmed vs. candidate memory.** Never claim something was saved unless you actually saved it this session.
4. **No emojis, no hype.** Terse and operational.
5. **Keep it compact.** This is a quick checkpoint, not a deep audit. For deep memory analysis, the user should invoke `memory-audit`. For end-of-session, `session-handoff`.
