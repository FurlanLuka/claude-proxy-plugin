---
name: review
description: Audits an existing project against proxy's standards (product, architecture, clean-code, testing, philosophy) and produces a findings report. Use when asked to check if a project conforms to house practices, review/audit an existing codebase, or find standards violations. Report only — never fixes anything itself.
---

Read the required references unless their full, unchanged contents are already available in the current context. Do not assume they were loaded by a startup hook, parent agent, or previous session.

Runs in the main session, live — not a workflow. There's nothing being built and no plan to approve, so no headless constraint and no plan-mode gate; just scan and report.

## Load context

Read every `.md` file in `${CLAUDE_PLUGIN_ROOT}/references/`. Discover the current files rather than relying on a fixed list. Apply each standard to the parts of the project it governs; loading walkthrough or data-analysis guidance does not require creating artifacts or running data queries for an unrelated audit.

## Scope

If what to review isn't already clear from the request (whole project vs. a specific directory/feature), ask ONE question — same rule as everywhere else in this plugin. Otherwise proceed directly.

## Review

Spawn the specialist agents against the **real, existing codebase** — not a draft plan, the actual code:

- `proxy:product` — scope/usefulness/positioning/UX conformance
- `proxy:architect` — system/module design conformance
- `proxy:clean-code-architect` — extraction, comments, pure-function conventions
- `proxy:test-architect` — test coverage and quality

Give each specialist the audit scope, relevant reference paths, and the request for findings rather than implementation. Pass any applicable walkthrough or data-analysis standards to the specialist reviewing that area. Check areas outside the specialists' scope in the main session and include their findings in the report.

Use the scoped names exactly as written — same collision reasoning as `pair`'s self-review: this plugin's agents share names with existing global ones.

**Important nuance:** `architecture-principles.md`'s own top rule is "match existing project conventions first" — this review isn't about blindly flagging every divergence from proxy's defaults as wrong. An existing, consistent, intentional pattern that differs from a default here is not automatically a violation. Flag divergences for visibility and leave the decision to conform or retain intentional house style to the user — don't present them as verdicts.

## Report

Consolidate findings by category (Product, Architecture, Clean Code, Testing). For each finding: what, where, why it matters, suggested fix — but don't apply anything. This skill reports; it doesn't touch code. Fix findings only in a separate follow-up (`proxy:pair`) requested by the user, never automatically as part of this skill.
