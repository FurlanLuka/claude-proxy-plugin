---
name: review-pr
description: Review someone else's GitHub pull request the way Jure would — run proxy:review against the PR, verify the findings, draft a concise main review plus inline comments, present the draft locally for inspection, and post it to GitHub only after an explicit go-ahead. Use when asked to "review PR 123", "make a PR review as if I'd do it", "prepare a review for <PR link>", or to draft review comments on a teammate's PR. Not for reviewing your own branch or diff (use /code-review) or for opening a PR.
---

# Review a PR

Four phases: gather → review → present → post. Never post, reply, approve or resolve anything on the PR before the user says to post.

Invoking this skill is the user's request for `proxy:review` and its four advisors.

## 1. Gather

Locate the PR's repo relative to the cwd first:

- **The cwd is a clone of it:** proceed. `gh api` fills `{owner}` and `{repo}` from the current repo.
- **The cwd is a parent directory, and a child directory's `origin` remote is the PR's repo** (a multi-repo workspace): proceed against that child.
  - Run git as `git -C <child>`.
  - Replace `{owner}/{repo}` with the literal owner and repo; the placeholders only resolve when the cwd is a repo.
  - Read the child's CLAUDE.md yourself, and pass paths from its `.claude/skills/` to every specialist.
  - Give subagents absolute paths.
- **Otherwise** (the cwd is a different repo, or no clone of the PR's repo sits below it): stop. Recommend starting a session in the PR's repo, because its CLAUDE.md and skills won't load here and `{owner}/{repo}` would resolve to the wrong repo.

```bash
gh pr view <N> --json title,body,author,baseRefName,headRefName,headRefOid,files,comments,reviews
gh pr diff <N> > <scratchpad>/pr.diff
git fetch origin pull/<N>/head          # then read head files with `git show <headRefOid>:<path>`
gh api graphql -F owner='{owner}' -F repo='{repo}' -F n=<N> -f query='
  query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$n){
    reviewThreads(first:100){nodes{isResolved path line comments(first:50){nodes{author{login} body}}}}}}}'
```

- The working tree is not the PR head. Every line number in the review refers to the head commit (`headRefOid`).
- In zsh, brace the variable: `git show "${SHA}:path"`. Unbraced, `$SHA:s…` is read as a substitution modifier and silently shows the commit instead of the file.
- Read existing threads first. A thread is settled if it's resolved, if the author replied that it's fixed, or if the author declined it with a reason; bots' threads often stay unresolved after a reply. Don't re-raise settled threads unless you have new evidence.
- Check the base branch. Most repos expect `develop`; if unsure, check the repo's CLAUDE.md, CONTRIBUTING.md or README.
- **Simulate the merge.** Green CI and GitHub's "mergeable" can be stale: a base-branch commit landed after the PR's last CI run can make a textually clean merge break type-check or lint (e.g. the same object key added on both sides). Run `git fetch origin <base>` and `git merge-tree --write-tree origin/<base> <headRefOid>`, then list `git log --oneline <headRefOid>..origin/<base> -- <PR files>`. If that log is non-empty, read the merged tree (`git show "${TREE}:<path>"`) where both sides touched, and raise any breakage as a must-fix.
- **Re-review** (the user has reviewed this PR before): take the commit of the user's last review (`.reviews[].commit.oid` from the `gh pr view` output above), save `git diff <thatCommit> <headRefOid>` as the changes since that review, and give it to every specialist alongside the full diff. Tell them which round-1 threads are resolved so they don't re-raise them. Once the findings are in, sort each one as either new code or missed last round; misses are the signal the skill needs tuning.
  - If the reviewed commit isn't an ancestor of the head (`git merge-base --is-ancestor` fails after a rebase or retarget), a plain diff would pull in everything the new base brought. Instead, find the reviewed commit's rebased copy (same commit message, and an empty `git diff <reviewed> <copy> -- <PR files>`), then use `git diff <copy> <headRefOid> -- <PR files>`. Without a clean match (squashed, reworded, or changed in the rebase), use `git range-diff <oldBase>..<reviewed> <newBase>..<headRefOid>`.

## 2. Review

1. Invoke `proxy:context`, then `proxy:review`, scoped to this PR's diff rather than the whole repo. When dispatching its four specialists (product, architect, clean-code-architect, test-architect), give each one, on top of what proxy:review passes:
   - the diff path and the `git show <headRefOid>:<path>` instruction
   - the repo's own skills for the layers the diff touches (from `.claude/skills/`), as paths to read
   - the brief: read-only, no questions, no subagents; decide from the references and flag the decision
2. In parallel, run `/code-review medium <N>` as the correctness lens, local only (never `--comment`, `--post` or `--fix`). Trace the changed paths end to end yourself as well, including callers and callees outside the diff. If the diff touches auth, payments, PII or permissions, add a security pass.
3. **Verify before including.** For every claim you keep, read the code yourself. Where a claim depends on data (payload shapes, affected rows), check it against production data if you have read access to it, e.g. a warehouse mirror, an analytics store or logs. Read-only queries only. A confirmed claim becomes a statement. An unconfirmable one becomes a question to the author, or is dropped.
4. **Triage.** proxy:review's category report is raw material, not the output. Judge findings against the repo's own conventions: drop a divergence from a proxy default when the codebase itself consistently follows the PR's pattern. Keep what the author should act on. Drop anything low-value: analytics-only side effects, ticket-level product concerns, and observations the PR description already covers.

## 3. Present locally

Show the draft in chat. Don't post it.

- **Proposed filing:** end the draft with one explicit line, `Proposed filing: Approve` or `Proposed filing: Reviewed with comment` (GitHub `APPROVE` / `COMMENT`), plus a one-sentence reason. Never use `REQUEST_CHANGES` unless the user asks for it.
  - **Approve** when the logic is sound and what's left is tests, cleanup or nits the author can fix after approval. Nothing to fix at all → say so plainly and propose Approve.
  - **Reviewed with comment** when the PR's core behaviour is wrong or unproven (a confirmed bug in what the PR exists to do), when it can't do its job as written, or when approving would enable a bad merge (land order, a prerequisite PR still unreviewed).
- **Main review:** lead with what needs fixing. Keep praise to a short clause or omit it; don't open with a compliment. Then bullets for the must-address items only. State each ask directly ("Please retarget `develop`.") with no alternatives, precedent lists or justification the author doesn't need. When a bullet has an inline comment with details, say "Details and a fix in the provided inline comment."
  - Match each ask's wording to its weight. When filing Approve, phrase optional asks as confidence-raisers ("a develop merge and CI re-run would confirm the combination"), not as preconditions ("please merge develop before merging"). Directive wording on an approval contradicts the approval.
- **Inline comments:** a numbered list, each with `path:line` and the exact comment text.
- **Coverage:** close with what you checked, what you couldn't verify and why, and what you deliberately left out.

### Comment style

- Concise, but without losing context the author needs to act. Cut prose, not facts.
- Start with `Nit: ` only for genuine nits (naming, comment wording, test tidiness). Everything else goes straight into the point, with no label.
- Shape each comment as problem → concrete case or impact → fix, with blank lines between parts when it runs longer than two sentences.
- Write for a human who wasn't in this session: spell out the scenario instead of using shorthand coined during the review, name the actual function or test, and quote a stale comment instead of pointing at it.
- Give evidence when it's what makes the point credible, e.g. "(checked against the production events table)".
- Suggested code is a short signature or expression, not a patch.

Iterate with the user until they approve the wording.

## 4. Post (only on explicit go-ahead)

1. Re-check `headRefOid`. If the head moved, re-map the line numbers, or tell the user before posting.
2. Every inline anchor must be a line inside a diff hunk (changed lines plus their context); GitHub rejects anything else with a 422.
   - `side: "RIGHT"` with head line numbers for added, changed or context lines.
   - `side: "LEFT"` with base line numbers for a deleted line, or for the old version of a changed line.
   - For a line outside every hunk, anchor on the nearest diff line and quote the target line in the comment. If no diff line in that file is close enough to make sense, post a file-level comment instead. It can't go in the review batch, so post it separately with `gh api -X POST repos/{owner}/{repo}/pulls/<N>/comments -f body=... -f commit_id=<headRefOid> -f path=<path> -f subject_type=file`.
3. Build the payload with a script, not shell-escaped JSON, and post it as one review:

```python
payload = {
    "commit_id": HEAD_SHA,
    "event": EVENT,  # "APPROVE" or "COMMENT": the filing the user confirmed
    "body": MAIN_REVIEW,
    "comments": [{"path": p, "line": n, "side": side, "body": text} for p, n, side, text in COMMENTS],
}
json.dump(payload, open(f"{scratchpad}/review.json", "w"))
```

```bash
gh api -X POST repos/{owner}/{repo}/pulls/<N>/reviews --input <scratchpad>/review.json --jq '"\(.id) \(.state) \(.html_url)"'
```

4. Verify the anchors with `gh api repos/{owner}/{repo}/pulls/<N>/comments --paginate --jq '.[] | select(.pull_request_review_id == <ID>) | "\(.path):\(.line)"'`. The per-review comments endpoint omits `line` (it reads as `null`), so don't use it for this check.
5. Report the review link and any comment that had to be re-anchored.
