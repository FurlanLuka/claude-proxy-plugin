# Commit messages and PR text

## Subject

`type(scope): lower-case summary`, no trailing period. Say what changed for the reader, in the
present tense.

- Types: `feat`, `fix`, `refactor`, `test`, `build`, `chore`, `style`, `ci`, `docs`.
- Scope: the area (`groups`, `sdk`, `social`, `mediator`, `extension`).
- Several changes join with `;`, or follow an em dash.

```
fix(groups): caughtUp rejects for a group this identity no longer reads
test(groups): removing a member who already left logs nothing
fix(extension): take a connecting page's origin from the browser
build(mediator): migrate at deploy, 6 MiB bodies, a status for every group refusal
feat(groups): DCTRL-0006 v0.6 — keys only to accounted members, stricter deletions and grants
```

## Body

Terse, declarative, about behaviour: what was wrong or missing, what happens now, and why. Cite
the spec section when the change follows one. Use `- ` bullets for several items, wrapped near 80
columns. Say where a bug was found when it matters ("Found in QA.").

```
Found in QA: once a read finds the group gone, the transport forgets it and
answers later reads as empty, so the check read looked "caught up" on a
deleted group. caughtUp now requires the group to be joined and keyed.
```

## Pull requests

- `## Summary`: one bullet per change, in the same voice as the commit body.
- `## Testing`: what was run and what it showed, with counts, plus what couldn't be verified and
  why.
