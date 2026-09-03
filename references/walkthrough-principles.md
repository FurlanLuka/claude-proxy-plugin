# Walkthrough Principles

Source of truth for *what a change walkthrough says and how it looks*. Two skills
render it: `plan-walkthrough` (HTML artifact, before approval) and `pr-walkthrough`
(hosted SVG, in the PR description). Neither owns the content rules — this does.

A reviewer reads a diff as a list of edits. A walkthrough shows the mechanism:
what the old path was, what the new one is, and what decides between them.

## Pitch it at architecture, not implementation

The reader wants to know what moved and why, not how each piece works — the code
is right there for that. If a paragraph could only be written by someone who had
read the file, it is too deep. Name the shape of the change, the decision it
turned on, and the thing that would break if it were wrong.

## When there is nothing to draw

Only worth doing when the change is genuinely structural: a pipeline reorder, a
new decision path, a state machine, a module boundary moving. A bug fix, a rename,
a config bump, a copy tweak — say it in prose and stop.

**The test: if you can't name the before-state and the after-state in one sentence
each, there's nothing to draw.** Skip silently. Don't build a page to prove the
step ran.

## Provenance — where the content comes from

Differs by moment, and getting it wrong is the main failure mode.

- **Plan walkthrough** draws *intent*. The after-state doesn't exist yet. Every
  before-state claim is still verified against real code — a plan page that
  misdescribes what's there today argues from a false baseline. Mark the
  after-state as proposed, never as fact.
- **PR walkthrough** draws *what shipped*. Read the actual diff and the actual
  base state. Intent drifts during implementation; a page built from the plan will
  confidently show a design that didn't ship. Every claim is one you just verified
  in a file.

For a stacked PR, diff against its **immediate base**, not `develop`.

## What earns a panel

Four is a good target, and they're usually these:

1. **The entry point that changed** — a new detector in a gather, a new branch, a
   new caller. Draw before and after stacked, same geometry, so the added thing is
   the only visual difference.
2. **The decision** — if the change added a ranking, a ladder, or a state machine,
   this is the panel that matters most. Show the fallthrough.
3. **The bound** — what stops the new thing running away: gates, budgets, TTLs,
   suppressions. Reviewers ask this second; answer it before they do.
4. **What the user experiences** — real before/after transcripts or payloads,
   verbatim from fixtures or prod samples. Never invented. This is the panel
   non-engineers read, and often the only one.

Also worth a panel when it applies: **a design you rejected**, costed against the
one you shipped. It makes a decision legible that would otherwise live only in a
review thread.

## Every figure is a figure

Not a mixture. A page with one hand-drawn diagram, one mermaid block and one
markdown table reads as three documents. Draw everything the same way — the
pipeline, the state machine, the before/after transcripts — all SVG, same palette.

Markdown tables stay markdown when they are genuinely *data*: numbers a reader
might sort, copy, or search. A table used for side-by-side *layout* is a figure
wearing a table costume; draw it.

## The identity is fixed — reuse it, don't re-derive it

Pages accumulate. Two that don't match read as two one-offs; five that match read
as a practice. Vary the composition, never the identity.

Three roles, three accents:

| role | light | dark |
|---|---|---|
| **what this change adds** (`--signal`) | `#b3660d` on `#fdf3e6` | `#e8a33d` on `#2a2113` |
| **what already existed** (`--existing`) | `#3f6d92` on `#eaf1f7` | `#7db0dc` on `#14212c` |
| **suppression / failure** (`--stop`) | `#a8353c` on `#fbeced` | `#e08188` on `#2b1618` |

Neutrals, hue-biased toward the accents:

```
light  --ground #f4f6f8  --panel #ffffff  --panel-sunk #eaeef2
       --rule #ccd5dd  --rule-soft #dfe5eb
       --ink #141a21  --ink-soft #4a5763  --ink-faint #74838f
dark   --ground #0e1319  --panel #161d25  --panel-sunk #111820
       --rule #2b3641  --rule-soft #212b34
       --ink #e4eaef  --ink-soft #a3b1bd  --ink-faint #7c8b98
```

Three faces, one superfamily — display, body, and mono for identifiers:

```
--sans  "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif
--serif "IBM Plex Serif", Georgia, serif
--mono  "IBM Plex Mono", ui-monospace, "SF Mono", Menlo, monospace
```

**Captions state the claim, not the contents.** "the asymmetry is the point", not
"diagram of the gates".

## One page per change, updated in place

The plan page and the PR page are the same page at two moments. `pr-walkthrough`
updates the artifact the plan produced rather than publishing a second one — the
update *is* the drift check: what got approved versus what shipped, same URL.

A walkthrough that shows a design you abandoned is worse than none. If review
changes the design, update the page before merge or delete it.
