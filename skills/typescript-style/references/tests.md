# Tests

Tests read like a truth table of the rules. Use the repo's runner (vitest here) and put
`x.test.ts` next to `x.ts`.

## Names

- `describe('functionName')`: the bare name of what's under test. Two related functions:
  `'grantAtSeq / staffAtSeq'`. A cross-cutting rule: `'deletions: what the mediator allows,
  readers honour'`.
- `it` names are **situation → outcome**: a lower-case noun phrase, an arrow, the result, often
  an error code. No "should", no full stop; a semicolon joins compound outcomes.

```ts
it('the author → honoured: hide (sender, id)', …);
it('an invitee who accepted over a control channel → accounted', …);
it('deleted group, %s → GROUP_DELETED (even from the admin)', …);
it('to a non-member → NEW_ADMIN_NOT_MEMBER; at an old version → STALE_HANDOVER', …);
it('without issued_at (before v0.6) → MALFORMED, and the schema refuses it', …);
```

- A rule with no single input reads as a plain present-tense statement:
  `'a grant counts for events after its from_seq, until revoked or ended'`.
- End-to-end tests: one sentence with a colon or semicolon:
  `'a DID the mediator injects gets no key when the admin rotates; it is reported, not removed'`.

## Structure

- Imports, a blank line, then small factories: `const party = (alias: string) => …`, named
  fixtures (`const alice = party('alice')`), signed or built inputs.
- Override factories take `Partial<Parameters<typeof fn>[0]>` and spread `...overrides` last, so
  each case states only what matters:

```ts
const vet = (overrides: Partial<Parameters<typeof vetMembers>[0]> = {}) =>
	vetMembers({ selfDid: ADMIN, members: [ADMIN, BOB], roster: [], ...overrides });
```

- Case tables with `it.each([...] as const)('%s → %s', (_name, input, expected) => …)`. The first
  column is a readable label bound as `_name`. Keep one shared table when two implementations
  (reader and server) must agree on a rule.
- Arrange and act, a blank line, then the `expect`s. A tiny test is a single `expect`.
- A file-level `/** … */` says what the suite proves, citing the spec. `//` comments explain why a
  case exists.

## What to test

- Pure functions directly, with real inputs (real crypto, real signatures), no mocks. If a test
  needs mocks, the logic probably belongs in a pure helper.
- Services through minimal fakes: `({ send: vi.fn() }) as unknown as Client`. Put shared fakes in
  a `test-helpers.ts`.
- Reducers: apply steps and assert that a refused event returns the same reference
  (`expect(next).toBe(before)`).
- Adversarial cases end to end. Simulate the dishonest party directly, for example by writing a row
  a compromised server would write, or by rewriting a reply, then assert what the honest client
  refuses.
- Snapshots only for truth tables and stable signed bytes, with volatile values replaced by
  placeholders.

## Assertions

- `toBe` for codes, booleans, numbers and identity; `toEqual` for whole result objects;
  `toMatchObject` when only some fields matter; `toBeUndefined()` when a checker's "ok" is
  `undefined`.
- Collapse a result into one comparable value in tables:
  `expect(result.status === 'ok' ? 'ok' : result.reason).toBe(expected)`.
- Several `expect`s are fine when they show both sides of one rule.
- Logs: spy, assert a substring, restore:
  `const warn = vi.spyOn(console, 'warn'); … expect(warn).toHaveBeenCalledWith(expect.stringContaining('NOT_AN_EXTENSION')); warn.mockRestore();`
- Narrow with an explicit guard (`if (!key) throw new Error('dave holds no key')`) rather than `!`.
