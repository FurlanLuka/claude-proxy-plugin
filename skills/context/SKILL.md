---
name: context
description: Loads all proxy reference files (philosophy, architecture principles) into the current conversation. Use when the user asks to load these standards/preferences, or wants them applied without going through the plan skill.
---

Read every `.md` file in `../../references/` (currently `philosophy.md`, `architecture-principles.md`, `clean-code-principles.md`, `testing-principles.md` — read whatever's actually there, don't hardcode this list, new files get added over time).

Apply everything in them for the rest of this conversation — same weight as if `pair` had loaded them. This is the standalone way to get that context without going through planning/plan-mode.

Confirm what loaded with a short list of file names — don't dump the full contents back into chat, they're already in context now.
