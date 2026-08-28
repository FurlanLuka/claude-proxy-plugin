---
name: review
description: Audits an existing project against proxy's standards (product, architecture, clean-code, testing, philosophy) and produces a findings report. Use when asked to check if a project conforms to house practices, review/audit an existing codebase, or find standards violations. Report only — never fixes anything itself.
---

Runs in the main session, live — not a workflow. There's nothing being built and no plan to approve, so no headless constraint and no plan-mode gate; just scan and report.

## Load context

Read all five references — always, not conditionally like `plan` does. An audit needs the full standard set regardless of what's being reviewed: `philosophy.md`, `product-principles.md`, `architecture-principles.md`, `clean-code-principles.md`, `testing-principles.md`.

## Scope

If what to review isn't already clear from the request (whole project vs. a specific directory/feature), ask ONE question — same rule as everywhere else in this plugin. Otherwise proceed directly.

## Review

Spawn the specialist agents against the **real, existing codebase** — not a draft plan, the actual code:

- `proxy:product` — scope/usefulness/positioning/UX conformance
- `proxy:architect` — system/module design conformance
- `proxy:clean-code-architect` — extraction, comments, pure-function conventions
- `proxy:test-architect` — test coverage and quality

Use the scoped names exactly as written — same collision reasoning as `plan`'s self-review: this plugin's agents share names with existing global ones.

**Important nuance:** `architecture-principles.md`'s own top rule is "match existing project conventions first" — this review isn't about blindly flagging every divergence from proxy's defaults as wrong. An existing, consistent, intentional pattern that differs from a default here is not automatically a violation. Flag divergences for visibility so he can decide whether to conform or treat it as intentional house style for that project — don't present them as verdicts.

## Report

Consolidate findings by category (Product, Architecture, Clean Code, Testing). For each finding: what, where, why it matters, suggested fix — but don't apply anything. This skill reports; it doesn't touch code. If he wants findings fixed, that's a separate follow-up (`pair` or `plan`), not something this skill does automatically.
