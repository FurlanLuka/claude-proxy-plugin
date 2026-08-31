---
name: pr-walkthrough
description: Builds a visual before/after page explaining what a PR changed, screenshots it, and embeds it at the top of the PR description. Use when a diff is hard to read from the diff — a pipeline reorder, a new decision path, a state machine — or when asked for a visual/diagram/walkthrough of a change.
---

A reviewer reads a diff as a list of edits. This shows them the mechanism: what the
old path was, what the new one is, and what decides between them.

Only worth doing when the change is genuinely structural. A bug fix, a rename, a
config bump — say it in the PR description and stop. If you can't name the
before-state and the after-state in one sentence each, there's nothing to draw.

## Content comes from the code, not the plan

Read the actual diff and the actual `develop` state. Plans describe intent, and
intent drifts during implementation — a page built from the plan will confidently
show a design that didn't ship. Every claim on the page should be one you just
verified in a file.

For a stacked PR, diff against its **immediate base**, not `develop`. The page
should show what *this* PR changed, not what the stack changed.

## What earns a panel

Load `artifact-design` (required) and `artifact-diagramming` before writing. They
own the design and diagram judgment; everything below is what's specific to
explaining a diff.

Four panels is a good target, and they're usually these:

1. **The entry point that changed** — a new detector in a gather, a new branch, a
   new caller. Draw before and after stacked, same geometry, so the added thing
   is the only visual difference.
2. **The decision** — if the change added a ranking, a ladder, or a state
   machine, this is the panel that matters most. Show the fallthrough.
3. **The bound** — what stops the new thing running away: gates, budgets, TTLs,
   suppressions. Reviewers ask this second; answer it before they do.
4. **What the user experiences** — real before/after transcripts or payloads,
   verbatim from test fixtures or prod samples. Never invented. This is the panel
   non-engineers read, and often the only one.

Also worth a panel when it applies: **a design you rejected**, costed against the
one you shipped. It makes a decision legible that would otherwise live only in a
review thread.

## Keep the pages a set

PR pages accumulate. Two that don't match read as two one-offs; five that match
read as a practice. Fix the identity on the first one and reuse it: same palette,
same faces, same panel furniture, same caption voice. Vary the composition, never
the identity.

State the token system explicitly in the first page's CSS so the next one can
copy it rather than re-derive it. What must stay constant:

- one accent for **the thing this PR adds**, one for **what already existed**, one
  for **suppression/failure**, and neutrals with a slight hue bias toward the
  accent
- a display face, a body face, and a mono face for identifiers — one superfamily
  is the easy way to make three roles cohere
- captions that state the claim, not the contents ("the asymmetry is the point",
  not "diagram of the gates")

## Capture it

`prefers-color-scheme` decides the theme, and headless Chromium defaults to dark.
Confirm which one you're shipping before uploading — an embedded image is
fixed-theme forever, unlike the live page.

There's no full-page flag: `--screenshot` grabs the viewport. Drive the DevTools
protocol instead, measure the content, then capture beyond the viewport. Any
Chromium works — Brave and Chrome both expose it.

```bash
"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  --headless=new --disable-gpu --hide-scrollbars \
  --remote-debugging-port=9222 --window-size=1500,1200 \
  --user-data-dir=/tmp/shot-prof "file:///abs/path/page.html" &
```

Then over the socket from `http://127.0.0.1:9222/json`: `Page.enable`,
`Runtime.enable`, **wait ~3s** for webfonts and any reveal animation to settle,
read `document.documentElement.scrollHeight`, `Emulation.setDeviceMetricsOverride`
to that height with `deviceScaleFactor: 2`, then `Page.captureScreenshot` with
`captureBeyondViewport: true`.

Two things that will bite: CDP nests its result (`msg.result.result.value` for an
evaluate), and a page whose sections animate in will capture mid-fade if you don't
wait. Look at the PNG before uploading — a silent font fallback or a half-faded
section is invisible until someone opens the PR.

## Host it

Find the repo's own convention first — several have an existing bucket and a
naming rule, and committing images into the repo is almost never it. Upload under
a content hash rather than a descriptive filename, and check the URL resolves
before editing the PR.

In this org that's `gs://speak-dev-agent-upload-bucket`, public, hashed names,
documented in speak-ios `agent_docs/skills/artifact-upload`. Public means public:
routine internal engineering material is fine, anything with PII or customer
content is not.

## Put it in the PR

Top of the description, above the prose, inside `<details open>` with a one-line
`<sub>` caption naming the panels. `<img width="820">` keeps it scannable while
staying clickable.

Publish the page as an artifact too and keep the link for the person, not the PR:
it follows the reader's own theme and stays live when the screenshot goes stale.
A private artifact URL 404s for reviewers, so it never replaces the embed.

## After

The page is now a claim about the code. If review changes the design — and on a
structural PR it usually does — update the page and re-upload before merge, or
delete it. A walkthrough that shows the design you abandoned is worse than none.
