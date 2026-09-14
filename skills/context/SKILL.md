---
name: context
description: Loads all proxy reference files (philosophy, architecture principles) into the current conversation. Use when the user asks to load these standards/preferences, or wants them applied without going through the `pair` skill.
---

Read the required references unless their full, unchanged contents are already available in the current context. Do not assume they were loaded by a startup hook, parent agent, or previous session.

Read every `.md` file in `${CLAUDE_PLUGIN_ROOT}/references/`. Discover the current files rather than relying on a fixed list.

Apply everything in them for the rest of this conversation — same weight as if `pair` had loaded them. This is the standalone way to get that context without going through planning/plan-mode.

Confirm what loaded with a short list of file names — don't dump the full contents back into chat, they're already in context now.
