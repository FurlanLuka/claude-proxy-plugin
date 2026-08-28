# proxy

Personal Claude Code plugin. Turns a product spec into a shipped, tested feature end-to-end: you approve twice, live — once on the build plan, once on the QA plan — everything else runs unattended.

## How it works

Two skill → workflow pairs. Each skill is the human-in-the-loop boundary (research, draft, real plan mode, live iteration); each workflow is what runs unattended once you approve.

```
you write a spec
      │
      ▼
 /proxy:plan ─────────────────────────────────────────────
      │   main session, interactive. Loads philosophy.md + product-principles.md
      │   always; architecture/clean-code/testing-principles.md for real specs.
      │   Checks for missing infra (tests/logs/deploy) and flags it early,
      │   as its own separate plan — never bolted onto the feature plan.
      │   Asks ONE question at a time, early, product + major-technical only —
      │   proposes a recommendation on technical calls rather than asking blind.
      │   Self-reviews the draft against product/architect/clean-code-architect/
      │   test-architect before you ever see it — loops fix → re-review →
      │   ask-if-needed until it holds up.
      ▼
 real plan mode — you iterate live, same as normal Claude Code plan mode
      │
      ▼
 approved → immediately launches, no extra confirmation
      ▼
 Workflow: build-product ────────────────────────────────────
      │   background, fully unattended. No mid-run human input — Claude Code
      │   workflows can't pause for it. Any real decision was already
      │   resolved in /proxy:plan (including architect's design review —
      │   that already happened in plan's self-review loop, not repeated here).
      │   Ambiguity here gets the agent's best judgment, noted in the report.
      │
      ├─ Load Context    → reads its own reference/agent files, given only
      │                     the plugin's absolute path
      ├─ Implement        → implementer writes the code + tests + logs,
      │                     runs what it wrote, loops fix → retest until green
      ├─ Review Code      → clean-code-architect / test-architect pass,
      │                     findings loop until clean
      └─ Report           → summary handed back to you

 build-product's report notification arrives → plan skill proceeds straight
 into qa-plan automatically — you don't have to remember to ask for QA
      ▼
 /proxy:qa-plan ──────────────────────────────────────────
      │   main session, interactive. Researches what's actually available
      │   to test with FIRST (running instance? curl-able endpoints?
      │   browser tooling already set up?) — never plans around tooling
      │   that isn't there. Drafts concrete QA cases from the real diff.
      ▼
 real plan mode — same live iteration
      ▼
 approved → immediately launches
      ▼
 Workflow: qa ────────────────────────────────────────────────
      │   background. qa-tester exercises the feature like a real client —
      │   curl, click-through if available — never installs new tooling.
      └─ Report: exercised / passed / failed / couldn't verify
```

## Directory layout

```
proxy/
├── .claude-plugin/
│   └── plugin.json        manifest — name/description/version only, rest auto-discovered
├── hooks/
│   └── hooks.json          SessionStart hook: dumps references/ into every session automatically
├── skills/
│   ├── plan/               interactive planning skill — front door for building
│   ├── qa-plan/             interactive QA-scoping skill — front door for testing
│   └── context/             loads all references/ into the current chat on demand (manual)
├── agents/
│   ├── product.md                 scope/usefulness/positioning/UX — advisor, no Edit/Write
│   ├── architect.md              system/module design — advisor, no Edit/Write
│   ├── clean-code-architect.md   extraction/refactor plans — advisor, no Edit/Write
│   ├── test-architect.md         test strategy — advisor, no Edit/Write
│   ├── implementer.md            the only agent with Edit/Write — executes plans
│   └── qa-tester.md              exercises the running feature live
├── references/
│   ├── philosophy.md               universal — product taste, communication, delegation
│   ├── product-principles.md       prioritization, feature yes/no, positioning, UX
│   ├── architecture-principles.md  system design judgment (match-existing-conventions first)
│   ├── clean-code-principles.md    extraction/refactor judgment
│   └── testing-principles.md       test strategy judgment
└── workflows/
    ├── build-product.js    unattended: review → implement → review → report
    └── qa.js                unattended: qa-tester executes the approved QA plan
```

Each workflow starts with a "Load Context" phase that reads its own reference/agent files itself, given only the plugin's absolute path (`pluginRoot`) — passed as `args` alongside the approved plan text. Plan/qa-plan skills don't assemble and pass file content themselves; that was the original design and it broke on first real use (too much to get right by hand every invocation). This also sidesteps a real name collision — this plugin's `architect`/`clean-code-architect`/`test-architect` share names with existing global agents at `~/.claude/agents/`, which win by default — since the workflow never relies on `agentType` resolution at all.

## Principles this plugin encodes

Pulled from mining actual work history, not invented — see `~/.claude/projects/-Users-luka/memory/` for the source material.

- Product decisions outrank specs — docs update to match decisions, never the reverse.
- Match existing project conventions before applying any default in these references.
- Cut anything that doesn't earn its place — except tests and logs, which are never ceremony to cut.
- Reviewers own rigor; you own product judgment. Every implementation gets reviewed before it's "done," but scope calls stay yours.
- One PR per repo touched, whole feature in one go — infra work is its own separate plan, never bolted onto a feature plan.
- Real plan mode is the only place live human-in-the-loop happens. Everything past approval runs without you, by design.
