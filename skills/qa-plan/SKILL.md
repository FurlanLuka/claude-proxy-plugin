---
name: qa-plan
description: Researches what's actually available to test with, drafts a live QA plan for what was just built, gets approval via plan mode, then launches the qa workflow to execute it. Use after build-product finishes, or whenever a feature needs live verification beyond unit tests.
---

Runs in the main session, same shape as `plan`: research → draft → approve (real plan mode) → hand off to a background workflow. The reason this is a separate skill/workflow from `build-product`: QA scope is its own decision worth a quick look, not something to blindly execute right after implementation.

## Research first — before drafting anything

Read `../../references/philosophy.md`. Then actually investigate what's available to test with — don't assume:

- Is there a running instance of what was built (local server, dev app)? Check, don't guess.
- What's curl-able — real endpoints, real payloads.
- Is browser automation already set up (check for a `run`-style skill or existing tooling)?
- What logs exist to watch while exercising the feature?

**Same hard constraint as `qa-tester`: only plan around tools that already exist.** Don't propose a QA plan that needs something to be installed first (a browser driver, a new client) — if the tooling genuinely isn't there, that's an infra gap, flag it the same way `plan`'s infra-gap-check does, don't paper over it with a plan that can't actually execute.

## Draft the plan

A QA plan is concrete, not aspirational — each item is a specific action with an expected outcome:

- "POST /api/foo with {x, y} → expect 200, {z}" not "test the API."
- "Click through signup flow with valid input → expect redirect to dashboard" not "test signup."

Plain, short, no ceremony — matches how every other plan in this pipeline gets written. Pull from what was actually implemented (the plan/diff/summary from the build that just happened) so the QA plan tests the real feature, not a guess at what it might do.

## Enter plan mode

Call `EnterPlanMode` with the draft. Same live iteration as `plan` — he can redirect, add cases, cut ones that don't matter.

## On approval

Once approved, immediately launch the `qa` workflow — same as `build-product`, don't ask again, that's what approving means. The `qa` workflow runs `qa-tester` against the plan and reports back: exercised / passed / failed / couldn't verify.

Same as `plan`'s approval step: pass exactly `qaPlan` (the approved QA plan text) and `pluginRoot` (this plugin's absolute directory path) in `args`. The `qa` workflow reads its own reference/agent files itself in a first "Load Context" phase — don't assemble and pass that content yourself.
