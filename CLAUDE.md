# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A **skill library** for Claude Code — reusable agent workflow templates for session management. There is no build system, package manager, or test suite; the artifacts are Markdown/YAML files.

## Skill Deployment

Skills are installed by copying the relevant folder into a Claude Code skills directory:

- **Global (all sessions):** `~/.claude/skills/<skill-folder>/`
- **Per-project:** `<project>/.claude/skills/<skill-folder>/`

Each skill is a directory containing at minimum a `SKILL.md` with YAML frontmatter (name, description, trigger phrases) followed by the markdown template body.

## Repository Structure

```
skill/
├── en/                  # English skills
│   ├── session-handoff/     # End-of-session context handoff
│   ├── session-statusline/  # Quick in-session checkpoint
│   └── memory-audit/        # Deep memory/CLAUDE.md review
├── pt/                  # Portuguese translations (identical structure)
└── _archive/            # Legacy versions — do not use
```

## Skill File Format

Every `SKILL.md` starts with YAML frontmatter:

```yaml
---
name: skill-name
description: When to use this skill — copied verbatim into the skills list shown to Claude.
---
```

The body is the markdown template Claude executes when the skill is triggered. Keep frontmatter fields (`name`, `description`) in sync between `en/` and `pt/` counterparts.
