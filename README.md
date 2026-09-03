# proxy

Personal Claude Code plugin. Turns a product spec into a shipped, tested feature: you approve twice, live — once on the build plan, once on the QA plan — everything runs in this conversation, with you.

There is no unattended/background mode. Earlier versions of this plugin used Claude Code Workflows to run implementation and QA headless in the background — that was dropped deliberately after real testing surfaced enough fragility (undefined args, wrong tool grants, wrong hooks schema, redundant review phases) that a simpler, fully live design won out. `pair` covers building; `qa-plan` covers testing; both run entirely in the main session.

## How it works

```
 /proxy:brainstorm ──────────────────────────────────────────
      │   optional, and separate on purpose. You bring a
      │   half-formed idea, it reacts — opinion first, ~200
      │   words, no options menu, no plan, nothing written.
      │   Ends only when you say "plan this".
      ▼
you write a spec
      │
      ▼
 /proxy:pair ────────────────────────────────────────────────
      │   main session, interactive. Loads philosophy.md + product-
      │   principles.md always; architecture/clean-code/testing-
      │   principles.md for real specs.
      │   Checks for missing infra (tests/logs/deploy) and flags it
      │   early, as its own separate plan — never bolted onto the
      │   feature plan.
      │   Asks ONE question at a time, early, product + major-
      │   technical only — proposes a recommendation on technical
      │   calls rather than asking blind.
      │   Self-reviews the draft against product/architect/clean-
      │   code-architect/test-architect before you ever see it —
      │   loops fix → re-review → ask-if-needed until it holds up.
      │   Then plan-walkthrough: if the change is structural, draws
      │   the before/after architecture as an artifact page so you
      │   can see the shape instead of reading for it. Skips most
      │   plans on purpose.
      ▼
 real plan mode — you iterate live, same as normal Claude Code plan mode
      │   (walkthrough link sits at the top of the plan)
      │
      ▼
 approved → implements immediately, right here
      │
      │   Writes the code, tests, logs. Runs what it wrote, loops
      │   fix → retest until green. Stays unblocked through to the
      │   end — no questions mid-build unless something is a
      │   genuinely big blocker, not just a preference call.
      │   Then a second pair of eyes: clean-code-architect +
      │   test-architect review the diff, loop fix → re-review
      │   until clean.
      ▼
 done → proceeds straight into qa-plan, no need to ask for it
      ▼
 /proxy:qa-plan ─────────────────────────────────────────────
      │   main session, interactive. Researches what's actually
      │   available to test with FIRST (running instance? curl-able
      │   endpoints? browser tooling already set up?) — never plans
      │   around tooling that isn't there. Drafts concrete QA cases
      │   from the real diff.
      ▼
 real plan mode — same live iteration
      ▼
 approved → executes immediately, right here
      │
      │   Hits real endpoints, drives the UI if browser tooling
      │   exists, checks logs actually fire. Same "only use what's
      │   already there" constraint, same "stay unblocked" rule.
      ▼
 Report: exercised / passed / failed / couldn't verify
```

### `/proxy:review`

Different shape entirely — audits an *existing* codebase against all references instead of building something new. No plan to approve; just scans and produces a findings report (product/architecture/clean-code/testing conformance). Report only, never fixes anything itself — that's a separate follow-up via `pair` if he wants findings acted on.

## Directory layout

```
proxy/
├── .claude-plugin/
│   └── plugin.json        manifest — name/description/version/author, rest auto-discovered
├── skills/
│   ├── brainstorm/          bounce ideas, high level, no planning — react and push back, nothing written
│   ├── pair/                the only build entry point — plan live, implement live, on approval
│   ├── review/              audits an existing codebase against all references — report only
│   ├── qa-plan/             plan QA live, execute live, on approval
│   ├── plan-walkthrough/    visual before/after page for a plan, published before approval
│   ├── pr-walkthrough/      that same page, exported to hosted SVG in the PR description
│   └── context/             loads all references/ into the current chat on demand (manual)
├── agents/
│   ├── product.md                 scope/usefulness/positioning/UX — advisor, no Edit/Write
│   ├── architect.md              system/module design — advisor, no Edit/Write
│   ├── clean-code-architect.md   extraction/refactor plans — advisor, no Edit/Write
│   └── test-architect.md         test strategy — advisor, no Edit/Write
├── references/
│   ├── philosophy.md               universal — product taste, communication, delegation
│   ├── product-principles.md       prioritization, feature yes/no, positioning, UX
│   ├── architecture-principles.md  system design judgment (match-existing-conventions first)
│   ├── clean-code-principles.md    extraction/refactor judgment
│   ├── testing-principles.md       test strategy judgment
│   ├── walkthrough-principles.md   what a change walkthrough says + its locked visual identity
│   └── data-analysis-principles.md population-level analysis, source cross-referencing, claim verification
```

All four advisor agents are pure — no Edit/Write, they produce findings/plans, never touch code. `pair` and `qa-plan` are the only places code actually gets written or exercised, and both do it directly in the main session, not by spawning a separate "implementer"/"qa-tester" agent — that split existed when a background workflow needed a headless executor; it doesn't anymore.

## Principles this plugin encodes

Pulled from mining actual work history, not invented — see `~/.claude/projects/-Users-luka/memory/` for the source material.

- Product decisions outrank specs — docs update to match decisions, never the reverse.
- Match existing project conventions before applying any default in these references — for code AND for UX/product patterns.
- Cut anything that doesn't earn its place — except tests and logs, which are never ceremony to cut.
- No useless comments — code should be self-describable; comments only for context code genuinely can't express.
- Reviewers own rigor; you own product judgment. Every implementation gets reviewed before it's "done," but scope calls stay yours.
- One PR per repo touched, whole feature in one go — infra work is its own separate plan, never bolted onto a feature plan.
- Once implementation starts, stay unblocked through to the end — ask only for a genuinely big blocker, not a preference call.
- Real plan mode is the only place live human-in-the-loop happens — twice, once for build, once for QA. Everything between those two approvals runs straight through, live, with you.
