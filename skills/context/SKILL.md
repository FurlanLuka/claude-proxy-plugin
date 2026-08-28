---
name: context
description: Load all proxy reference files (philosophy, architecture principles) into the current conversation. Use when Luka asks to load his standards/preferences, or wants them applied without going through the plan skill.
---

Read every `.md` file in `../../references/` (currently `philosophy.md`, `architecture-principles.md`, `clean-code-principles.md`, `testing-principles.md` — read whatever's actually there, don't hardcode this list, new files get added over time).

Apply everything in them for the rest of this conversation — same weight as if `plan` had loaded them. This is the standalone way to get that context without going through planning/plan-mode.

Confirm what loaded with a short list of file names — don't dump the full contents back into chat, they're already in context now.
