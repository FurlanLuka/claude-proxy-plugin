# Clean Code Principles

Source of truth for extraction/refactoring judgment — used by `clean-code` and (when writing/refactoring code) `pair`. Builds on `philosophy.md` and `architecture-principles.md` (Simple > Extendable > Maintainable), applied at the function/code level.

## The Extraction Principle

The highest-impact refactoring is extracting pure cores from impure shells. Most business logic is a pure computation wrapped in side effects (database reads, API calls, framework plumbing). The computation doesn't need the side effects to function — it just needs data.

When decision logic is trapped inside a method that depends on a database, DI container, or external state:

1. **Identify the pure core** — the part that takes data in and produces data out, with no side effects. This is the logic worth testing.
2. **Design the interface** — define what the pure function receives and returns. The inputs should be pre-resolved values, not containers the function has to dig through.
3. **Extract to a helpers file** — an exported pure function with zero framework dependencies.
4. **Transform the call site** — the service becomes a thin orchestrator: fetch data, call helper, act on result.
5. **Test the pure function directly** — no mocks, no test doubles, no framework bootstrapping.

This is ALWAYS preferred over mocking. Mocks verify that you called the right function with the right arguments. Pure function tests verify that the actual logic produces correct results.

## What to Extract

### High-Value Extraction Targets

- **Filter predicates** — complex filter callbacks with multi-branch logic. When a predicate has 5+ lines of conditionals, it's a named function waiting to happen.
- **Decision logic** — if/else chains that compute "what to do next" before the service acts on the result. The decision is pure; the action is impure. Separate them.
- **Computation** — anything that calculates a value from inputs without side effects: scoring, timing, conflict detection, eligibility checks, duration calculations.
- **Transformation chains** — data mapping and reshaping that doesn't need external state.
- **Validation rules** — business rule checks that evaluate data and return a verdict.

### Leave in the Service

- **Orchestration** — the sequence of "fetch, compute, save" stays in the service. That IS the service's job.
- **Trivial logic** — don't extract `items.filter(x => x.active)` just because you can.
- **Query construction** — building database queries stays in the service. Extract the logic that processes query results.
- **Framework wiring** — decorators, module registration, dependency injection setup.

## Service Architecture

Services should follow a linear pattern. When you read a service method top to bottom, it should tell a clear story:

1. **Fetch** — gather immutable data from databases, config, other services.
2. **Compute** — derive new data from what was fetched, using pure helpers.
3. **Decide** — determine what action to take, using pure helpers that return structured results.
4. **Act** — execute the decision: write to database, trigger side effects, return response.

When a service method has deeply nested conditionals, inline computation mixed with database calls, or complex callbacks passed to array methods — that's the signal to extract.

### Context Objects

When multiple service methods need the same bundle of fetched data, aggregate it into a context object. A single factory method fetches everything. Individual methods receive the context and pull what they need.

This eliminates repeated data fetching, keeps method signatures clean, and makes it obvious what data a subsystem depends on.

## Pure Function Design

### Parameter Design

- **3+ parameters → named object.** Always. Define a params type directly above the function. Destructure in the signature so the reader immediately sees what the function uses.
- **Explicit return types** for all exported functions. Never rely on inference at module boundaries.
- **Push resolution to the caller.** The helper should receive pre-resolved data, not containers it has to dig through. Don't pass a dictionary and a key — pass the resolved value. This makes the helper testable without constructing complex nested structures just to satisfy the signature.

### Return Types for Decisions

When a function decides between different courses of action, use tagged/discriminated unions — not booleans, not error codes, not exceptions for control flow.

Each variant carries exactly the data the caller needs to act on that specific decision. The caller switches on the tag and gets type-safe access to variant-specific fields. This is cleaner than computing a value and then checking conditions separately to decide what to do with it.

### Boolean Predicates

For filter predicates and eligibility checks, return `boolean`. Name the function to read naturally as a question: `isOperationFrozen`, `hasConflict`, `canSchedule`. The call site becomes self-documenting: `operations.filter(op => isOperationFrozen({ ... }))`.

### Composition

Pure helpers should be composable. Each function does one thing. Complex behavior emerges from calling simpler functions in sequence. A helper can call other helpers — this is composition, not coupling.

## Type and Interface Placement

- **Domain types** live in a dedicated interfaces/types file per module. These are the core shapes that multiple files reference.
- **Function params types** live in the helpers file, directly above the function that uses them. They are specific to that function and shouldn't pollute the shared types file.
- **Return type aliases** (especially discriminated unions) live near the function that returns them.

## File Organization

### Module Structure

Each module is a vertical slice owning its entire domain. A module has its service (orchestration), its helpers (pure logic), its types (domain shapes), and its tests (collocated).

No barrel/index files. Import directly from source. This keeps dependency chains explicit and makes dead code obvious.

### Helper File Layout

Group helpers by logical function, not alphabetically. Related functions stay together. Internal utilities (unexported) precede the exported functions that use them.

Use section comments sparingly — only for major logical groups within a large helpers file.

## When to Refactor

### Extract When

- A service method has **inline callbacks** with multi-branch logic (5+ lines in a filter, map, or reduce).
- A method **computes then decides** — the computation + decision is one pure core, the action on the result is impure.
- The **same decision logic** appears in multiple service methods.
- A method is **hard to test** because the interesting logic requires bootstrapping the entire service.
- A file exceeds **~400 lines** or handles clearly distinct sub-domains.
- Logic is **buried under indentation** — deep nesting is often a pure function struggling to get out.

### Don't Refactor When

- The code is already a pure function in a helpers file.
- The "improvement" is purely aesthetic with no testability or clarity gain.
- The extraction would create a function used exactly once with trivial logic (under 5 lines).
- The code is framework wiring — leave plumbing as plumbing.
- The refactor crosses module boundaries just to avoid a few lines of duplication. Cross-domain duplication is acceptable and preferred over coupling.

## Leftovers

A change that replaces or removes something usually leaves part of the old thing behind. `philosophy.md` says to cut what no longer earns its place; this is where that gets checked.

When reviewing a change, look for what it orphaned:

- **What it replaced.** The old function, type, component or module, once its last caller moved to the new one. Its constants, its helpers, its tests and fixtures, its config keys and flags, its assets, its docs and comments.
- **What it abandoned on the way.** An approach tried during the build and then replaced, with its helpers, parameters or files still in the diff. A parameter threaded through that nothing reads. A branch that can no longer be reached.
- **What it added and never used.** An export with no importer, a function with no production caller, an option nothing sets.

Something added for a consumer that arrives in a companion change — another repo, or a later change in a stack the plan or brief names — is not a leftover. Name the consumer. If nothing names one and the thing is internal to the repo, it is a leftover.

Search, don't infer. Reading the diff shows what was added, not what stopped being used. For each candidate, search the repo for references, including tests, config, scripts and string-based lookups, and say what you searched. An internal symbol still referenced only by its own test is unused.

A search of this repo only proves something about this repo. Anything other code can reach without importing it here stays undetermined until there is evidence its consumers are gone: a public export of a package or library, a route, a CLI command, a job or handler registered by name, anything resolved at runtime from a string. That it has no caller here, or only a test, is not that evidence. The evidence has to be about the way that thing is actually reached:

- **An exported symbol** is reached by import. Evidence: the package is not published or installed anywhere else, or a search of the repos that depend on it.
- **A route, a command, a job or a handler** is reached by being called at runtime, by clients, schedulers, webhooks or people, whether or not any package is published. Evidence: request or invocation logs, usage data, the list of scheduled jobs and integrations that call it, or a deprecation that has run its course.
- **Anything resolved from a string** is reached through the data that names it. Evidence: what that data holds.

That a service's package is unpublished says nothing about who calls its routes. The owner saying it is unused settles any of them.

Telling "left unused by this change" from "unused before it" needs the state the change started from. Use the pinned before and after in the brief. Without them, report the item under "cannot tell" and say the baseline was missing; do not guess which side it falls on.

What to do with what you find:

- **Left unused by this change** — blocking, when it is internal to the repo or there is evidence its outside consumers are gone. The change removes it, in the same change. Dead code that ships is paid for by every later reader.
- **Unused before this change** — report it, and leave it. Removing it here would widen the diff beyond its own change; it is a follow-up.
- **Cannot tell** — the baseline is missing, or the thing is reachable from outside the repo or at runtime and nothing shows its consumers are gone. Say so and name what would settle it. Never blocking, and never a recommendation to delete on a guess.

## Docs Follow the Change

A doc that describes how something works is part of that thing. When the thing changes and the doc does not, the doc is now wrong, and a wrong doc costs more than a missing one: people and agents act on it.

When reviewing a change, list what it renamed, removed, or made behave differently — functions, commands, flags, config keys, file paths, routes, concepts — and search for each in what the repo says about itself:

- **Docs for people.** README, architecture and design docs, guides, API docs, changelogs where the repo keeps one, comments and docstrings on the changed code.
- **Instructions for agents.** `CLAUDE.md`, `AGENTS.md`, skills, prompts and templates that describe the changed behavior. A stale instruction is followed, not just read.
- **References between docs.** Links, section anchors, file paths, command names, and examples that are meant to run.

Search, don't infer, and say what you searched: the terms and where you looked. Cover both kinds every time — docs for people and instructions for agents. Agent instructions are the easy ones to forget and the costly ones to miss: nobody rereads them, they are simply obeyed. A search of one kind is half a search, and "no docs affected" with no search beside it is not a finding.

This section and Leftovers meet at one line. A doc whose whole subject is gone is a leftover: it is removed. A doc that stays but now says something untrue belongs here: it is corrected.

As with leftovers, telling "made false by this change" from "already false before it" needs the pinned before and after in the brief. Without them, report the doc as undetermined and say the baseline was missing.

What to do with what you find:

- **Now false, because of this change** — blocking. A command that no longer exists, a path that moved, a described behavior the change reversed, a link or reference that no longer resolves. The change fixes it in the same change.
- **Already false before this change** — report it and leave it, for the same reason as code that was already unused: fixing it here widens the diff beyond its own change.
- **New and undocumented** — flag it only where the repo already documents that kind of thing: a new command in a README that lists the commands, a new option in a config reference. Do not ask for docs the project has no habit of writing; `philosophy.md` counts verbose docs as ceremony.
- **Wording, tone, completeness** — non-blocking, as before.
- **Outside the repo** — a spec, a wiki page, a guide in another tool. You cannot search those. When the brief or the code points to one that describes what changed, name it and what in it is likely stale. The implementing session reports it to the user and updates it only when asked.

### When the change is to guidance itself

Skills, agent docs, `CLAUDE.md`, `AGENTS.md`: text that agents act on. A wrong fact there teaches a convention the repo does not have, so a change to it is checked claim by claim.

- **Against the code, never against other guidance.** Every path, identifier, quoted literal, number and stated behavior in an added or changed line is checked in the code it describes. A guidance line is not evidence for itself, or for another guidance line.
- **Quantifiers are claims.** "All", "every", "never", "only": re-derive each with a search. Run the pattern first on a line you know it should match, so that an empty result means no match and not a broken pattern.
- **Removed lines are accounted for.** Each one is restated elsewhere in the change, or removed on purpose and said so. Moving text between files is where a rule gets lost without anyone deciding to drop it.
- **Sweep for contradictions.** Search the rest of the guidance for the terms a changed rule names. Two rules a reader could apply either way are a finding, wherever the second one lives.
- **Renamed or removed headings.** Search for references to the old name.

A claim that needs a run to settle is reported as not checked, with what would settle it. A false claim or a contradiction introduced by the change is blocking, like any other doc the change made false.

## Algorithm vs Helpers

- **Stateful algorithms** — when logic maintains running state across iterations, a class with constructor setup and a public entry method is appropriate. Private methods handle scoring and internal state. The class is still testable — construct it with known inputs, call the public method, assert the output.
- **Everything else** — pure exported functions. No classes for stateless computation. A function that takes data and returns data doesn't need a `this`.

## Equivalence Verification

Every extraction must preserve behavior exactly. The refactored call site must produce identical results to the original inline code for all possible inputs.

- **Trace every branch.** Walk through each conditional path in the original and verify the extracted function handles it identically.
- **Check comparison semantics.** If the original used framework-specific comparisons (e.g., date library methods), verify the extracted version uses equivalent operations.
- **Account for removed side effects.** If the original had logging or metrics in the middle of the logic, decide whether those belong in the service wrapper or can be dropped. Debug logging inside pure decision logic is typically noise — the service can log the result if needed.
- **Preserve implicit behavior.** If the original had two standalone `if` blocks (not `if/else`), the extracted function must handle the case where neither triggers. Subtle things like this are where extraction bugs hide.

## Analysis Process

When analyzing code for refactoring:

1. **Read the service methods** — scan for inline logic that could be pure. Look for complex callbacks, compute-then-decide patterns, and deeply nested conditionals.
2. **Trace data flow** — for each candidate: what does the logic receive? What does it produce? Where does the data come from? Can inputs be pre-resolved at the call site?
3. **Identify the boundary** — where does "fetch data" end and "compute result" begin? The boundary is the function signature of the extraction.
4. **Design the interface** — define params (pre-resolved, minimal) and return type (discriminated union for decisions, boolean for predicates, value for computation).
5. **Verify equivalence** — trace every branch. Confirm the refactored call site produces identical behavior.
6. **Plan tests** — what are the interesting inputs? What are the edge cases? The test plan validates the extraction and becomes the permanent regression suite.

## Comments

Flag useless comments during every review, not just when doing extraction work. Make code self-describable through naming and structure, not narration.

- **Flag:** a comment that restates what the code already says (`// increment counter` above `counter++`), a comment explaining WHAT when the code is already clear, a stale comment that no longer matches the code next to it. A comment this change made untrue is more than a flag: it is blocking under Docs Follow the Change.
- **Fine, leave it:** a comment that captures product/business context, a non-obvious constraint, or the reason a decision was made a specific way — none of which the code itself can express.
- **Describe the present.** A comment says what the reader needs now, not how the code got here: no "used to", "now", "the new flow replaces", no account of an approach that was tried and dropped. The reason a decision stands belongs in the comment; the story of reaching it belongs in the commit.
- **Nothing more transient than the code.** No feature flags, experiments, rollout phases, or other screens and features, unless the annotated code reads that thing. Test: would an unrelated cleanup, a flag deleted or an experiment concluded, silently make this comment wrong? Then it describes the moment, not the contract. Two things are not transient context and stay: a citation of the spec a rule comes from, as `typescript-style` writes it, and the removal condition on something temporary, which `security-principles.md` requires next to an override.
- **Docstrings lead with what a caller must know**: the contract and the gotchas. How the body works, which the reader can see, does not belong there.
- **The same rules cover other text a developer reads**: test names, log messages, error text.
- When in doubt: would removing this comment confuse a reader? If not, it shouldn't be there.

## Collaboration with Testing

Every extraction creates pure functions that need tests — this feeds directly into the non-negotiable testing requirement in `architecture-principles.md`. When producing an extraction plan, include test cases for each extracted function (input → expected output). If the test strategy is complex, recommend spawning **testing** to design the full test suite for the extracted code — see `testing-principles.md`.

## Output Format

When producing a clean code plan, structure it as:

1. **Source analysis** — which methods contain extractable logic, with file and line references.
2. **Extractions** — for each extraction:
   - Source location (file:lines)
   - What it does (one sentence)
   - Interface definition (params + return type)
   - Transformed call site (how the service calls the new helper)
   - Test cases (input → expected output, one line each)
3. **Leftovers** — when reviewing a change: what it left unused, what was already unused nearby, and what could not be determined, each with the search that shows it. "None", with what was searched, when there are none.
4. **Docs** — when reviewing a change: docs and agent instructions it made false, new behavior missing from docs that cover its kind, and docs outside the repo that likely need an update, each with the search that shows it. "None", with the terms searched and where, when there are none.
5. **Files to modify** — table of files and what changes in each.
6. **Implementation order** — sequence that builds incrementally (simplest extraction first).
7. **Verification** — steps to confirm correctness (type check, test run, coverage).
