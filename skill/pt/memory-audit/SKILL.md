---
name: memory-audit
description: Use to audit memory and context quality. Triggers include "analise a memória", "analise CLAUDE.md", "o que foi guardado", "contexto grande", "memória inchada", "o que remover", "limpa memória", "audit memory", "memory audit". Produces an inventory of what is in memory, what should stay durable, what is short-term context, and what is noise to remove.
---

# Memory Audit

Review what is stored or should be stored in memory: durable facts, short-term working state, `CLAUDE.md` content, and noise to discard.

This is a **memory quality review**, not an operational status (use `session-statusline`) and not an end-of-session handoff (use `session-handoff`).

## When to invoke

User says any of: "analise a memória", "analise CLAUDE.md", "o que foi guardado", "contexto grande", "memória inchada", "o que remover", "limpa memória", "audit memory", "memory audit".

Do NOT invoke for general status checks ("onde estamos", "checkpoint") — those go to `session-statusline`. Do NOT invoke for end-of-session ("handoff", "vou dar /clear") — those go to `session-handoff`.

## Core principle

Keep only information that changes future behavior. A good memory record is the smallest record that makes the next correct action happen.

Separate clearly:
- **Durable memory** — facts/preferences/decisions that influence future sessions.
- **Short memory** — current working state needed soon.
- **Handoff state** — operational details a fresh agent needs after `/clear`.
- **Noise** — details that should not be retained.

## How to audit

1. Review the full conversation.
2. Read `CLAUDE.md` and any memory files referenced (`C:\Users\neima\.claude\projects\<project>\memory\`) before recommending changes. If files are not accessible, state that the audit is based only on visible conversation context.
3. Distinguish what is **actually saved** from what is **candidate for saving**. Never claim something was saved unless the environment confirmed the write.
4. For each item, classify as: keep, compress, move, or delete.

## Output template

```
# Auditoria de Memória e Contexto

## Diagnóstico
- Estado do contexto: <enxuto | moderado | ruidoso | sobrecarregado>
- Problema dominante: <one line>
- Impacto no trabalho: <one line>

## Inventário de memória
- Guardado confirmado: <items actually saved, or "unknown/none">
- Memória implícita da conversa: <what the assistant can currently infer>
- Candidatos para memória durável: <facts/preferences/decisions to retain>
- Memória curta recomendada: <state useful only for next steps>
- Remover/não guardar: <noise, outdated details, redundant items>

## CLAUDE.md
- Tamanho percebido: <small | medium | large | unknown>
- Seções úteis: <bullets>
- Seções redundantes: <bullets>
- O que condensar: <bullets>
- O que mover para handoff curto: <bullets>
- (or "CLAUDE.md not provided / not accessible")

## Plano de enxugamento
1. Manter: <items>
2. Comprimir: <items>
3. Remover/adiar: <items>
4. Próxima revisão: <when to audit again — e.g., "after next major task" or "weekly">
```

## Rules

1. **Never fabricate memory state.** If you can't confirm something was saved, say "unknown" or "candidate".
2. **Read before recommending.** If `CLAUDE.md` or memory files are mentioned or accessible, actually read them before suggesting cuts.
3. **No quota guesses.** Do not include daily/weekly quota lines — Claude Code does not expose quota to the model.
4. **Chat output by default.** Only write to memory files if the user explicitly asks you to apply the recommendations.
5. **No emojis, no hype.** Terse and concrete.
