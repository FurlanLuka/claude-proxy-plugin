# React, hooks, reducers and selectors

The core rules in `SKILL.md` all apply. This file covers what is specific to UI code.

## Components

- `export function Name()`. Add JSDoc only for a caller-visible contract or constraint that its
  name and props cannot express, following `SKILL.md`'s comment rule. Helper subcomponents in
  the same file are unexported `function`s below it.
- Props in an `interface XProps` above the component, destructured in the signature. A tiny
  component may type inline: `{ state }: { state: NotReadyState }`.
- Body order, no blank lines inside each group:
  1. hooks and derived `const`s;
  2. `useEffect` blocks, with a `//` comment only when the reason or constraint is non-obvious;
  3. handlers as `const send = async () => { … }`;
  4. a blank line, then `return (`.
- Early returns for loading, empty and error states come before the main JSX, each `if` followed
  by a blank line.
- In `.map`, compute per-row `const`s first, then a blank line, then `return (`, with a stable
  `key`.

```tsx
/** Everyone in the community, newest first. */
export function MembersPage() {
	const community = useCommunityContext();
	const [filter, setFilter] = useState('');
	const members = membersOf(community.index, filter);

	if (members.length === 0) {
		return <Empty>no members match</Empty>;
	}

	return (
		<Section label="Members">
			{members.map((member) => {
				const isOwner = member.did === community.ownerDid;

				return <MemberRow key={member.did} member={member} isOwner={isOwner} />;
			})}
		</Section>
	);
}
```

## State and actions

- Plain `useState` for local UI state: `busy`, `error: string | null`, `confirming`.
- Async handlers follow one shape: set busy, clear the error, `try` the call, `catch` into
  `setError(errorMessage(error, 'Could not remove'))`, reset busy in `finally`. Prefer a shared
  `useAction` hook once two components repeat it.
- User actions go through a logging wrapper with a dotted action name:
  `logged('group.remove', { groupDid, did }, () => client.groups.remove(groupDid, did))`.
- Quiet failures use the project's structured logger with action/request correlation:
  `logger.warn('[App] Removing member failed', { ...ids, error: serializeError(error) })`.
  Use the project's redacted serializer and existing logger/context as described in `SKILL.md`.
  Preserve the application's action/request-ID propagation through the API call so client and
  server logs describe the same action; do not assume browser code has server async context.
- Hooks are `useX`, wrap callbacks in `useCallback` with complete deps, and expose state as
  booleans: `isPending`, `isSuccess`, `isError`.

## Accessibility, always, even in mockups

- Real `<button type="button">`, `<a href>`, `<input>` with a `<label htmlFor>`; never
  `onClick` on a `div`.
- `aria-label` on icon-only buttons and unlabeled inputs; `aria-pressed` on toggles;
  `aria-expanded`/`aria-haspopup` on menus.
- Forms submit through `onSubmit` with `event.preventDefault(); void send();`.

## Styling

Follow the app's existing approach. Where the codebase uses inline styles, values come from CSS
variables (`'var(--muted)'`), and `className` is kept for what inline styles can't do (hover,
focus-visible, responsive hiding). Variants live in a `Record<Variant, CSSProperties>`.

UI copy is short and specific. Match the product's voice; labels say what happens.

## Reducers (folds)

- `foldX(state, data, meta): State`, pure.
- **Return the same reference when nothing changes** (the event isn't allowed, or names nothing).
  Composite folds compare children by identity before allocating:
  `return logo === index.logo && forum === index.forum ? index : { ...index, logo, forum };`
- Persisted state is plain JSON: `Record<string, T>` and arrays, never `Map`/`Set`. Read records
  through an own-property helper so ids like `constructor` are safe.
- Empty states are constants: `EMPTY_FORUM`.
- Wire folds with small curried helpers: `perCommunity(inCommunity('forum', foldSection))`.
- Validate event data with zod schemas declared next to the folds; limits as
  `SCREAMING_MAX = 20_000`.

## Selectors

- Plain functions of folded state, named as nouns: `liveSections`, `threadOf`, `replyCount`.
- Work that every row repeats is computed once per state object and memoised in a
  `WeakMap<State, Aggregates>`. Maps are fine there, since that cache is never persisted.
