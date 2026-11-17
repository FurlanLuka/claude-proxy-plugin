---
name: pr-check
description: Checks your own open pull requests and gets them mergeable. Reports CI, reviews, unresolved threads and conflicts for each, then fixes what it can — addresses review comments, repairs CI, resolves conflicts, restacks, replies and re-requests review. Use on "check my PRs", "any reviews yet", "address the comments", "fix the conflicts", "is it ready to merge". Not for someone else's PR (`pr-review`). Never merges unless asked.
---

Runs in the main session. Status first, then fixes. Invoking this skill is the go-ahead to push fixes to the user's own PR branches and to post factual replies about those fixes. It is not a go-ahead to merge, approve, dismiss a review, mark a draft ready, or argue with a reviewer in the user's name.

Read `${CLAUDE_PLUGIN_ROOT}/docs/prerequisites.md` and check its **PR open and PR check** requirements. Read `${CLAUDE_PLUGIN_ROOT}/skills/pr-review/references/github-review.md` for the snapshot and thread-retrieval commands; its posting rules belong to `pr-review` and do not apply here.

## 1. Scope

The PRs the user named. Otherwise the user's open PRs for the current branch and its stack, in the repos under the working directory. Confirm each is the user's own; anything else is a job for `pr-review`.

## 2. Status — read-only

For each PR, against the live head and the live target:

- **CI**: each failing check and what failed in it.
- **Reviews**: the decision, who approved, who is still pending, and whether an approval predates later commits.
- **Threads**: every unresolved thread, with all its replies read, from people and from bots, and compared with the code at the current head. A thread is settled only when its fix is verified in that code or the reviewer accepted the explanation. An author reply alone settles nothing: the reviewer may have been right, and may have shown it since.
- **Mergeability**: conflicts with the target as it is now.
- **Stack**: position, and whether its base moved or merged.
- **Description**: whether it still matches the code.

Present one table in merge order, and under it what each PR needs and from whom. If the user only asked for status, stop here.

## 3. Fix

Work on each PR's branch without disturbing other worktrees or uncommitted work; use a scratch worktree when the branch is not the one checked out.

- **Review comments.** Verify each against the code, as `${CLAUDE_PLUGIN_ROOT}/references/review-process.md` requires for any finding. Right → fix it. Wrong, or really a product or scope decision → change nothing and draft a reply for the user. Bot comments get the same bar and no deference.
- **CI.** Read the failing log and fix the cause. Rerun without a change only when the evidence says the failure is infrastructure or a known flake, and say so.
- **Conflicts and moved bases.** Merge or rebase the repo's way. When a lower PR in a stack has merged, retarget the next one and restack upward from the bottom. Regenerate generated files rather than merging them by hand.
- **Fixes are new changes.** Run the lenses the review process applies to later changes on them, and rerun the tests, before pushing.
- **Push.** Force only with lease, only on the user's own PR branches, only when history was rewritten.

## 4. Close the loop on GitHub

Done without asking, for what was fixed:

- Reply on each thread with what changed and the commit that changed it. Write for the reviewer: no session shorthand.
- Resolve the threads that were fixed. Leave open any thread that still needs the reviewer's judgment.
- Re-request review from reviewers whose comments were addressed.
- Bring the description up to date when behavior changed. It describes the PR as it is now, not its history.

Held for the user's go-ahead:

- Any reply that declines a request, pushes back, or answers a product question. Show the drafts together.
- Merging. If the user said to merge when ready, merge in order once each PR is approved and green, rechecking the head and the target before each.
- Marking a draft ready, unless that was the request.

Under `solo`, technical calls are yours as usual; the held replies stay held, because they speak for the user.

## 5. Re-read before reporting

The status from step 2 describes the revision before the fixes. A push starts new checks and can invalidate an approval, and the target can move while the fixes are made. So after the last write, read again, for each PR, at the same moment:

- its head, its checks and its review decision, and
- its live target and whether that head merges into it cleanly.

Do this for every PR that was changed, and for every PR above one in a stack: pushing a lower branch changes the target of the PR on top of it even when that PR's own head did not move.

Report what was read, for that head against that target. Checks still running mean the PR is waiting on CI, not ready. A conflict found here goes back to step 3.

## 6. Report

Decisions that need the user come first, with the drafted replies. Then per PR: what was fixed, what was replied, and what it is waiting on — a named reviewer, CI, or the user. End with what is ready to merge, in order. A PR is ready only if its current head is approved, green and merges cleanly into its live target, all as read in step 5.
