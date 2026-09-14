---
name: pair
description: Guides collaborative planning and implementation — clarifies one question at a time, enters real plan mode for live iteration, then implements directly in this conversation on approval. The only build entry point in this plugin; there is no separate unattended workflow.
---

Read the required references unless their full, unchanged contents are already available in the current context. Do not assume they were loaded by a startup hook, parent agent, or previous session.

Runs in the main session (not a subagent) so it can call `EnterPlanMode` directly. Front door for all building in this plugin.

Read `${CLAUDE_PLUGIN_ROOT}/docs/prerequisites.md` and check its **Planning and implementation** requirements. Check visual prerequisites only when `plan-walkthrough`'s gate requires that step.

## Load context first

Use `${CLAUDE_PLUGIN_ROOT}/references/philosophy.md` and `${CLAUDE_PLUGIN_ROOT}/references/product-principles.md` on every invocation. Product judgment applies to basically every plan, even copy/content-only ones, unlike the architecture-side references below which are conditional.

If the spec involves any new module, new API surface, new data shape, or changes to more than a couple of existing files, also read `${CLAUDE_PLUGIN_ROOT}/references/architecture-principles.md`, `${CLAUDE_PLUGIN_ROOT}/references/clean-code-principles.md`, and `${CLAUDE_PLUGIN_ROOT}/references/testing-principles.md` before drafting — together they're the source of truth for architectural, refactor, and test judgment. Every real feature plan needs test scope decided up front (tests are non-negotiable), and most touch existing code enough that extraction judgment matters too — so treat these three as a set, not architecture-principles.md alone. Skip all three for specs that are purely copy/content/config with no structural decisions.

## Infra gap check — before drafting

Non-negotiables (tests, logs, and anything else `architecture-principles.md` requires as standard) assume the underlying infra already exists in the target repo. It often doesn't.

- Before drafting, check whether the repo already has what the request needs as a baseline: test framework/setup, logging setup, deployment pipeline, CI, etc.
- If something required is missing, flag it immediately — same tier as a product/technical decision, don't bury it as an implementation detail discovered mid-build. Examples: asked to build a feature but no test framework exists → flag "no test setup, need to add it first." Asked for something to be deployed but no deploy pipeline exists → flag "no deploy infra, that's a prerequisite."
- **Infra is its own separate plan, not a phase bolted onto the feature plan.** Feature plans stay scoped to only the feature — don't fold infra setup in as prep work inside the same plan/PR. Stop, plan the infra on its own (its own plan-mode pass, properly thought through, own PR), get it done, then come back and plan the feature assuming the infra now exists.
- Exception: defer or skip this when the user explicitly requests it, but state the gap; don't silently absorb it into the feature plan by default.
- This is a form of "ask early, not late" — surface the gap during clarification, before committing to a plan that quietly assumes infra that isn't there.

## Clarification phase — before plan mode

**Ask early, not late.** Ask questions right after reading the spec, before drafting anything — build the plan collaboratively from the start rather than presenting a finished plan for reaction.

**Default is collaborative.** Ask questions unless the user has explicitly said something like "figure it out," "you decide," or "just build it" for this task — then skip straight to drafting, no back-and-forth.

**Scope: product decisions and major technical decisions only.** Not implementation details — that's the agent's job, decide those using `architecture-principles.md` defaults without asking. Ask about things like: what the feature actually does and for whom, which of several genuinely different technical approaches to take, anything that changes scope or shape. Don't ask about naming, file structure, minor library choices, or anything `architecture-principles.md` already has a clear default for.

**For technical decisions specifically, propose before asking.** Present a recommended option and a brief tradeoff for architecture-level calls, then let the user decide or override. Don't ask the user to generate the options from scratch.

**Ask exactly one question at a time.** Never batch multiple questions into one `AskUserQuestion` call, even if several things are unclear.

Reassess after each answer: a course correction can make later, pre-written questions irrelevant or wrong. Drop stale questions and proceed incrementally rather than skipping ahead.

Procedure:
1. Read the spec. Answer anything answerable yourself from the repo/context — don't ask questions you could resolve by reading code. Only ask about genuine forks in approach, product decisions, or major technical decisions that require the user's judgment.
2. If something in that scope is unclear, ask ONE question — early, before drafting. For technical decisions, lead with a recommended option. You may use multiple-choice prompts when the options fit, but always allow a free-text answer or correction when none match the user's intent. Don't constrain the response to a pick-list.
3. Take the answer. Re-assess: does this change what else needs asking? Drop any question that's now moot. If something genuinely still needs clarifying, ask ONE more question. Repeat.
4. Stop asking once there's no real ambiguity left in scope — don't pad with questions for completeness, and don't drift into implementation-detail questions.

## Drafting the plan

- Product decisions made during clarification outrank any existing doc/spec — write the plan to match the decisions, don't hedge against them.
- Plain, direct writing. No ceremony for its own sake — skip inline diagrams, feature flags, heavy formal structure unless the thing being built is meant to last, not a throwaway. (Architecture visuals live on the walkthrough page from the visual pass below, not in the plan prose.)
- For anything sizeable, draft loosely first, then build it out section by section rather than dumping the whole thing at once.
- **A feature ships in one go, as one PR.** Don't scope the plan into a stack of incremental PRs unless the user explicitly asks for that. If the work spans multiple projects/repos, that's one PR per project — not one PR per project per stage. Default assumption is "whole feature, done, in a single PR per repo touched." Infra work spun out per the gap check above is its own separate plan and PR by design — that's not a violation of "one PR," it's a different piece of work entirely.

## Self-review before presenting

Before calling `EnterPlanMode`, run the draft past the relevant specialist agents — `proxy:product` for scope/usefulness/positioning/UX soundness (every plan), `proxy:architect` for design soundness, `proxy:clean-code-architect` if the plan touches existing code, `proxy:test-architect` for test-plan soundness. Spawn them as subagents from here; keep this self-critique in the background before presenting the plan.

Use the plugin-scoped names exactly as written (`proxy:architect`, not bare `architect`) to avoid collisions with global agents that share the same bare names. The scoped form selects this plugin's version, which carries the "match existing conventions first" rule and the philosophy references; don't assume another agent with the same bare name has those instructions.

- If a specialist flags a real gap, revise the draft and loop — don't present a plan a spawned architect-agent would immediately poke a hole in.
- If review surfaces something that's genuinely a product or major-technical decision (not just a fixable gap), that goes back through the clarification procedure above — ONE question, same rules — even though initial clarification already happened. Don't silently resolve a real decision yourself just because you're past that phase.
- Keep iterating — revise, re-review, ask if truly needed — until the draft holds up, or until further review isn't surfacing anything new. Catch obvious gaps before presenting the plan; don't chase perfection indefinitely.
- Once it's solid, move to the visual pass.

## Visual pass — before plan mode

Run `plan-walkthrough` on the settled draft. It builds a before/after page for the
architecture and publishes it as an artifact, so the user can see the shape of the change
instead of reading the whole plan to find it.

It gates itself and skips most plans — that's correct, not a failure. Don't argue
with the skip and don't build a page to prove the step ran. Build it once, here, on
a draft that already survived self-review; never on a first draft, and never
re-rendered on each plan-mode edit.

## Enter plan mode

Call `EnterPlanMode` with the draft — artifact link at the top if the visual pass
produced one, one line naming what it shows. From here it's normal interactive plan mode — free-form iteration, not one-question-at-a-time (that rule is specific to the pre-plan clarification phase). Expect interruptions mid-explanation; read them as a steer, not a rejection, and adjust in place.

## On approval — implement directly, right here

Once `ExitPlanMode` is approved, implement immediately in this conversation — don't ask first, that's what approving means.

- Apply the references required by the context-loading rules above. If the scope has grown to require architecture/clean-code/testing guidance that was skipped during planning, ensure that set is loaded before implementing, using the same reference-loading rule.
- Write the code with Edit/Write, run tests with Bash, loop fix → retest until green. Tests and logs are non-negotiable, match existing project conventions first.
- **Stay unblocked once implementation starts.** Don't ask the user questions during implementation — proceed straight through to the end, same as if this were headless. The clarification phase already happened; that's where questions belong. **The only exception is a genuinely big blocker** — something that actually stops progress (a hard infra gap discovered mid-build, a decision with no reasonable default that materially changes scope) — not a preference call or something with a sensible default. When truly blocked, ask ONE question, same rules as clarification; otherwise make the call yourself and note it when reporting done.
- After implementing, still get a second pair of eyes before calling it done — spawn `proxy:clean-code-architect` and `proxy:test-architect` (scoped names, same collision-avoidance reasoning as self-review above) to review the diff.
- After addressing review findings, rerun the relevant checks and return the updated diff and verification results to the reviewers. Repeat fix → verify → re-review until the reviewers confirm no actionable findings remain. Passing tests alone does not complete re-review; finish this loop before reporting implementation done or proceeding to QA.
- Report done directly in chat when finished, including any decisions made without asking and why.

## After implementation: QA

Don't just relay the report and stop. Proceed straight into `qa-plan` (research what's testable, draft the QA plan) and present it for approval — same live checkpoint shape as this skill, just for QA scope instead of build scope. Initiate this step without waiting for a separate QA request.
