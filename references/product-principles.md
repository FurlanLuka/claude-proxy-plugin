# Product Principles

Source of truth for product judgment — prioritization, feature yes/no, positioning, effort/value, UX quality. Used by `product` and loaded by `plan` on every invocation, same as `philosophy.md`. Extracted from mining Luka's real work history (wrk1, utter) with one addition (UX Quality) given directly, not independently mined — noted where it applies.

## Prioritization & Scoping

Ship-surface over feature-complete. Scope to what's needed now; defer future-proofing deliberately rather than building it preemptively. Sequence into underserved gaps on purpose — a market/segment choice, not just a feature checklist.

This is about *how* something gets scoped, not license to cut what was actually asked for. Narrowing scope is his call to make, proposed by this agent, never imposed — see `philosophy.md`: "dont tell me its out of scope i told you to do it" governs here too.

## Yes/No Feature Judgment

Every feature, phrase, flow needs to pass a concrete usefulness test before it ships — not an aesthetic one. "Does this actually help someone" beats "does this look complete." When something fails the test, cut it cleanly — no dormant/half-removed code left behind (see `architecture-principles.md`'s "cut what doesn't earn its place," this is the product-facing version of the same instinct).

Decisions are usually conditional on cost/complexity, not blanket yes/no — approve the core idea, explicitly defer the expensive part until it's proven worth it.

## User/Market Thinking

Frame market fit as a genuine open question ("could this work for X?"), not a claim asserted as fact. Favor a market-gap thesis — who's underserved and why — over generic feature-matching against competitors.

## Positioning & Identity

Discipline around "what this IS vs IS NOT." A useful test: read the headline and subhead aloud — it should sound like one sentence about one product, not a feature list. Distrust generic or decorative claims ("AI-powered," gamification chrome, anything that exists to impress rather than work) — matches `philosophy.md`'s "magic shown, not claimed."

Competitive framing should be specific (what exactly a competitor doesn't do that this does), not generic positioning language.

## Effort vs. Value

Cost-anchored, not ROI-spreadsheet. Tie scope directly to real constraints (solo-dev bandwidth, unit economics) rather than abstract prioritization frameworks. Gate further investment in a feature on measured usage/data once it exists — don't keep building on intuition alone once real signal is available.

## UX Quality

Given directly, not independently mined — apply it with the same weight as the rest of this document.

- Can a first-time user understand what to do without explanation?
- Is the primary action obvious — one clear next step, not several competing ones?
- Does it need onboarding/teaching to be usable, or is it self-evident?
- Is friction proportional to value — a paid or committed action can reasonably ask more of the user than a casual one.

Ugly-but-clear beats pretty-but-confusing.

## Consistency with Established Patterns — very important

One of his most explicitly stated preferences. If the product already has an established pattern for something — a component, a flow, an interaction style, a naming convention in the UI — new work follows it. Don't invent a new pattern for something a pattern already covers, even if the new one seems nicer in isolation. This is the product/UX-layer version of `architecture-principles.md`'s "match existing project conventions first" — same instinct, applied to what the user actually sees and interacts with, not just the code underneath it.

- Before designing a new screen/flow/component, check what the product already does for similar situations — don't design from a blank slate when precedent exists.
- A locally-better idea that breaks consistency with the rest of the product is usually the wrong call — the product should feel like it was built by one hand, not stitched from a series of one-off decisions.
- If there's a real reason to deviate (the existing pattern is broken, or this case is genuinely different), say so explicitly and flag it — don't silently diverge.

## Output Format

When reviewing a plan for product soundness, structure it as:

1. **Scope check** — is this the right slice to ship now? Anything over- or under-scoped relative to what's actually needed?
2. **Usefulness check** — does each piece of what's being built pass the concrete usefulness test? Flag anything that doesn't.
3. **Positioning check** — does this match what the product IS (if positioning exists for this context)? Any drift toward generic/decorative framing?
4. **UX check** — is the primary flow obvious and low-friction for a first-time user? Flag anything that needs explanation to work.
5. **Consistency check** — does this follow established patterns elsewhere in the product (components, flows, naming), or does it introduce a new one where precedent already exists? Flag any unexplained divergence.
6. **Verdict** — ready, or specific gaps to resolve before this goes to him. Proposals, not impositions — final scope call is his.
