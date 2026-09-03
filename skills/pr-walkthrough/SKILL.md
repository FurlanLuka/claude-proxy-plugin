---
name: pr-walkthrough
description: Turns a change walkthrough into hosted SVG figures embedded in a PR description, updating the plan's page in place so the diff between what was approved and what shipped is visible. Use when a diff is hard to read from the diff — a pipeline reorder, a new decision path, a state machine.
---

Read `../../references/walkthrough-principles.md` first — it owns the content
rules, the panel set, and the locked palette/type identity. This file is only the
PR-moment specifics: what shipped, and what GitHub will actually render.

## Start from the plan's page, if there is one

`plan-walkthrough` may already have published an artifact for this change. Find
it (`action: "list"`, or the plan itself), read it, and **update that same URL** —
don't publish a second page.

The update is the drift check, and it's free. Every panel that showed a proposal
now has to show what shipped. Where they differ, that difference is the most
useful thing on the page — the reviewer is looking at exactly the part of the
design that moved during implementation. Drop the "proposed" furniture and the
conditional caption voice with it.

If there's no plan page, build one now off the diff.

## Content comes from the code, not the plan

Read the actual diff and the actual base state. Intent drifts during
implementation — a page built from the plan will confidently show a design that
didn't ship. Every claim on the page should be one you just verified in a file.

For a stacked PR, diff against its **immediate base**, not `develop`. The page
shows what *this* PR changed, not what the stack changed.

## The page and the PR are two outputs

The artifact stays normal HTML — real CSS, web fonts, whatever the subject wants.
That's what a person reads, and it follows their theme.

The PR gets the same figures exported to standalone SVG files. Write the page so
that export is mechanical: each figure a self-contained `<svg>` whose only theme
dependency is the token names.

## What GitHub will actually render

Its sanitizer is stricter than it looks, and guessing wastes a round trip. Probe
it instead — `POST /markdown` with `mode: gfm` returns exactly what a PR body
becomes:

```bash
gh api --method POST /markdown --input probe.json   # {"text": "...", "mode": "gfm"}
```

Verified with that:

- **`<picture>` + `<source media="(prefers-color-scheme: dark)">` works.** GitHub
  wraps it in `<themed-picture>`, so one embed follows the reader's theme. This is
  the single biggest upgrade over a plain screenshot, which is fixed-theme forever.
- **Inline `<svg>` is stripped entirely** — it becomes an empty paragraph. But an
  SVG *file* referenced by `<img src>` survives, and camo serves it as
  `image/svg+xml`. So vector diagrams are available; they just have to be hosted.
- **`style=` is stripped; `align`, `width`, `valign` survive.** So `<table>` is the
  only real layout control you get — genuinely useful for before/after panels side
  by side, which markdown alone cannot do.
- `<details>`, `<kbd>`, `<sub>`, `<ins>`, `<blockquote>` all work. So do GitHub's
  `> [!IMPORTANT]` / `> [!WARNING]` callouts.

### Hosted SVG is the format

Sharper at any zoom, a few KB instead of a few MB, and it sits next to the prose
it explains rather than as one enormous image at the top. Two constraints, both
from camo's CSP (`default-src 'none'`):

- **No external fonts.** Google Fonts will not load — write the real fallback
  stacks from the principles file into the SVG or it silently reflows into
  whatever the reader has.
- **No CSS variables or `currentColor`.** They resolve against a stylesheet that
  is not there. Bake literal hex per theme, and export a light and a dark file.

Render one standalone before uploading. A missing font or an unresolved colour
looks fine in the page it came from and wrong in the PR.

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

Keep the artifact link for the person, not the PR: it follows the reader's own
theme and stays live when the exported SVG goes stale. A private artifact URL 404s
for reviewers, so it never replaces the embed.

## Full-page screenshots, if you need one

Usually unnecessary once the sections carry their own figures — it duplicates the
argument at lower fidelity. If you do need one: `prefers-color-scheme` decides the
theme and headless Chromium defaults to dark, so confirm which one you're shipping.

There's no full-page flag — `--screenshot` grabs the viewport. Drive the DevTools
protocol instead. Any Chromium works; Brave and Chrome both expose it.

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

## After

The page is now a claim about the code. If review changes the design — and on a
structural PR it usually does — update the page and re-upload before merge, or
delete it. A walkthrough that shows the design you abandoned is worse than none.
