---
name: pair
description: Same planning process as `plan`, but implements live in the main session with him present instead of handing off to an unattended workflow. Use when he wants to watch/participate in the build, or when the task might need to ask him something mid-implementation.
---

Identical to `plan` (`../plan/SKILL.md`) through everything up to approval — read and follow that skill's process exactly: Load Context, Infra gap check, Clarification phase (one question at a time, propose before asking), Drafting the plan, Self-review before presenting, Enter plan mode. Don't duplicate that logic here, just follow it verbatim. The only difference is what happens after approval.

## On approval

Don't launch `build-product`. Implement directly, right here, in this conversation instead:

- Apply `architecture-principles.md`, `clean-code-principles.md`, and `testing-principles.md` yourself — already loaded during planning, no need to re-read.
- Write the code with Edit/Write, run tests with Bash, loop fix → retest until green. Same bar `implementer.md` holds itself to: tests and logs are non-negotiable, match existing project conventions first.
- Unlike the workflow, there's no headless constraint here — if something genuinely needs his input mid-build, ask. Same discipline as everywhere else in this plugin still applies: only for real product/technical decisions, one question at a time, not implementation details.
- After implementing, still get a second pair of eyes before calling it done — spawn `proxy:clean-code-architect` and `proxy:test-architect` (scoped names, same collision-avoidance reasoning as `plan`'s self-review) to review the diff, loop fix → re-review until clean. Same review discipline as `build-product`'s Review Code phase, just synchronous here instead of async in a workflow.
- Report done directly in chat when finished. No workflow notification needed — he's already watching.

## When to use this vs `plan`

Default to `plan` → `build-product` for most work — that's the whole point of this plugin, write a spec and walk away. Use `pair` specifically when he wants to be present for the build, or the task is likely to need his input partway through rather than everything being resolvable up front.
