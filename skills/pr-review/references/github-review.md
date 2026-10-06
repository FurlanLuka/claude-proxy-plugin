# GitHub review mechanics

Use these commands inside the `pr-review` workflow. Its snapshot, evidence and approval rules apply to every operation below. Substitute the resolved repository, absolute clone/scratch paths and captured commits; `gh api` has no `--repo` flag.

## Capture the snapshot

```bash
gh pr view <N> --repo <owner/repo> --json title,body,author,baseRefName,baseRefOid,headRefName,headRefOid,files,comments,reviews
git -C <clone> fetch origin <baseRefName> pull/<N>/head
```

Confirm the captured commits are available locally, then repeat the metadata read before saving the diff. Refresh the snapshot if either commit or the target branch changed.

```bash
git -C <clone> diff <baseRefOid>...<headRefOid> > <scratchpad>/pr.diff
git -C <clone> show "<headRefOid>:<path>"
git -C <clone> merge-tree --write-tree <baseRefOid> <headRefOid>
git -C <clone> log --oneline <headRefOid>..<baseRefOid> -- <relevant-paths>
```

On a successful merge check, read the returned tree with `git -C <clone> show "<treeOid>:<path>"`. A conflict is not a successful integration check. Use quoted, braced shell variables when substituting commit IDs, e.g. `"${headRefOid}:<path>"`.

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

## Anchor comments

An inline anchor must fall inside a diff hunk, including its context lines; GitHub rejects other lines with 422.

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
