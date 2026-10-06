---
name: pr-review
description: Review someone else's GitHub pull request with proxy's four advisors and a correctness review. Verify findings, present a main review and inline comments locally, and post only after explicit approval. Use when asked to review a PR, prepare a review for a PR link, or draft comments on a teammate's PR. Not for your own branch or diff (use /code-review) or for opening a PR.
---

# Review a PR

Gather → review → present → post. No GitHub writes, including pending reviews, replies or resolutions, until the user explicitly says to post. Approval of wording alone is not permission to post.

Invoking this skill requests the four proxy advisors. The main session gathers, verifies and posts; advisors remain read-only. First check the PR review requirements in `${CLAUDE_PLUGIN_ROOT}/docs/prerequisites.md`.

## 1. Gather

Resolve owner/repo and PR number from the URL; a bare number uses the current repository. Ask which repo when a parent-workspace request is ambiguous. Use its clone in the cwd or a child whose `origin` matches; otherwise stop and suggest a session in that repo.

Run Git as `git -C <clone>`, `gh pr` with `--repo <owner/repo>`, and APIs with literal owner/repo endpoints or variables. Read the clone's CLAUDE.md and applicable `.claude/skills/`. Preserve the branch, worktrees and staged, unstaged and untracked files: no pull, checkout, stash or worktree creation. Fetch metadata, Git objects and scratch files may be written.

Read `${CLAUDE_PLUGIN_ROOT}/skills/pr-review/references/github-review.md` for snapshot commands and thread retrieval. Reuse a reference only when its full, unchanged contents are in the current context, never from an assumed hook, parent read or previous session.

- **Pin the snapshot.** Capture `baseRefName`, `baseRefOid` and `headRefOid`, fetch target/head, confirm those commits exist locally, and recheck metadata. Refresh if it moved; report a blocker if it stays unstable. Save `baseRefOid...headRefOid` as the diff. Read code with `git -C <clone> show "<headRefOid>:<path>"`; the checkout is not evidence of the pinned head.
- **Read existing discussions.** Fetch every thread and all replies before classifying them. Resolved threads, author-confirmed fixes and reasoned declines are settled; don't re-raise them without new evidence.
- **Check target policy.** Flag conflicts with documented contribution rules, respecting exceptions. The actual target still defines the diff and merge check.
- **Check integration.** Run `git -C <clone> merge-tree --write-tree <baseRefOid> <headRefOid>`. Report conflicts; on success inspect the returned tree. Bound target-only history (`<headRefOid>..<baseRefOid>`) to PR files, direct callers/dependencies and applicable shared schemas, dependency manifests and configuration. Follow concrete compatibility evidence deeper. Confirmed breakage is a must-fix; a clean text merge is not proof of passing checks. Disclose uncertainty and recommend combined CI verification where needed.
- **Re-review.** Use `gh api user --jq .login`, unless the user names another reviewer. Select that account's latest submitted review by submission time. If its commit is available and an ancestor of the head, save its delta alongside the full pinned diff. Otherwise review the full diff and disclose the missing baseline; don't infer a rebased copy. Pass settled threads to reviewers and distinguish new findings from misses last round when the baseline supports that distinction.

## 2. Review

Verify factual premises before briefing reviewers, using pinned code and authorized read-only data at the layer the application consumes. Stored values alone don't establish what an ORM or validator receives. Label unverified premises as hypotheses; if disproven after dispatch, promptly correct every affected reviewer and revalidate their findings.

Invoke `proxy:context` to load the plugin's references unless their full, unchanged contents are already in context. For TypeScript, JavaScript or React, also read `${CLAUDE_PLUGIN_ROOT}/skills/typescript-style/SKILL.md` and its applicable references; pass them to the clean-code and test advisors. Established repo conventions take precedence over proxy defaults.

Spawn these advisors directly in parallel, scoped to the PR:

- `proxy:product` — scope, usefulness and UX.
- `proxy:architect` — system and module design.
- `proxy:clean-code-architect` — structure, extraction and style.
- `proxy:test-architect` — coverage and test quality.

Give each absolute clone/diff paths, pinned commits, the `git show` instruction, applicable repo skills and reference paths, plus any re-review delta and settled threads. Brief: read-only, no questions, no subagents; decide from the references and flag recommendations and assumptions.

Run the local correctness lens in parallel:

1. Invoke the bundled `code-review` skill with `medium <baseRefOid>...<headRefOid>`. Supply the absolute clone and saved diff paths, requiring `git -C` inspection. Never use `--comment`, `--post`, `--fix` or `ultra`.
2. Check its tool trace for the actual repo and commits. Require pinned-head `git show` evidence, including relevant callers/callees outside the diff; checkout files or an upstream diff do not establish that scope.
3. Discard mis-scoped results and rerun against the pinned snapshot. If that cannot work, report missing correctness coverage.

Add a security pass against the same snapshot for auth, payments, PII or permissions changes. Trace the changed paths end to end in the main session too.

Then verify and triage:

- Read the code behind every retained claim yourself. Check data claims against authorized read-only sources at the application's consumption layer. Confirmed → statement; unconfirmed → question or drop. Keep credentials, PII, customer content and raw sensitive records out of drafts and posts; summarize evidence appropriate for the PR audience.
- Drop harmless deviations from proxy defaults when they match repo conventions, and restatements of intentional changes or accepted tradeoffs.
- Keep evidenced defects, understated impact and unresolved actionable risks, including analytics issues. Mentioning a bug in the description does not settle it. Leave unrelated ticket-level decisions out.

## 3. Present locally

Show the draft in chat:

- **Main review:** lead with what needs fixing; praise in a short clause or omit it. One direct ask per must-address bullet. Refer to the inline comment for details. On Approve, optional asks are suggestions, not conditions.
- **Comments:** numbered inline comments with `path:line`, side and exact text; include any file-level comments explicitly.
- **Coverage:** what you checked, what you couldn't verify and why, and what you left out. Sibling-only findings belong here, naming the owning PR and offering to raise them separately; posting there needs separate authorization. Keep defects affecting this PR's integration in its review.
- **Proposed filing:** finish with `Proposed filing: Approve` or `Proposed filing: Reviewed with comment`, plus one sentence explaining why. Approve sound logic with only tests, cleanup or nits remaining; say plainly when there is nothing to fix. Comment for wrong/unproven core behavior or a landing path that could precede a required dependency. An unreviewed prerequisite alone does not prevent approving a sound stacked PR whose landing order preserves that dependency. Never use `REQUEST_CHANGES` unless asked.

Comment style:

- Cut prose, not facts or context needed to act.
- `Nit: ` for naming, wording or test tidiness, including wording-only factual corrections. Behavioral defects get no label.
- Problem → concrete case or impact → fix. Use blank lines between parts when longer than two sentences.
- Write for someone outside this session: name the function/test, quote stale wording, avoid session shorthand.
- Every production-data number names its source; figures and attribution must suit the PR audience.
- Suggested code is a short signature or expression, not a patch.

Before presenting, silently check each inline and file-level comment against every style rule. Check the main review for duplicates, settled points, evidence and consistency with the filing. Iterate on wording with the user; keep posting permission separate.

## 4. Post (explicit go-ahead only)

Read `${CLAUDE_PLUGIN_ROOT}/skills/pr-review/references/github-review.md` for anchors, payloads and verification unless its full, unchanged contents are already in context.

Recheck head, target branch and target tip before **each** posting operation, including separate file-level comments:

- **Head or target branch changed:** refresh the snapshot, diff, integration assessment and findings; present the updated draft and filing for a new explicit go-ahead. Remapping anchors alone is insufficient.
- **Only target tip changed:** fetch it, refresh the diff/merge check and inspect relevant changes since the previous tip within Gather's integration scope. Revalidate findings, anchors, filing and coverage. If the draft or recommendation changes, present it for renewed approval; otherwise authorization for the unchanged draft remains valid. Recheck before posting; stop and report a blocker if repeated movement prevents a reliable assessment.

Post only the approved text and filing against the checked head. Use valid diff anchors, include file-level comments in the approved draft, build JSON with a script and verify every posted comment as described in the reference. Report the review link and any re-anchoring.
