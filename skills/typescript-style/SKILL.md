---
name: typescript-style
description: TypeScript and React style conventions, distilled from the Decentrl codebase - blank-line rhythm, naming, terse "why" comments, params objects, pure rule modules beside thin services, returned error codes, prefixed log lines, arrow-named tests. Use it whenever you write, edit, refactor or review TypeScript, JavaScript or React code, add a service, hook, component, schema, reducer or test, or write a commit message in a TS repo, even if the user never mentions style. Also use when the user asks for code that "reads like Decentrl", "matches our style" or "looks clean".
---

# TypeScript style

Read the required references unless their full, unchanged contents are already available in the current context. Do not assume they were loaded by a startup hook, parent agent, or previous session.

Write code that reads like a careful spec: short declarative sentences, one idea per block,
and nothing that doesn't earn its place. Make each block's decision and reason clear when
reading top to bottom. These conventions are distilled from the Decentrl codebase.

**Match the repo you're in first.** If the project already has a formatter, lint rules or a clear
house pattern, follow it; apply this style where the repo has no opinion. Formatting itself
(tabs, width 100, single quotes, semicolons, trailing commas) belongs to the formatter, not to
you: run it.

Read the reference for what you're touching:

- React components, hooks, reducers and selectors: `${CLAUDE_PLUGIN_ROOT}/skills/typescript-style/references/react.md`
- Tests: `${CLAUDE_PLUGIN_ROOT}/skills/typescript-style/references/tests.md`
- Commit messages and PR text: `${CLAUDE_PLUGIN_ROOT}/skills/typescript-style/references/commits.md`
- A full worked example (rule module, service, test): `${CLAUDE_PLUGIN_ROOT}/skills/typescript-style/references/example.md`

## 1. Vertical rhythm

Blank lines are punctuation. They separate decisions, not declarations.

- Consecutive `const` declarations and simple calls run together, even when they `await`.
- A blank line before every `if`, `for`, `while`, `try` or `switch` that follows other statements.
- A blank line after every closing `}` of a block, before the next statement.
- A blank line before every `return` that follows other statements, including inside `if`
  blocks, callbacks and `try`.
- No blank line between an action and the log line that reports it.
- One blank line between top-level items. A function's `XParams` interface sits directly above
  the function.

```ts
const joinedAfterSeq = await lastGroupSeq(group.did);
const code = checkApproval({ hasRequest, isMember, memberCount, maxMembers });

if (code) {
	logger.info('[Mediator] Approval refused', { requesterDid, groupDid: group.did, code });

	return { type: 'ERROR', code };
}

await prisma.$transaction([...memberOps, ...parcelOps]);
logger.info('[Mediator] Member approved', { requesterDid, groupDid: group.did, senderDid });

return { type: 'SUCCESS' };
```

Every `if` has braces, even one-liners. Guards are early returns, one per `if`, so the happy path
stays at the lowest indentation.

## 2. Naming

Names say what a thing decides or returns, so call sites read as sentences.

| Shape | Returns | Examples |
| --- | --- | --- |
| `checkX` | an error code or `undefined` | `checkApproval`, `checkGroupGrant` |
| `authorizeX` | an access decision | `authorizeGroupCommand` |
| `planX` | a `{ status }` union to act on | `planMembershipChange` |
| `isX` / `hasX` / `canX` | boolean | `isJoinRequestLapsed`, `hasGrown`, `canRemove` |
| `xOf` | something derived from or read off `x` | `grantLogOf`, `nameOf`, `threadOf` |
| `xFor` | something per target | `scopeValuesFor`, `endGrantsFor` |
| `toX` / `withX` | a mapping / a wrapper | `toGroupEventRow`, `withGroupLock` |
| `foldX` | next state from an event | `foldSection`, `foldPostEdit` |
| `onX` | a listener or callback prop | `onDeletion`, `onDone` |

- Public methods are short verbs, no `Async` suffix: `invite`, `remove`, `rotate`, `vouch`.
- Booleans start with `is`/`has`/`can`, or read as a flag (`ownerOnly`, `clearsPendingLink`).
- Constants are SCREAMING_SNAKE with the unit in the name: `JOIN_REQUEST_TTL_MS`,
  `BODY_LIMIT_BYTES`, `MAX_PENDING_JOIN_REQUESTS`. Big numbers use separators: `20_000`.
- Error codes are SCREAMING_SNAKE string literals that name the business condition:
  `'STALE_GROUP_KEY'`, `'NOT_A_GROUP_MEMBER'`, `'INVALID_ADMISSION'`.
- Types: `XParams` for a function's params object, `XOptions` for constructor options, `XProps`
  for components, `XContext` for a bundle of closures, `XRejection`/`XResult`/`XPlan` for results,
  `xSchema` for zod schemas.
- Files are kebab-case and say their role: `*.service.ts` touches IO or the database,
  `*-rules.ts` holds pure decisions, `*.schema.ts` holds wire shapes, `use-x.ts` holds a hook,
  `PascalCase.tsx` holds a component, `x.test.ts` sits beside `x.ts`.
- Wire fields stay snake_case as the protocol defines them (`key_version`); TypeScript locals are
  camelCase.

## 3. Comments: terse prose that says why

Comments are the code's second voice. They state an invariant, a reason or a consequence, never
what the next line obviously does.

- Add JSDoc to exported functions, public methods, components and hooks when callers need a
  contract, business rule, external constraint or gotcha that the name and types cannot express.
  Omit it when it would only restate the code. Use one or two declarative sentences, often a
  noun phrase, a colon, then the detail. Never "This function…".
- `//` comments sit directly above the line they justify.
- Plain and terse: colons and semicolons, no "we", no "should", no TODOs, no commented-out code.
- Identifiers in backticks.
- Full JSDoc sentences end with a period. One-line field docs and `//` comments don't.
- When a rule comes from a spec, RFC or ticket, cite it in parentheses: `(DCTRL-0006 §4.7)`.
- Add a short prose block after a pure module's imports only when a shared business rule or spec
  constraint would otherwise be lost. Cite the relevant spec section when one exists; don't
  add a block merely to describe the module's implementation.
- No banner comments. In long classes, `// --- Helpers ---` style dividers separate public steps
  from private helpers; nothing else.

```ts
/** The group's newest event: a member added now reads only what comes after it. */
export const lastGroupSeq = async (groupDid: string): Promise<number> => { … };

/** A request lapses after 30 days, like an invitation: approving it then needs a new one. */
export const isJoinRequestLapsed = (createdAt: Date, now: Date): boolean => …;

interface ForumPost {
	/** Unix ms as claimed by the author: display only */
	timestamp: number;
}

// Only a real refusal proves nothing was committed; anything else is settled by reconcile
if (reply.type === 'ERROR' && reply.code) {
```

The colon reads as "because" or "so": `// The admin needs no grant: one it held ends here`.

## 4. Function shape

- Arrow `const`s with explicit return types on everything exported. `function` only where a
  framework wants one (React components, Next pages).
- One or two simple arguments stay positional. Three or more become one destructured object typed
  by an `XParams` interface declared right above:

```ts
interface CheckApprovalParams {
	hasRequest: boolean;
	isMember: boolean;
	memberCount: number;
	maxMembers: number;
}

export const checkApproval = ({
	hasRequest,
	isMember,
	memberCount,
	maxMembers,
}: CheckApprovalParams): GroupErrorCode | undefined => {
	if (!hasRequest) {
		return 'NO_JOIN_REQUEST';
	}

	if (isMember) {
		return 'ALREADY_A_MEMBER';
	}

	return memberCount >= maxMembers ? 'GROUP_FULL' : undefined;
};
```

- **Pure rules beside thin services.** Decisions live in pure, synchronous, IO-free functions in a
  `*-rules.ts` (or sibling) module. The service gathers facts, often booleans like `hasRequest` and
  `isMember`, passes them in, and acts on the answer. For mutations, use the project's
  established concurrency controls to keep eligibility checks valid when the writes execute.
  When this relies on a transaction or lock, protect eligibility reads as well as writes;
  starting a writes-only transaction after those reads is insufficient. Keep that orchestration
  in the service and decision helpers pure. A service reads top to bottom:
  1. fetch, with `Promise.all` for independent reads;
  2. call the rule;
  3. on a refusal, log it and return the code;
  4. write atomically (one transaction);
  5. after commit, log the success;
  6. return the result.
- Results that branch are discriminated unions: `{ status: 'ok'; view } | { status:
  'rejected'; reason }`. Wire responses use `type: 'SUCCESS' | 'ERROR'`.
- Tables keyed by a union use `Record<Union, X>` so a missing case is a type error.
- Optional keys: `...(cond ? { key } : {})`.
- Signed payloads: build `const signed = { … } as const`, then
  `return { ...signed, signature: sign(signed, key) }`.

### Classes

Only for long-lived stateful objects that own a queue, a transport or storage. They are thin:

- `private readonly` dependencies first, then mutable state.
- One options object in the constructor, defaulted with `??` (inject the clock: `now ?? Date.now`).
- Static factories (`create`, `fromState`) behind a `private constructor` when creation is async.
- Each public method is a line or two that delegates to a pure sibling module (`x-roster.ts`,
  `x-delivery.ts`), passing an `xContext()` of closures.
- Work that must not interleave runs through one serialize queue.

## 5. Errors

- Expected refusals are values, not exceptions: return the code (`'GROUP_FULL'`) or a
  `{ status: 'rejected', reason }`. A server maps codes to HTTP statuses in one table.
- A library's public API throws one error class with a code and a details object naming the ids
  involved:

```ts
throw new DecentrlSDKError(`${did} is not a member`, 'GROUP_REFUSED', { did });
```

- The message is a short sentence fragment. When wrapping an IO failure, keep the original in
  details: `{ eventId, error }`.
- `try`/`catch` only around IO, and only where you can handle or translate the failure. Never
  swallow: a fire-and-forget call reports the error through the structured logger, for example
  `void promise.catch((error) => logger.warn('Optional cleanup failed', { error: serializeError(error) }))`.

## 6. Logging

Follow `${CLAUDE_PLUGIN_ROOT}/references/architecture-principles.md`'s logging contract:
structured fields, centralized collection, and a request ID propagated across client, server
and external calls. Use the project's existing logger and transport. Where neither exists,
establish that baseline before shipping; plain `console.*` strings are not a substitute.

Inspect the logger implementation and representative call sites before using it. Import the
shared application logger when that is the repo's pattern; do not add an injected logger or
request-ID parameter to domain functions merely to satisfy these examples. Reuse the existing
request-scoped context or child logger for correlation. Carry and restore context explicitly
where an actual boundary, such as a queued job, loses it; do not assume every runtime has an
active HTTP request. Preserve injection when the project already uses it.

Messages are short plain-English sentences; entity ids, refusal codes, counters and errors are
queryable fields. Keep the bracketed component voice (`[Mediator]`, `[EventStore]`) where it
fits the project's log format. Use info for a committed state change, refusal or duplicate,
and warn for something dropped or failed, following the project's severity conventions.
Keep counters as numeric fields rather than embedding `JSON.stringify(counts)` in the message.

The examples use an imported application logger with `(message, fields)` and automatic request
correlation. Match the actual logger's import, argument order and context mechanism, preserving
structured fields and correlation. Use the project's configured error field,
serializer and redaction rules; `serializeError` below stands for that redacted serializer.
Preserve useful error codes, type and safe cause details. Never dump raw transport errors,
request configs, headers or bodies that may contain credentials, tokens, invite codes or
customer content.

```ts
logger.info('[Mediator] Approval refused', { requesterDid, groupDid: group.did, senderDid, code });
logger.info('[Mediator] Grant issued', { groupDid: group.did, granteeDid, fromSeq });
logger.warn('[EventStore] Group event dropped', { seq: row.seq, groupDid, reason: verdict.reason });
logger.warn('[Communities] Marking read failed', { groupDid, error: serializeError(error) });
```

## 7. Types, imports, exports

- Named exports only; no default exports outside framework entry points.
- `import type` for type-only imports; inline `type` in mixed ones:
  `import { type GroupContext, lastGroupSeq } from './group.service';`
- Packages first, then relative paths.
- Zod schemas are the source of truth for wire shapes, each followed by
  `export type X = z.infer<typeof xSchema>;`.
- `interface` for object shapes and params, `type` for unions and aliases. Params interfaces stay
  unexported unless a caller needs them.
- `as` only at the boundary where untyped data enters (a JSON column, a parsed message), never to
  silence the compiler mid-logic.

## 8. Before you hand it over

Run the formatter and linter. Then reread the diff top to bottom and ask of each block:

- Does a blank line separate each decision, and nothing else?
- Does every name say what it returns or decides?
- Does every comment give a reason the code can't, in one terse sentence?
- Is every decision a pure function the service calls?
- Would the log lines alone tell what happened?
