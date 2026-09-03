---
name: pair
description: Luka's planning and implementation flow — clarify one question at a time, enter real plan mode for live iteration, then implement directly in this conversation on approval. The only build entry point in this plugin; there is no separate unattended workflow.
---

Runs in the main session (not a subagent) so it can call `EnterPlanMode` directly. Front door for all building in this plugin.

## Load context first

Read `../../references/philosophy.md` and `../../references/product-principles.md` — always, every invocation. Product judgment applies to basically every plan, even copy/content-only ones, unlike the architecture-side references below which are conditional.

If the spec involves any new module, new API surface, new data shape, or changes to more than a couple of existing files, also read `../../references/architecture-principles.md`, `../../references/clean-code-principles.md`, and `../../references/testing-principles.md` before drafting — together they're the source of truth for architectural, refactor, and test judgment. Every real feature plan needs test scope decided up front (tests are non-negotiable), and most touch existing code enough that extraction judgment matters too — so treat these three as a set, not architecture-principles.md alone. Skip all three for specs that are purely copy/content/config with no structural decisions.

## Infra gap check — before drafting

Non-negotiables (tests, logs, and anything else `architecture-principles.md` requires as standard) assume the underlying infra already exists in the target repo. It often doesn't.

- Before drafting, check whether the repo already has what the request needs as a baseline: test framework/setup, logging setup, deployment pipeline, CI, etc.
- If something required is missing, flag it immediately — same tier as a product/technical decision, don't bury it as an implementation detail discovered mid-build. Examples: asked to build a feature but no test framework exists → flag "no test setup, need to add it first." Asked for something to be deployed but no deploy pipeline exists → flag "no deploy infra, that's a prerequisite."
- **Infra is its own separate plan, not a phase bolted onto the feature plan.** Feature plans stay scoped to only the feature — don't fold infra setup in as prep work inside the same plan/PR. Stop, plan the infra on its own (its own plan-mode pass, properly thought through, own PR), get it done, then come back and plan the feature assuming the infra now exists.
- Exception: he can explicitly say to defer or skip this — his call, but state the gap, don't silently absorb it into the feature plan by default.
- This is a form of "ask early, not late" — surface the gap during clarification, before committing to a plan that quietly assumes infra that isn't there.

## Clarification phase — before plan mode

**Ask early, not late.** Questions come right after reading the spec, before drafting anything — build the plan together from the start, not present a finished plan and ask him to react to it.

**Default is collaborative.** Ask questions unless he's explicitly said something like "figure it out," "you decide," or "just build it" for this task — then skip straight to drafting, no back-and-forth.

**Scope: product decisions and major technical decisions only.** Not implementation details — that's the agent's job, decide those using `architecture-principles.md` defaults without asking. Ask about things like: what the feature actually does and for whom, which of several genuinely different technical approaches to take, anything that changes scope or shape. Don't ask about naming, file structure, minor library choices, or anything `architecture-principles.md` already has a clear default for.

**For technical decisions specifically, propose before asking.** Don't hand him a blind open question on architecture-level calls — come with a recommended option and a brief tradeoff, let him decide or override. He'd rather react to a proposal than generate the options himself.

**Ask exactly one question at a time.** Never batch multiple questions into one `AskUserQuestion` call, even if several things are unclear.

Why one-at-a-time: earlier answers routinely cause a large course-correction that makes later, pre-written questions irrelevant or wrong. Asking them anyway wastes his attention on stale questions and produces answers to a version of the plan that no longer exists. This matches a well-evidenced pattern from his history — explicit, repeated frustration when an agent skips ahead instead of going through things incrementally ("i told you many times," "i told you to go section by section").

Procedure:
1. Read the spec. Answer anything answerable yourself from the repo/context — don't ask questions you could resolve by reading code. Only ask about genuine forks in approach, product decisions, or major technical decisions only he can make.
2. If something in that scope is unclear, ask ONE question — early, before drafting. For technical decisions, lead with a recommended option. Always leave room for a free-text answer, not just a pick-list. Note: he uses clean multiple-choice picks fine when the options actually fit — this isn't "avoid select-style questions." The real pattern is he free-texts his own answer/correction when none of the offered options match what he wants, so the escape hatch has to be genuinely open, not decorative.
3. Take the answer. Re-assess: does this change what else needs asking? Drop any question that's now moot. If something genuinely still needs clarifying, ask ONE more question. Repeat.
4. Stop asking once there's no real ambiguity left in scope — don't pad with questions for completeness, and don't drift into implementation-detail questions.

## Drafting the plan

- Product decisions made during clarification outrank any existing doc/spec — write the plan to match the decisions, don't hedge against them.
- Plain, direct writing. No ceremony for its own sake — skip inline diagrams, feature flags, heavy formal structure unless the thing being built is meant to last, not a throwaway. (Architecture visuals live on the walkthrough page from the visual pass below, not in the plan prose.)
- For anything sizeable, draft loosely first, then build it out section by section rather than dumping the whole thing at once — matches how he actually works through plans in conversation.
- **A feature ships in one go, as one PR.** Don't scope the plan into a stack of incremental PRs unless he explicitly asks for that. If the work spans multiple projects/repos, that's one PR per project — not one PR per project per stage. Default assumption is "whole feature, done, in a single PR per repo touched." Infra work spun out per the gap check above is its own separate plan and PR by design — that's not a violation of "one PR," it's a different piece of work entirely.

## Self-review before presenting

Before calling `EnterPlanMode`, run the draft past the relevant specialist agents — `proxy:product` for scope/usefulness/positioning/UX soundness (every plan), `proxy:architect` for design soundness, `proxy:clean-code-architect` if the plan touches existing code, `proxy:test-architect` for test-plan soundness. Spawn them as subagents from here; this is background self-critique, not something he sees.

Use the plugin-scoped names exactly as written (`proxy:architect`, not bare `architect`) — he also has global agents with the same bare names, and plugin agents lose that naming collision by default. The scoped form is the only reliable way to get this plugin's version, which carries the "match existing conventions first" rule and the philosophy grounding the bare global agents don't have.

- If a specialist flags a real gap, revise the draft and loop — don't present a plan a spawned architect-agent would immediately poke a hole in.
- If review surfaces something that's genuinely a product or major-technical decision (not just a fixable gap), that goes back through the clarification procedure above — ONE question, same rules — even though initial clarification already happened. Don't silently resolve a real decision yourself just because you're past that phase.
- Keep iterating — revise, re-review, ask if truly needed — until the draft holds up, or until further review isn't surfacing anything new. This is meant to catch obvious gaps before he sees the plan, not to chase perfection indefinitely.
- Once it's solid, move to the visual pass.

## Visual pass — before plan mode

Run `plan-walkthrough` on the settled draft. It builds a before/after page for the
architecture and publishes it as an artifact, so he can see the shape of the change
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

- Apply `architecture-principles.md`, `clean-code-principles.md`, and `testing-principles.md` yourself — already loaded during planning, no need to re-read.
- Write the code with Edit/Write, run tests with Bash, loop fix → retest until green. Tests and logs are non-negotiable, match existing project conventions first.
- **Stay unblocked once implementation starts.** Don't ask him things during implementation — proceed straight through to the end, same as if this were headless. The clarification phase already happened; that's where questions belong. **The only exception is a genuinely big blocker** — something that actually stops progress (a hard infra gap discovered mid-build, a decision with no reasonable default that materially changes scope) — not a preference call or something with a sensible default. When truly blocked, ask ONE question, same rules as clarification; otherwise make the call yourself and note it when reporting done.
- After implementing, still get a second pair of eyes before calling it done — spawn `proxy:clean-code-architect` and `proxy:test-architect` (scoped names, same collision-avoidance reasoning as self-review above) to review the diff, loop fix → re-review until clean.
- Report done directly in chat when finished, including any decisions made without asking and why.

## After implementation: QA

Don't just relay the report and stop. Proceed straight into `qa-plan` (research what's testable, draft the QA plan) and present it for approval — same live checkpoint shape as this skill, just for QA scope instead of build scope. He shouldn't have to remember to manually ask for QA — that's on this skill to carry forward.
