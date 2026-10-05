---
name: review-pr
description: Review someone else's GitHub pull request using proxy's advisors and a correctness review. Verify findings, present a concise main review and inline comments locally, and post only after explicit approval. Use when asked to review a PR, prepare a review for a PR link, or draft comments on a teammate's PR. Not for reviewing your own branch or diff (use /code-review) or for opening a PR.
---

# Review a PR

Four phases: gather → review → present → post. Never post, reply, approve or resolve anything on the PR before the user says to post.

Invoking this skill is the user's request for `proxy:review` and its four advisors.

Read the required references unless their full, unchanged contents are already available in the current context. Do not assume they were loaded by a startup hook, parent agent, or previous session.

Before gathering, check the PR review requirements in `${CLAUDE_PLUGIN_ROOT}/docs/prerequisites.md`. The main session owns gathering, verification and posting; the advisors retain their read-only execution boundaries.

## 1. Gather

Resolve the repository and PR number from the supplied URL. For a bare number, use the current repository; in a parent workspace, ask which repository if the request does not identify it. Locate that repository's clone relative to the cwd:

- **The cwd is a clone of it:** proceed against that clone.
- **The cwd is a parent directory, and a child directory's `origin` remote is the PR's repo** (a multi-repo workspace): proceed against that child.
- **Otherwise** (the cwd is a different repo, or no clone of the PR's repo sits below it): stop. Recommend starting a session in the PR's repository so the review uses its code and local guidance.

In both supported cases, run Git as `git -C <clone>` and every `gh pr` command with `--repo <owner/repo>`. Use literal owner/repo values in API endpoints and GraphQL variables; do not depend on cwd placeholders. Read the clone's CLAUDE.md when present, pass applicable paths from its `.claude/skills/` to every specialist, and give subagents absolute paths.

Capture `baseRefName`, `baseRefOid` and `headRefOid`. The PR's actual target is authoritative: derive the diff from that base and head, not from an assumed default branch or the local upstream. Fetch the target branch and PR head, confirm the captured commits exist locally, and re-check the metadata before reviewing. If either commit or the target changed during gathering, refresh the snapshot; if it cannot be captured consistently, report the blocker.

```bash
gh pr view <N> --repo <owner/repo> --json title,body,author,baseRefName,baseRefOid,headRefName,headRefOid,files,comments,reviews
git -C <clone> fetch origin <baseRefName> pull/<N>/head
git -C <clone> diff <baseRefOid>...<headRefOid> > <scratchpad>/pr.diff
gh api graphql --paginate -f owner=<owner> -f repo=<repo> -F n=<N> -f query='
  query($owner:String!,$repo:String!,$n:Int!,$endCursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$n){
    reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}
      nodes{id isResolved path line comments(first:50){commentPageInfo:pageInfo{hasNextPage endCursor}
        nodes{author{login} body}}}}}}}'
```

- The thread query paginates threads, not each nested comment connection. Its nested page information is aliased as `commentPageInfo` so `gh --paginate` follows only the outer `pageInfo`. For every thread whose `comments.commentPageInfo.hasNextPage` is true, fetch its remaining comment pages before classifying it. Supply that connection's returned cursor as the initial `endCursor` below; `--paginate` follows subsequent pages:

```bash
gh api graphql --paginate -f thread=<thread-id> -f endCursor=<comments-end-cursor> -f query='
  query($thread:ID!,$endCursor:String){node(id:$thread){... on PullRequestReviewThread{
    comments(first:50,after:$endCursor){pageInfo{hasNextPage endCursor}
      nodes{author{login} body}}}}}'
```

- The working tree is not the PR head. Inspect code with `git -C <clone> show <headRefOid>:<path>`. Use head line numbers for RIGHT-side comments and the diff's old-side line numbers for LEFT-side comments.
- In zsh, brace the variable: `git -C <clone> show "${SHA}:path"`. Unbraced, `$SHA:s…` is read as a substitution modifier and silently shows the commit instead of the file.
- Read existing threads first. A thread is settled if it's resolved, if the author replied that it's fixed, or if the author declined it with a reason; bots' threads often stay unresolved after a reply. Don't re-raise settled threads unless you have new evidence.
- **Simulate the merge against the captured target.** Green CI and GitHub's "mergeable" can be stale: a base-branch commit landed after the PR's last CI run can make a textually clean merge break type-check or lint (e.g. the same object key added on both sides). Run `git -C <clone> merge-tree --write-tree <baseRefOid> <headRefOid>`. On success, capture the returned tree ID; on conflict, report the conflict rather than treating the tree as mergeable. List `git -C <clone> log --oneline <headRefOid>..<baseRefOid> -- <PR files>`, then inspect the merged tree (`git -C <clone> show "${TREE}:<path>"`) where both sides touched. Raise confirmed integration breakage as a must-fix; a clean text merge alone does not prove type-check or lint passes.
- **Re-review** (the user has reviewed this PR before): select the user's latest submitted review by author and submission time. Take its commit (`.reviews[].commit.oid`), save `git -C <clone> diff <thatCommit> <headRefOid>` as the changes since that review, and give it to every specialist alongside the full diff. Fetch the prior commit if needed; if it cannot be retrieved, report the missing history and review the full pinned diff without claiming a precise delta. Tell specialists which round-1 threads are resolved so they don't re-raise them. Once the findings are in, sort each one as either new code or missed last round; misses are the signal the skill needs tuning.
  - If the reviewed commit isn't an ancestor of the head (`git -C <clone> merge-base --is-ancestor` fails after a rebase or retarget), a plain diff would pull in everything the new base brought. Instead, find the reviewed commit's rebased copy (same commit message, and an empty `git -C <clone> diff <reviewed> <copy> -- <PR files>`), then use `git -C <clone> diff <copy> <headRefOid> -- <PR files>`. Without a clean match, use `git -C <clone> range-diff <oldBase>..<reviewed> <newBase>..<headRefOid>` when both historical bases are known; otherwise disclose the limitation and use the full pinned diff.

## 2. Review

1. Invoke `proxy:context`, then `proxy:review`, scoped to this PR's diff rather than the whole repo. When dispatching its four specialists (product, architect, clean-code-architect, test-architect), give each one, on top of what proxy:review passes:
   - the clone's absolute path, pinned base/head commits, diff path and the `git -C <clone> show <headRefOid>:<path>` instruction
   - the repo's own skills for the layers the diff touches (from `.claude/skills/`), as paths to read
   - the brief: read-only, no questions, no subagents; decide from the references and flag the decision
2. In parallel, invoke the bundled `code-review` skill with `medium` and a target brief containing the absolute saved diff path, clone path and `<baseRefOid>...<headRefOid>`. Require `git -C <clone>` inspection of that snapshot as the correctness lens. Local only: never `--comment`, `--post` or `--fix`. The working tree, default branch/upstream diff and a bare PR number from the parent workspace are not the review target. Verify retained findings against the pinned head, tracing callers and callees outside the diff as well. If the diff touches auth, payments, PII or permissions, add a security pass against the same snapshot.
3. **Verify before including.** For every claim you keep, read the code yourself. Where a claim depends on data (payload shapes, affected rows), check it against sources you are authorized to read, such as a warehouse mirror, analytics store or logs. Read-only queries only. Keep credentials, PII, customer content and raw sensitive records out of the draft and posted comments; summarize only evidence appropriate for the PR's audience. A confirmed claim becomes a statement. An unconfirmable one becomes a question to the author, or is dropped.
4. **Triage.** proxy:review's category report is raw material, not the output. Judge findings against the repo's own conventions: drop a divergence from a proxy default when the codebase itself consistently follows the PR's pattern. Keep what the author should act on. Drop observations only when their impact and actionability are low; analytics changes and issues acknowledged in the PR description still warrant findings when they affect user, business, compliance or operational behavior. Leave unrelated ticket-level product decisions out.

## 3. Present locally

Show the draft in chat. Don't post it.

- **Proposed filing:** end the draft with one explicit line, `Proposed filing: Approve` or `Proposed filing: Reviewed with comment` (GitHub `APPROVE` / `COMMENT`), plus a one-sentence reason. Never use `REQUEST_CHANGES` unless the user asks for it.
  - **Approve** when the logic is sound and what's left is tests, cleanup or nits the author can fix after approval. Nothing to fix at all → say so plainly and propose Approve.
  - **Reviewed with comment** when the PR's core behaviour is wrong or unproven (a confirmed bug in what the PR exists to do), when it can't do its job as written, or when approving would enable a bad merge (land order, a prerequisite PR still unreviewed).
- **Main review:** lead with what needs fixing. Keep praise to a short clause or omit it; don't open with a compliment. Then bullets for the must-address items only. State each ask directly ("Please preserve the caller's tenant scope.") with no alternatives, precedent lists or justification the author doesn't need. When a bullet has an inline comment with details, say "Details and a fix in the provided inline comment."
  - Match each ask's wording to its weight. When filing Approve, phrase optional asks as confidence-raisers ("a target-branch merge and CI re-run would confirm the combination"), not as preconditions ("please update the branch before merging"). Directive wording on an approval contradicts the approval.
- **Inline comments:** a numbered list, each with `path:line` and the exact comment text.
- **Coverage:** state what you checked, what you couldn't verify and why, and what you deliberately left out before the final proposed-filing line.

### Comment style

- Concise, but without losing context the author needs to act. Cut prose, not facts.
- Start with `Nit: ` only for genuine nits (naming, comment wording, test tidiness). Everything else goes straight into the point, with no label.
- Shape each comment as problem → concrete case or impact → fix, with blank lines between parts when it runs longer than two sentences.
- Write for a human who wasn't in this session: spell out the scenario instead of using shorthand coined during the review, name the actual function or test, and quote a stale comment instead of pointing at it.
- Give evidence when it's what makes the point credible, e.g. "(checked against the production events table)".
- Suggested code is a short signature or expression, not a patch.

Iterate with the user until they approve the wording.

## 4. Post (only on explicit go-ahead)

1. Re-check `headRefOid`, `baseRefName` and `baseRefOid` for the explicit repository. If the head, target or target tip changed, do not post the approved draft. Refresh the snapshot, diff, merge assessment and findings; inspect the changes since the reviewed head and revalidate retained comments. Present the refreshed draft with its filing and obtain an explicit go-ahead again before posting. Remapping line numbers alone is insufficient.
2. Every inline anchor must be a line inside a diff hunk (changed lines plus their context); GitHub rejects anything else with a 422.
   - `side: "RIGHT"` with head line numbers for added, changed or context lines.
   - `side: "LEFT"` with base line numbers for a deleted line, or for the old version of a changed line.
   - For a line outside every hunk, anchor on the nearest diff line and quote the target line in the comment. If no diff line in that file is close enough to make sense, include a file-level comment in the locally approved draft, then post it separately with `gh api -X POST repos/<owner>/<repo>/pulls/<N>/comments -f body=... -f commit_id=<headRefOid> -f path=<path> -f subject_type=file`. Re-check the snapshot before each separate posting operation too.
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
gh api -X POST repos/<owner>/<repo>/pulls/<N>/reviews --input <scratchpad>/review.json --jq '"\(.id) \(.state) \(.html_url)"'
```

4. Verify inline anchors with `gh api repos/<owner>/<repo>/pulls/<N>/comments --paginate --jq '.[] | select(.pull_request_review_id == <ID>) | "\(.path):\(.side):\(.line)"'`. The per-review comments endpoint omits `line` (it reads as `null`), so don't use it for this check. Verify separately posted file-level comments by their returned IDs and paths; they are outside the review batch.
5. Report the review link and any comment that had to be re-anchored.
