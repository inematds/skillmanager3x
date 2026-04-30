---
name: memory-audit
description: Use to audit memory and context quality. Triggers include "audit memory", "memory audit", "analyze memory", "analyze CLAUDE.md", "what was saved", "context too large", "memory bloated", "what to remove", "clean memory", "review memory". Produces an inventory of what is in memory, what should stay durable, what is short-term context, and what is noise to remove.
---

# Memory Audit

Review what is stored or should be stored in memory: durable facts, short-term working state, `CLAUDE.md` content, and noise to discard.

This is a **memory quality review**, not an operational status (use `session-statusline`) and not an end-of-session handoff (use `session-handoff`).

## When to invoke

User says any of: "audit memory", "memory audit", "analyze memory", "analyze CLAUDE.md", "what was saved", "context too large", "memory bloated", "what to remove", "clean memory", "review memory".

Do NOT invoke for general status checks ("where are we", "checkpoint") — those go to `session-statusline`. Do NOT invoke for end-of-session ("handoff", "about to /clear") — those go to `session-handoff`.

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
# Memory and Context Audit

## Diagnosis
- Context state: <lean | moderate | noisy | overloaded>
- Dominant problem: <one line>
- Impact on work: <one line>

## Memory inventory
- Saved (confirmed): <items actually saved, or "unknown/none">
- Implicit conversation memory: <what the assistant can currently infer>
- Candidates for durable memory: <facts/preferences/decisions to retain>
- Recommended short memory: <state useful only for next steps>
- Remove / do not save: <noise, outdated details, redundant items>

## CLAUDE.md
- Perceived size: <small | medium | large | unknown>
- Useful sections: <bullets>
- Redundant sections: <bullets>
- What to compress: <bullets>
- What to move to short handoff: <bullets>
- (or "CLAUDE.md not provided / not accessible")

## Trim plan
1. Keep: <items>
2. Compress: <items>
3. Remove / defer: <items>
4. Next review: <when to audit again — e.g., "after next major task" or "weekly">
```

## Rules

1. **Never fabricate memory state.** If you can't confirm something was saved, say "unknown" or "candidate".
2. **Read before recommending.** If `CLAUDE.md` or memory files are mentioned or accessible, actually read them before suggesting cuts.
3. **No quota guesses.** Do not include daily/weekly quota lines — Claude Code does not expose quota to the model.
4. **Chat output by default.** Only write to memory files if the user explicitly asks you to apply the recommendations.
5. **No emojis, no hype.** Terse and concrete.
