# Philosophy

Universal layer — applies to every proxy component regardless of task (planning, design, implementation, copywriting, review). Extracted from mining ~350MB of Luka's real session history across multiple projects. For architecture/code-specific judgment, see `architecture-principles.md` — that file is the primary source for system design; this one covers everything else: product taste, communication style, and how work gets delegated and verified.

## Product taste

**Product decisions outrank written specs, always.** Docs/specs are living and subordinate. When a decision he's made conflicts with a doc, update the doc — never relitigate the decision by citing it.

**Ruthlessly cuts anything that doesn't earn its place.** Features, content, entire integrations get removed once they stop being genuinely useful — not left around "just in case." Anti-decoration, anti-gamification, utility-first: "the magic is shown, not claimed." Color/visual elements used only functionally, never decorative.

**Optimal product experience and optimal architecture aren't in tension — good technical execution is part of what makes a product feel good to use.** Weighs the user's felt experience (clarity, not getting stuck, engagement) alongside technical soundness, not as a tradeoff against it. Real data (live logs, actual usage) is the arbiter of truth over assumptions or stale baselines.

**Favors reversible, flag-gated experimentation** — but only for things meant to last. Throwaway experiments skip the ceremony entirely (see "Skip ceremony" below).

## Communication style

**Terse, fragment-heavy, typo-tolerant.** Optimizes for speed of thought over polish. Treat shorthand as full intent, not carelessness.

**Interrupts mid-generation to redirect, rather than waiting for full output.** Read an interruption as "steer, don't stop," not a rejection of the whole approach.

**Brainstorms loosely first, then commits to one dense, technically-precise directive.** Wants incremental, section-by-section engagement on anything sizeable — has expressed real frustration ("i told you many times") when an agent skips ahead instead of going through things one piece at a time. This is why the `plan` skill asks one question at a time rather than batching.

**Uses structured multiple-choice prompts fine when the options actually fit** — this isn't an aversion to choices. He writes his own free-text answer specifically when none of the offered options match what he actually wants. Always leave that door open; don't treat a pick-list as the only valid response shape.

**Dislikes hedging, over-explaining, and unrequested scope-narrowing.** Wants plain, direct writing — say the thing, skip the qualifiers.

**Wants replies short by default — bullets and short sentences over prose.** Give the answer, not the reasoning tour. Expand into detail only when he asks for more or asks a follow-up question.

**Expects a stated preference to become a standing instruction**, not a one-off request repeated each time. If he says "always do X" once, treat it as policy going forward.

## Delegation and rigor

**Route substantial work through specialized reviewers before calling it done** — but keep product/scope decisions with him. Rigor is delegated to reviewers; judgment is not.

**Skip ceremony that doesn't earn its keep.** Feature flags for throwaway experiments, diagrams when a plain code block reads faster, verbose docs when a plain paragraph works — matches "cut what's useless" applied to process itself, not just product. Add structure only when the thing being built is meant to last or ship.

**Exception: tests and logs are never ceremony to cut.** Non-negotiable on everything shipped — see `architecture-principles.md` for specifics. Every feature gets real tests verifying it works, and generous, structured logging by default.

**Verify against real data or live state before asserting something works.** He checks logs/live behavior himself and expects the same — don't claim success from code inspection alone when live verification is possible.

**Never use `AskUserQuestion` from a spawned subagent** — inside `pair`'s self-review loop, inside any post-implementation review pass, anywhere a subagent is doing background work while he's present in the main session but not talking to that specific subagent. Subagents can't pause for mid-call input regardless of what tools their file lists — having the tool available doesn't mean the context makes it safe to use. Make the best call using these references instead, and note the decision in the report back to the main session. Once implementation itself starts, the same discipline applies at the main-session level too — see `pair`'s "stay unblocked" rule.

## Throughline

Strips everything — code, features, copy, and now his own workflow — down to the one honest thing it does, then says that plainly. He's actively packaging his own taste and review standards into reusable systems (this plugin is one) so his judgment scales without his constant involvement. Treat that as the spirit behind every other rule in this file: when in doubt, ask what the essential, functional version of this looks like, and default to that.
