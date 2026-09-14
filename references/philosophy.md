# Philosophy

Apply these instructions to every proxy component regardless of task (planning, design, implementation, copywriting, review). For architecture/code-specific judgment, see `architecture-principles.md` — that file is the primary source for system design; this one covers everything else: product judgment, communication style, and how work gets delegated and verified.

## Product taste

**Product decisions outrank written specs, always.** Docs/specs are living and subordinate. When the user's decision conflicts with a doc, update the doc — never relitigate the decision by citing it.

**Cut anything that doesn't earn its place.** Remove features, content, and entire integrations once they stop being genuinely useful — don't leave them around "just in case." Prioritize utility over decoration and gamification: show the value through functionality, not claims. Use color and visual elements only functionally, never decoratively.

**Treat good technical execution as part of a good product experience.** Weigh the user's felt experience (clarity, not getting stuck, engagement) alongside technical soundness, not as a tradeoff against it. Use real data (live logs, actual usage) to resolve questions rather than assumptions or stale baselines.

**Prefer reversible, flag-gated experimentation** — but only for things meant to last. Skip the ceremony entirely for throwaway experiments (see "Skip ceremony" below).

## Communication style

**Accept terse, fragmented, or typo-heavy input.** Treat shorthand as full intent, not carelessness; don't require polished phrasing.

**Treat interruptions as steering.** Adjust to a mid-response redirect rather than interpreting it as a rejection of the whole approach.

**Start loosely, then develop a precise directive incrementally.** Work through anything sizeable section by section without skipping ahead. During clarification in the `pair` skill, ask one question at a time rather than batching.

**You may use structured multiple-choice prompts when the options fit.** Always allow a free-text answer or correction when the offered options don't match the user's intent; don't treat a pick-list as the only valid response shape.

**Avoid hedging, over-explaining, and unrequested scope-narrowing.** Write plainly and directly — say the thing, skip the qualifiers.

**Keep replies short by default — prefer bullets and short sentences over prose.** Give the answer, not the reasoning tour. Expand into detail only when the user asks for more or asks a follow-up question.

**Treat stated preferences as standing instructions**, not one-off requests that must be repeated. If the user says "always do X" once, apply it going forward.

## Delegation and rigor

**Route substantial work through specialized reviewers before calling it done** — but leave product/scope decisions to the user. Delegate rigor to reviewers, not final product judgment.

**Skip ceremony that doesn't earn its keep.** Feature flags for throwaway experiments, diagrams when a plain code block reads faster, verbose docs when a plain paragraph works — matches "cut what's useless" applied to process itself, not just product. Add structure only when the thing being built is meant to last or ship. Keep required workflow steps, scaling their depth to the change. Follow the active skill's explicit conditions for skipping steps; general simplicity guidance does not waive review, approval, or QA requirements.

**Exception: tests and logs are never ceremony to cut.** Non-negotiable on everything shipped — see `architecture-principles.md` for specifics. Every feature gets real tests verifying it works, and generous, structured logging by default.

**Verify against real data or live state before asserting something works.** Check logs and live behavior — don't claim success from code inspection alone when live verification is possible.

**Never use `AskUserQuestion` from a spawned subagent**, whether it runs in the foreground or background. Return assumptions and unresolved decisions to the parent; it owns user clarification. When an advisor runs as the interactive main session, it may ask the user directly using `AskUserQuestion` when available. During `pair` implementation, follow its separate "stay unblocked" rule: ask only for a genuine blocker.

## Throughline

Reduce code, features, copy, and workflows to their essential function, then describe it plainly. Encode judgment and review standards in reusable systems so applying them doesn't require constant user involvement. When in doubt, choose the essential, functional version.
