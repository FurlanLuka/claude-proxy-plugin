# Architecture Principles

Source of truth: `~/.claude/agents/architect.md` (Luka's actual, already-refined architect agent — years of real use, not reconstructed). This file carries that content forward for any proxy component that needs architectural judgment, with grounding notes from mined work history added where they reinforce or extend a principle.

## Match Existing Project Conventions First

Everything in this document — and in `clean-code-principles.md` and `testing-principles.md` — is the default for green-field decisions or when no established pattern exists. It is not a mandate to override what a codebase already does.

Before applying any convention below, check what the project already does for that thing (file structure, naming, error handling style, test framework, logging format, module boundaries). If it has an established pattern, match it — consistency within the codebase beats external convention, even when the established pattern differs from the default here. Extend the existing pattern to cover non-negotiables (tests, logs) rather than introducing a competing one alongside it.

> **Grounding:** "wait can't we add itmeout directly to llm call? like we do for everything else" — explicit preference for matching what's already there over introducing something new, even when the new thing might be better in isolation.

Only fall back to this document's defaults where the project genuinely has no established pattern yet — a new module, a new project, or an area no prior convention touches.

## Core Philosophy

Three principles guide every decision, in order of priority:

1. **Simple** — the easiest solution that solves the problem. No premature abstraction. No framework unless it earns its place. Boring over clever.
2. **Extendable** — new features plug in without rewriting existing ones. Achieve this through composition, clear boundaries, and event-driven decoupling — not through inheritance hierarchies or speculative generalization.
3. **Maintainable** — code is read far more than it is written. Optimize for the reader. Self-documenting names. Small, focused modules. Explicit over implicit.

When these conflict, simplicity wins. Add complexity only when the current design actively blocks a known requirement.

> **Grounding:** matches an explicit, repeated pattern in his own words — "i really like stuff made in a way where it can be reused in the future to some extend and no hacky stuff." Simple isn't an excuse to under-build, though — "i want everything in this ticket. dont tell me its out of scope i told you to do it" — simplicity applies to *how* something is built, not to *whether* the full requested scope gets built.

## System Design Thinking

- Start with the domain, not the technology. Identify the core entities, their relationships, and the operations users need to perform.
- Draw the boundaries first. What are the modules? What owns what data? Where does business logic live?
- Design for the 90% case. Handle the common path cleanly. Edge cases get handled, but they don't drive the architecture.
- Prefer vertical slices (feature-based) over horizontal layers (type-based). A feature module owns its handler, logic, validation, and types — not a `/handlers` folder with files from 40 features.
- Keep the dependency graph simple. Modules depend downward or on shared packages. Circular dependencies are a design smell — resolve with events or restructuring.
- Separate what changes together from what changes independently. This is the single most important principle for module boundaries.

## Module and Feature Organization

### Organize by Feature, Not by Layer

Each feature owns all its parts — the handler, the business logic, the validation, the types.

### Progressive Complexity

- **Start flat.** A new feature gets the minimum files needed. Nothing more until something earns its own file.
- **Extract when it hurts.** When a file passes 300-400 lines or handles clearly distinct sub-domains, split.
- **Nest submodules for complex domains.** The parent orchestrates. Submodules own their sub-domain. Submodules can call each other when needed but prefer going through the parent for cross-cutting operations.

### When to Create a New Module vs Extend an Existing One

- **New module**: the feature has its own data, its own API surface, and could conceptually exist without the other module.
- **Extend existing**: the new functionality is tightly coupled to the existing module's data and operations.
- **Submodule**: the feature is part of a larger domain but complex enough to deserve its own files.

## API Design

- Handlers are thin. Parse the request, call the business logic, return the response. No domain logic in the handler layer.
- Schemas are the source of truth for request validation and response shapes. Derive types from schemas, not the other way around.
- Mutations can return void or minimal confirmation. Queries return data. Keep this separation clean.
- 3+ parameters in any function → use a named object. Self-documenting, easy to extend, better tooling support.
- For command-based APIs (single endpoint, operation determined by payload), use discriminated unions on the command type. Each command gets its own schema. A dispatcher maps types to handlers.

## Database Design

- Transactions for any operation touching multiple related records.
- Normalize by default. Denormalize only when read performance demands it and you can prove the cost.
- Every schema change gets a migration. No manual database edits.
- Index any column used in filtering, ordering, or joining.
- Hard delete by default. Soft deletes only when business requirements demand audit trails.

## Error Handling

- Custom exceptions with descriptive error codes that describe the business condition, not the transport status.
- Handle errors at every boundary — internal calls, external APIs, async operations.
- Never swallow exceptions. Catch only when you can handle meaningfully.
- Validate inputs at the boundary, trust data within the module.
- Early returns for guard clauses. The happy path lives at the lowest indentation level.

## Testing — non-negotiable

Every feature gets tests that verify it actually works, not just that it compiles or type-checks. Write as many tests as it takes to cover real behavior — this isn't ceremony to be trimmed for speed, even under the "skip what doesn't earn its keep" instinct elsewhere in this doc. Tests are the one thing that earns its keep by default.

- Cover the happy path and the edge cases that would actually break in production, not just the trivial case.
- Test behavior/output, not implementation details — tests should survive a refactor that doesn't change behavior.
- Every `build-product` workflow run includes a test stage that loops fix→retest until green before reporting done — don't report a feature complete with failing or absent tests.

## Logging — non-negotiable

More logs than feels natural. Optimize for debuggability: when something breaks, the logs alone should make it obvious where and why, without needing to reproduce locally.

- Log at every meaningful boundary — request in, request out, external calls, state transitions, errors.
- Prefer structured logs (fields, not just message strings) so they're actually queryable later.
- This applies from day one, not just at launch-critical moments — logging is infrastructure, not an afterthought bolted on when something breaks.

## Side Effects and Decoupling

- When an operation triggers side effects that don't tie directly to its core purpose, those side effects should be decoupled via an event-driven pattern. The core operation emits an event; separate handlers react to it.
- This keeps the primary operation clean and focused. Adding a new side effect means adding a new handler — zero changes to the emitting code.
- Side effect handlers should be idempotent — safe to re-run without causing harm.
- Some side effects are critical and must complete before responding. Others can happen asynchronously in the background. Design the system to distinguish between these.

## State Management

- The service/logic layer is the source of truth for data operations.
- No shared mutable state between requests.
- Caches and connection pools managed at the framework level with clear lifecycle.
- Separate server state (comes from API/DB) from client state (exists only in the consumer). Different tools for different jobs.
- Consumers (UI, CLI, other services) should be able to fetch their own data through clean interfaces — avoid passing state through deep chains.

## Type Safety

- Strict typing everywhere. No escape hatches unless absolutely necessary — and if so, narrow immediately.
- Schemas define the shape. Types are derived from them. One source of truth.
- Shared interfaces in dedicated files. Function parameter types defined near the function.
- Generic types for reusable patterns (pagination, service responses, result types).

## Code Organization Conventions

- Named exports only. No default exports.
- No barrel/index files. Import directly from source.
- **No useless comments — this is one of his strongest, most explicitly stated preferences.** Code should be self-describable through naming and structure, not narrated. A comment only earns its place when it adds something code genuinely can't express: product/business context, a non-obvious constraint, the reason a decision was made a certain way — not what the code does (the code already says that) or a restatement of the function name in prose.
- Whitespace is communication. Use blank lines to separate logical blocks — before returns, before conditionals, after blocks. Group related declarations.

## When to Add Complexity

Add complexity only when at least one is true:

1. **The current design actively blocks a known, concrete requirement.**
2. **Duplicate logic within the same domain** — if the same logic exists in multiple places within a module or domain, extract it. Across different domains, duplication is acceptable and preferred over coupling — don't share code across domain boundaries just to avoid repetition. The only exception is pure utilities (generic helpers with no domain knowledge).
3. **The module has outgrown its structure** — a file is over 400 lines, or has 8+ concerns that could cleanly separate.
4. **Cross-cutting concerns pollute core logic** — side effects that should be decoupled via events.

Do NOT add complexity for:
- "What if we need to..." — solve current problems.
- Design patterns for their own sake.
- Configuration flexibility nobody asked for.

> **Grounding:** the same instinct shows up beyond code — he's killed entire features and integrations once they stopped earning their place (dropped a recall feature outright, removed Stripe entirely once RevenueCat covered it: "remove stripe so we don't have unused noise"). Treat unused surface area — dead integrations, unused config, decorative UI — the same way this section treats unnecessary code complexity: cut it, don't let it linger "just in case."

## Infrastructure

- Infrastructure as Code (IaC) whenever possible. Infrastructure must be declarative — define the desired state, let the tooling handle convergence.
- Keep infrastructure as simple as possible. Only introduce components that are genuinely needed. Don't add a cache layer, message queue, or search engine unless the system actively requires it.
- Every infrastructure component has an operational cost — monitoring, maintenance, failure modes. Justify each one.
- When a component is needed (caching, async job processing, pub/sub), pick the simplest option that solves the problem. Don't over-provision or over-architect infrastructure ahead of demand.

## Shared Packages and Monorepos

When a project spans multiple apps or packages:

- Shared packages for genuinely cross-cutting code only.
- Fine-grained exports — consumers import specific modules, not entire packages.
- Builder pattern for complex object construction — chainable, readable, validatable.
- Declarative patterns for consumer-facing APIs — declare what you need, the framework handles the wiring.
- Transport abstraction — decouple business logic from how messages travel.

## Extensibility

Extensibility comes from clean boundaries, not abstraction layers.

- Composition over inheritance. No class hierarchies.
- Plugin points are event-driven side effects. New side effect = new handler, zero changes to existing code.
- New features are new modules. Add a folder and wire it in — don't touch existing modules.
- Configuration over code where patterns repeat.
- Don't build extension points speculatively. Build v1 simply. Refactor when v2 arrives. v3 tells you if the abstraction was right.

## Decisions Override This Document

If a product decision made during planning conflicts with a default in this file, the decision wins — update the design doc to match, don't relitigate the decision by citing architecture defaults. This document sets defaults for when nothing else has been decided, not constraints on what can be decided. (See `philosophy.md` — "product decisions outrank specs" applies here too.)

## Design Output Format

When producing a design plan, structure it as:

1. **Summary** — one paragraph on what is being built and why.
2. **Module structure** — directory tree showing new/modified files.
3. **Key interfaces** — type definitions or schemas for core data shapes.
4. **Flow** — step-by-step of how data moves through the system for the primary use case.
5. **Events/side effects** — what events are emitted, what processors react.
6. **Data changes** — new tables/fields, migrations needed.
7. **Open questions** — anything that needs user input before implementation (route through the `plan` skill's one-question-at-a-time rule, not a bundled list).

## Follow-up Specialists

After producing a design, consider whether the work benefits from a follow-up pass:

- **clean-code-architect** — when the design touches existing code that needs refactoring or internal cleanup.
- **test-architect** — when the design introduces new logic that needs a test strategy.

Recommend these as explicit next steps in the plan rather than skipping straight to implementation.
