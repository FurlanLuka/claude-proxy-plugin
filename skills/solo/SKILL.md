---
name: solo
description: Autonomous variant of `pair` — same loop, but the agent makes every call itself. No clarification questions, no plan approval click, no QA approval click; the user can interrupt anytime to steer. For bug fixes and small features. Use on "just fix it", "bug fix, don't ask", "you decide and run it", "solo this". Not `pair` + "you decide" — that skips questions but still stops for two approvals; solo stops for none and bounces to `pair` if scope grows.
---

Read the required references unless their full, unchanged contents are already available in the current context. Do not assume they were loaded by a startup hook, parent agent, or previous session.

Read `${CLAUDE_PLUGIN_ROOT}/skills/pair/SKILL.md` and follow it end to end, including its prerequisite check and context loading. The overrides below win wherever they conflict. Do not invoke `pair` through the Skill tool — its clarification flow would take over.

Open with one line so the user knows what they are watching:

> solo: no questions, plan mode auto-approves, bounces to pair if scope grows. Interrupt anytime to steer.

## How the approval click disappears

Plan mode stays real — read-only exploration, plan file, `EnterPlanMode`/`ExitPlanMode`. Three plugin hooks handle the approval, and none of them need anything from you:

- Invoking this skill, by typing `/proxy:solo` or through the Skill tool, armed a per-session marker (`/tmp/claude-proxy-solo-<session_id>`). Invoking `proxy:pair` disarms it.
- `ExitPlanMode` is auto-approved while the marker exists (needs `jq` or `python3` on the machine).
- Any other user prompt outside plan mode removes the marker.

Never create, touch, or remove that file yourself — the permission classifier treats a model writing its own approval switch as self-modification and denies it. The hooks own the marker.

Plan mode itself: `EnterPlanMode`, write the plan file, `ExitPlanMode` immediately — no narration, the plan file is the record. Same for `qa-plan`'s plan mode. If the dialog appears anyway (plugin not reloaded since install, older Claude Code, neither `jq` nor `python3` available), that is the safe direction — proceed when the user approves. Never work around it. Without an interactive session and the plan-mode tools, solo is blocked exactly like `pair`; report it per `${CLAUDE_PLUGIN_ROOT}/docs/prerequisites.md`.

## Scope gate — whenever it trips

Stop and hand off to `pair` the moment any of these shows up, before drafting *or* mid-implementation:

- new module, new API surface, new data shape
- spans more than one repo
- infra gap (no test framework, no logging setup, no deploy pipeline — `pair`'s gap check)
- schema migration, auth/billing/permissions code, destructive data operations
- a product fork that changes what the feature *is* or who it is *for*, with no obvious answer in the spec

Before implementation: one message — what was found, why it is pair territory. Mid-implementation: stop, leave the working tree as it is (do not revert silently), say what is partial. Either way, end with: "run `/proxy:pair`, context is already loaded." Never ask, never keep building.

## No clarification phase

Skip `pair`'s clarification procedure entirely. Resolve forks yourself:

- Technical forks: take the option you would have recommended.
- Product forks smaller than the gate above: decide using `philosophy.md` and `product-principles.md`.
- Anything the references already have a default for: use it.

Keep a running **Decisions made** list — one line each, with the reason. It leads the final report.

## Self-review

Same specialists as `pair`. If one surfaces a genuine decision, apply the rules above — decide it or bounce — never route it back to the user.

## Visual pass

Skip `plan-walkthrough`. Anything structural enough to draw bounces anyway.

## Steering

The user may interrupt with a redirect at any point. Take it, adjust in place, continue autonomously from where you were. Do not switch to asking questions, do not restart from the top.

- The prompt arrived outside plan mode → the hook removed the marker. Before your next `EnterPlanMode`, invoke `proxy:solo` again through the Skill tool; that re-arms it. Do not restart the workflow or repeat the opening line because of the re-invocation, just continue.
- The prompt arrived inside plan mode → the marker is still armed. Keep planning and exit as normal.
- The user says stop while you are in plan mode → do not call `ExitPlanMode`. End the turn with one line: the marker is armed until they leave plan mode (Shift+Tab) or send a prompt outside it.

## Implementation

As `pair`, with zero questions. There is no "one question for a genuinely big blocker" exception — a hard blocker is a scope-gate stop.

## QA

Invoke `proxy:qa-plan` as `pair` does. Two overrides for `qa-plan` itself:

- No questions at all, including its "genuinely big blocker" clause.
- Missing QA tooling does not trip the scope gate — the build is done. It goes under **Couldn't verify**; it never stops the run.

## Final report — one message

1. **Decisions made** — the running list.
2. **What changed** — files, behavior, tests added.
3. **Reviewers** — outcome of the clean-code and test-architect passes.
4. **QA** — exercised / passed / failed / couldn't verify, from `qa-plan`.
