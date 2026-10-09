# GitHub review mechanics

Use these commands inside the `pr-review` workflow. Its snapshot, evidence and approval rules apply to every operation below. Substitute the resolved repository, absolute clone/scratch paths and captured commits; `gh api` has no `--repo` flag.

## Capture the snapshot

Read PR metadata, then fetch the target branch separately so its fetched tip is unambiguous, even with custom remote-tracking configuration:

```bash
gh pr view <N> --repo <owner/repo> --json title,body,author,baseRefName,baseRefOid,headRefName,headRefOid,files,comments,reviews
git -C <clone> fetch origin "refs/heads/<baseRefName>"
targetTipOid=$(git -C <clone> rev-parse --verify "FETCH_HEAD^{commit}")
git -C <clone> fetch origin "refs/pull/<N>/head"
```

Record `targetTipOid` before the head fetch overwrites `FETCH_HEAD`. Confirm the captured head is available locally. GitHub’s `baseRefOid` is PR-associated metadata and can lag behind the actual target branch; do not substitute it for the fetched tip.

Recheck head, target name and live tip in one response during gathering and immediately before every posting operation:

```bash
gh api graphql -f owner=<owner> -f repo=<repo> -F n=<N> -f query='
  query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$n){
    baseRefName headRefOid baseRef{target{oid}}}}}'
```

`baseRef.target.oid` is the live target tip. Compare it with `targetTipOid`, not `baseRefOid`. If the ref is missing or movement prevents a consistent snapshot, report the blocker.

Compute the review base from the captured live tip and head:

```bash
reviewBaseOid=$(git -C <clone> merge-base <targetTipOid> <headRefOid>)
git -C <clone> diff <reviewBaseOid>...<headRefOid> > <scratchpad>/pr.diff
gh pr diff <N> --repo <owner/repo> > <scratchpad>/github-pr.diff
git -C <clone> show "<headRefOid>:<path>"
git -C <clone> merge-tree --write-tree <targetTipOid> <headRefOid>
git -C <clone> log --oneline <headRefOid>..<targetTipOid> -- <relevant-paths>
```

Compare the saved files/changes with GitHub’s diff; recheck the snapshot after retrieving it. Different context widths or diff formatting may be explained only after confirming the same paths and changed content; a content mismatch remains a blocker. Use `github-pr.diff` for posting anchors even when the local diff has different hunk boundaries. A target update can change the merge base, so recompute the diff as well as the integration check.

On a successful merge check, read its returned tree with `git -C <clone> show "<treeOid>:<path>"`; conflicts are not a successful check. Before repinning a moved target, save the current `targetTipOid` as `previousTargetTipOid`. Then inspect `git -C <clone> diff <previousTargetTipOid> <targetTipOid> -- <relevant-paths>` so removed changes from a target rewrite are visible.

Use quoted, braced shell variables, e.g. `"${headRefOid}:<path>"`. In zsh, an unbraced `$SHA:s…` is parsed as a substitution modifier and can silently inspect the commit instead of the intended file.

## Read review threads

Fetch every thread page:

```bash
gh api graphql --paginate -f owner=<owner> -f repo=<repo> -F n=<N> -f query='
  query($owner:String!,$repo:String!,$n:Int!,$endCursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$n){
    reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}
      nodes{id isResolved path line comments(first:50){commentPageInfo:pageInfo{hasNextPage endCursor}
        nodes{author{login} body}}}}}}}'
```

This paginates threads, not their nested replies. The nested `pageInfo` is aliased as `commentPageInfo` so `gh --paginate` follows the outer connection. For each thread with `comments.commentPageInfo.hasNextPage`, fetch the remaining replies, starting from its returned comment cursor:

```bash
gh api graphql --paginate -f thread=<thread-id> -f endCursor=<comments-end-cursor> -f query='
  query($thread:ID!,$endCursor:String){node(id:$thread){... on PullRequestReviewThread{
    comments(first:50,after:$endCursor){pageInfo{hasNextPage endCursor}
      nodes{author{login} body}}}}}'
```

Classify threads only after reading all replies, including later author fixes or reasoned declines.

## Select a re-review baseline

Fetch all reviews and review comments; the metadata summary may not contain the full history:

```bash
gh api repos/<owner>/<repo>/pulls/<N>/reviews --paginate
gh api repos/<owner>/<repo>/pulls/<N>/comments --paginate
```

Filter reviews by the selected account’s `user.login` and a non-null `submitted_at`. A substantive review has a non-blank body, an `APPROVED`, `CHANGES_REQUESTED` or `DISMISSED` state, or at least one top-level inline comment. Join comments on `pull_request_review_id`; top-level comments have no `in_reply_to_id`. An empty-body `COMMENTED` record containing only replies, or no comments, is not a baseline. An empty-body approval, dismissed review or inline-only review still counts. Dismissal invalidates a decision, not the historical record of which commit was reviewed; it does not establish current approval.

Choose the latest eligible `submitted_at` and its `commit_id`. If the commit is missing locally, try `git -C <clone> fetch origin <commit_id>` and confirm the object is available; fetching by SHA may fail. Use a delta only when that commit is available and an ancestor of the captured head; otherwise disclose the limitation and review the full pinned diff. Do not infer a rebased copy: `range-diff` heuristically pairs commits, and today's target cannot reliably reconstruct the original reviewed series after retargeting or target-history rewrites. New-versus-missed classification belongs in Coverage only when the baseline supports it.

## Anchor comments

Validate every inline comment's path, side and line against the saved `github-pr.diff` for the checked snapshot. Its anchor must fall inside a GitHub diff hunk, including its context lines; GitHub rejects other lines with 422. Local diff hunk boundaries are not authoritative. Refresh GitHub's diff and recheck the snapshot after any head, target branch or target tip movement.

- `side: "RIGHT"`: head line numbers for added, changed or context lines.
- `side: "LEFT"`: the diff's old-side line numbers for deletions or the old version of a changed line.
- Outside a hunk: use a nearby diff line and quote the target line if that makes sense. Otherwise draft a file-level comment and post it separately.

Include file-level comments and any changed anchors in the locally approved draft. Recheck the snapshot under the skill's posting rules before every write, including separate comments.

## Submit and verify

Build JSON with a script instead of shell-escaped JSON. Use the checked head and the filing the user confirmed:

```python
import json

payload = {
    "commit_id": HEAD_SHA,
    "event": EVENT,
    "body": MAIN_REVIEW,
    "comments": [{"path": p, "line": n, "side": side, "body": text} for p, n, side, text in COMMENTS],
}
with open(f"{scratchpad}/review.json", "w") as output:
    json.dump(payload, output)
```

`EVENT` is `APPROVE` or `COMMENT`, unless the user explicitly requested `REQUEST_CHANGES`. Submit one review batch:

```bash
gh api -X POST repos/<owner>/<repo>/pulls/<N>/reviews --input <scratchpad>/review.json --jq '"\(.id) \(.state) \(.html_url)"'
```

For each approved file-level comment, build a separate JSON payload containing `body`, `commit_id`, `path` and `subject_type: "file"`. After rechecking the snapshot, post it separately:

```bash
gh api -X POST repos/<owner>/<repo>/pulls/<N>/comments --input <scratchpad>/file-comment.json
```

Verify the batch's anchors using the PR-wide comments endpoint:

```bash
gh api repos/<owner>/<repo>/pulls/<N>/comments --paginate --jq '.[] | select(.pull_request_review_id == <ID>) | "\(.path):\(.side):\(.line)"'
```

The per-review comments endpoint omits `line`; do not use it for anchor verification. Check separately posted file-level comments by their returned IDs and paths, outside the review batch. Report the review link and any re-anchoring.
