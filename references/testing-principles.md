# Testing Principles

Source of truth for test strategy — used by `test-architect` and (when writing tests) `implementer`. Tests are non-negotiable per `architecture-principles.md`; this file is the how.

**Not TDD.** Tests verify that real behavior works, written alongside or after the implementation — not a test-first, red-green-refactor discipline driving the design. Write the code, then write tests that confirm it actually does what it's supposed to, then run them for real. Don't write a failing test first and implement to satisfy it.

## Core Philosophy

Three principles guide every decision, in order of priority:

1. **Test behavior, not implementation** — tests assert what the code does, not how it does it. If a refactor changes internals but preserves behavior, zero tests should break. The exception is snapshot tests, which intentionally detect any output change.
2. **Pure functions first** — the highest-value tests are on pure functions. They're fast, deterministic, and easy to write. Extract logic from services into pure helpers specifically to make it testable (see `clean-code-principles.md`).
3. **Confidence over coverage** — 100% line coverage with shallow assertions is worse than 80% coverage with tests that actually catch bugs. Every test should exist because a failure would indicate a real problem.

## What to Test

### Always Test (high value, low cost)
- **Pure functions** — any function that takes inputs and returns outputs without side effects. These are the core of the test suite.
- **Algorithm output** — scheduling, sorting, scoring, conflict detection, or whatever business logic makes the app valuable.
- **Edge cases in domain logic** — zero values, empty inputs, boundary conditions, off-by-one scenarios.
- **Deterministic snapshots** — capture exact output for fixed inputs. When the algorithm changes, the snapshot breaks, forcing explicit acknowledgement.

### Test Selectively (moderate value, moderate cost)
- **Integration between pure functions** — run the full pipeline with realistic data to catch composition bugs.
- **Performance guardrails** — assert that operations complete within a time budget. Keep limits tight (3-5x observed time) so regressions are caught early.
- **Data transformation chains** — multi-step pipelines where an intermediate bug wouldn't show up in a unit test of any single step.

### Don't Test (low value, high cost)
- **Framework wiring** — decorators, module imports, DI registration. The framework tests this.
- **Database queries in isolation** — test the logic that uses query results, not the query itself.
- **Private methods directly** — if a private method needs its own tests, extract it to a pure helper.
- **Third-party library behavior** — don't test that a library function works.

## Extracting for Testability

The most impactful test strategy decision is **what to extract**. When logic is trapped inside a service method that depends on a database, DI container, or external state:

1. Identify the pure core — the part that takes data in and produces data out.
2. Extract it to a helpers file as an exported pure function.
3. Update the service to call the extracted function.
4. Test the pure function directly — no mocks needed.

This is always preferred over mocking. Mocks test that you called the right function with the right arguments. Pure function tests verify that the actual logic produces correct results.

## Test Structure

### File Organization
- Test files live next to the code they test: `foo.helpers.ts` → `foo.helpers.spec.ts`
- One spec file per helpers file. Algorithm tests get their own spec file.
- Snapshot files are auto-generated in `__snapshots__/` directories.
- Shared test utilities (factories, helpers) go in a common test-support location.

### Test File Layout
```
imports
factories / helpers (local to this file)
describe('functionName', () => {
    it('primary behavior', ...)
    it('edge case', ...)
    it('error case', ...)
})
// Next function...
```

### Naming
- Describe blocks: function name or feature area.
- Test names: `input condition → expected outcome` using arrow notation.
- Example: `'frozenDaysCount=0 → returns start of day'`.

### Factories
- Build domain objects with sensible defaults and surgical overrides.
- Only specify what matters for this test — e.g. `makeOperation(machineId, shiftId, { duration: 120 })`.
- Use a deterministic anchor date/seed for anything time- or randomness-dependent — same input, same result, every run.

## Snapshot Tests

### When to Use
- **Algorithm output** — capture the exact result for fixed inputs. If ordering logic changes, the snapshot breaks.
- **Generated structures** — anything with many interacting fields where a full-object diff catches subtle bugs a spot-check would miss.
- **Cascading state changes** — capture how a system responds when one upstream value changes.

### How to Use
1. Serialize results to a stable, readable format (strip non-serializable objects, use unix timestamps).
2. Call `expect(serialized).toMatchSnapshot()`.
3. First run auto-creates snapshot files. Subsequent runs compare against stored snapshots.
4. When a snapshot breaks, verify the change is intentional before updating it.

## Performance Tests

- Set limits at 3-5x the observed execution time. Tight enough to catch regressions, loose enough to avoid flakes.
- Test increasing scale tiers, each with its own time budget.
- Performance tests assert completeness too — nothing silently dropped under load.
- Log actual execution time in test output for visibility.

## Test Tooling

- Use whatever the project's existing test runner is — don't introduce a second one.
- Snapshot testing via the runner's built-in matcher — auto-managed snapshot files.
- **No mocks** for pure function tests. If a test needs mocks, the code probably needs extraction instead (see `clean-code-principles.md`).
- Domain-specific assertion helpers for common invariants worth naming and reusing across test files.

## Collaboration with Clean Code Architect

When a test plan identifies logic that is hard to test because it's trapped inside services (requires mocks, DI bootstrapping, or database setup), recommend extraction via **clean-code-architect** — see `clean-code-principles.md`. Clean-code-architect designs the extraction; test-architect designs the tests for the extracted pure functions.

## Test Plan Output Format

When producing a test plan, structure it as:

1. **Coverage gaps** — what's currently untested and why it matters.
2. **Extraction needed** — pure functions trapped in services that should be extracted for testability.
3. **Test cases** — grouped by function/feature, each with a one-line description of input → expected output.
4. **Snapshot candidates** — which outputs should be captured as deterministic snapshots.
5. **Files to create/modify** — table of spec files and source files affected.
6. **Implementation order** — sequence that builds on previous steps (extract → unit test → integration test → snapshot).
