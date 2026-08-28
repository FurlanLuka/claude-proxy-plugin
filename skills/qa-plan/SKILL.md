---
name: qa-plan
description: Researches what's actually available to test with, drafts a live QA plan for what was just built, gets approval via plan mode, then executes it live in this conversation. Use after implementation finishes, or whenever a feature needs live verification beyond unit tests.
---

Runs in the main session, same shape as `pair`: research → draft → approve (real plan mode) → execute. The reason QA scope gets its own approval step rather than being folded into implementation: it's its own decision worth a quick look, not something to blindly execute right after building.

## Research first — before drafting anything

Read `../../references/philosophy.md` and `../../references/architecture-principles.md`. Then actually investigate what's available to test with — don't assume:

- Is there a running instance of what was built (local server, dev app)? Check, don't guess.
- What's curl-able — real endpoints, real payloads.
- Is browser automation already set up (check for a `run`-style skill or existing tooling)?
- What logs exist to watch while exercising the feature?

**Same hard constraint as the execution step below: only plan around tools that already exist.** Don't propose a QA plan that needs something to be installed first (a browser driver, a new client) — if the tooling genuinely isn't there, that's an infra gap, flag it the same way `pair`'s infra-gap-check does, don't paper over it with a plan that can't actually execute.

## Draft the plan

A QA plan is concrete, not aspirational — each item is a specific action with an expected outcome:

- "POST /api/foo with {x, y} → expect 200, {z}" not "test the API."
- "Click through signup flow with valid input → expect redirect to dashboard" not "test signup."

Plain, short, no ceremony — matches how every other plan in this pipeline gets written. Pull from what was actually implemented (the plan/diff/summary from the build that just happened) so the QA plan tests the real feature, not a guess at what it might do.

## Enter plan mode

Call `EnterPlanMode` with the draft. Same live iteration as `pair` — he can redirect, add cases, cut ones that don't matter.

## On approval — execute directly, right here

Once approved, exercise the implementation immediately in this conversation — don't ask again, that's what approving means.

- Hit real endpoints with curl (or whatever HTTP client is already set up in the project) — real requests, real responses, not mocked.
- If browser automation is already available, drive the UI through the actual flow: click, fill, submit, observe the result.
- Check logs while doing this — confirm they actually fire and are useful, not just present.
- **Same hard constraint as anywhere else in this plugin: only use tools already available.** Never install a browser driver, a new HTTP client, or anything else to make something testable. If something needed genuinely isn't there, that's an infra gap — report it, don't route around it.
- **Stay unblocked through to the end**, same rule as `pair`'s implementation phase — don't ask him things mid-QA unless something is a genuinely big blocker.

## Report

1. **Exercised** — what was actually run/clicked/hit, one line each, with real inputs and real observed outputs.
2. **Passed** — behavior confirmed working as expected, live.
3. **Failed** — behavior that didn't match expectations, with the actual output/error observed.
4. **Couldn't verify** — anything that couldn't be exercised live and why (missing tooling, no running instance, etc.) — name these, don't silently skip them.
