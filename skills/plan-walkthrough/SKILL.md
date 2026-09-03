---
name: plan-walkthrough
description: Builds a visual before/after page for a plan and publishes it as an artifact, so the architectural change can be seen instead of read. Runs inside `pair` just before plan mode, and standalone when asked for a visual of a proposed change.
---

A plan is a wall of prose you have to read linearly to find the one decision you
actually care about. This puts the shape of the change on a page: what the system
looks like today, what it looks like after, and what decides between them.

Read `../../references/walkthrough-principles.md` first — it owns the content
rules, the panel set, and the locked palette/type identity. This file is only the
plan-moment specifics.

## When it runs

Inside `pair`: after the draft survives specialist self-review, before
`EnterPlanMode`. Not on the first draft — the page is built once, off a plan that
already holds up, so plan-mode iteration doesn't re-render it.

**Gate hard.** Apply the "nothing to draw" test from the principles file. Most
plans don't clear it, and skipping is the correct outcome — say nothing, go
straight to plan mode. Build the page only when the plan moves a boundary,
reorders a pipeline, or adds a decision path.

Standalone invocation skips the gate — if he asked for it, draw it.

## The after-state is a proposal, not a fact

The single rule that differs from `pr-walkthrough`. The right-hand side of every
panel is something that doesn't exist yet.

- Verify the **before** side against real code, always. Grep it, read it. A
  before-state drawn from memory or from the spec's description of the current
  system is how a plan gets approved against a baseline that isn't there.
- Draw the **after** side from the plan draft, and label it as proposed — a
  "proposed" tag in the panel furniture, and caption voice in the conditional
  ("the gather would fan out", not "the gather fans out").
- Where the plan left something genuinely open, draw the open thing as open. A
  page that resolves an undecided fork silently is worse than one that shows the
  fork — the fork is often exactly what he needs to see before approving.

## HTML artifact is the output

Not SVG files, not screenshots. A published artifact page: theme-aware, live,
zoomable, and reachable from the plan while he's reading it.

- Load `artifact-design` (required) and `artifact-diagramming` before writing.
- Figures are still inline `<svg>` inside the page — same discipline as the PR
  page, so the later export is a find-and-replace rather than a redraw. Keep each
  figure self-contained and its only theme dependency the token names.
- Web fonts are fine here (the artifact CSP allows Google Fonts). The PR moment is
  where they have to be baked out.
- Publish it. Keep the URL — `pr-walkthrough` republishes to that same URL later.

## Hand it to him with the plan

Put the artifact link at the **top** of the plan draft passed to `EnterPlanMode`,
above the prose, with a one-line caption naming the panels. The point is that he
can open the page, see the architecture, and approve or push back without reading
the plan body — the prose is there for the parts the figures can't carry.

Say what it is in one line ("visual of the change, before/after"). Don't narrate
the build.

## Then plan mode as normal

Plan-mode iteration changes the plan; it does not re-trigger this skill. If
iteration changes the *architecture* — a panel is now wrong, not just a detail —
update the page in place at that same URL and say so. Otherwise leave it.

If the plan is approved and implementation drifts, that's `pr-walkthrough`'s
problem, not this one's.
