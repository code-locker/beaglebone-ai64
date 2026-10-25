---
name: add-skill
description: Create or update a Claude skill in this repo's skills/ directory so lessons from builds, kernel work, apps, and hardware tests are kept. Use after solving something non-obvious in this repo, when the user asks to save/remember a procedure, or when an existing skill turned out wrong or incomplete.
---

# Add or update a skill

Skills live in `skills/<kebab-name>/SKILL.md`; `.claude/skills` → `skills/`,
so they are picked up on every clone and every PC.

## Decide

- Existing skill covers the topic → **update it** (fix wrong steps, add the gotcha
  to its failure table). Don't create near-duplicates.
- New, reusable procedure (would be repeated, or cost real time to rediscover) → new skill.
- One-off result or log → `docs/mine/notes/` instead.

## Format

```markdown
---
name: <kebab-name>              # matches the folder
description: <what it does + "Use when …" triggers, one paragraph>
---

# Title
Steps with exact commands, then a symptom → cause table, then rules.
```

- Commands must be ones actually run/verified in this repo; mark anything
  untested as such.
- Reference repo files by path instead of copying them (scripts, `versions.lock`, `docs/`).
- Extra material (scripts, long references) can sit next to `SKILL.md` in the folder.
- No work/office names, hosts, emails, or paths.

## Finish

1. Add a line to the index in `skills/README.md`.
2. Commit on a feature branch off `develop` (see `git-workflow`):
   `git commit -m "skills: add <name>"`.
