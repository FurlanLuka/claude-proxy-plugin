---
name: pr-open
description: Opens pull requests for finished work, one per repo touched, with a description checked against the code, the right target, and sibling PRs linked in rollout order. Use when asked to open, create or put up a PR, or at the end of `pair` or `solo` when the request asked for one. Not for reviewing a PR (`pr-review`) or working an open one (`pr-check`).
---

Runs in the main session. Invoking this skill is the go-ahead to commit the work, push its branch and open the PR. It is not a go-ahead to merge, to mark a draft ready, or to post anywhere else.

Read `${CLAUDE_PLUGIN_ROOT}/docs/prerequisites.md` and check its **PR open and PR check** requirements.

## 1. Find the work

- List every repo the work touched, from the build that just ran or from the working tree. One PR per repo, not one per stage.
- Never open a PR from the default branch: branch first, following the repo's naming.
- Commit only what belongs to the work. Do not sweep in untracked or unrelated files; name anything left behind.

## 2. Follow the repo's way

Before anything else, read what the repo already says about PRs: its own PR skill under `.claude/skills/`, its PR template, CONTRIBUTING, CLAUDE.md. Target branch, title format, labels, draft policy, required sections and preview setup come from there. A repo PR skill does the opening; this skill supplies the checks around it. The defaults below apply only where the repo is silent.

## 3. Make sure it is ready

- **Reviewed at this revision.** Work that came straight out of `pair` or `solo` in this session already is. Anything else, or anything changed since, goes through `${CLAUDE_PLUGIN_ROOT}/references/review-process.md` first, with its fix loop. A PR is not where blocking findings get discovered.
- **Green locally.** Run the checks CI will run, where the repo makes that possible.
- **Merges into the target as it is now.** Fetch the target and check the merge. Resolve conflicts the repo's way before opening, not after.

## 4. Target and stacks

- Target what the repo's policy says. Stacked work targets its immediate base.
- A PR carries only its own change. If a sibling's commits show up in the diff, the base is wrong; fix the base.
- In a stack or a multi-repo change, every description lists the whole set in merge order.

## 5. Write the description from the diff

Write it from the code at the head commit, not from memory of the plan.

- **What and why**, in the user's terms.
- **How it works**, briefly. Link the plan walkthrough page when one exists.
- **How it was verified**: tests added, what QA exercised, and what could not be verified. Take this from the QA report; do not upgrade it.
- **Rollout**: flags, order across repos, what older clients do — from the plan's integration map.
- **Accepted risks** and other big decisions, when there are any.
- **Links**: the ticket if one exists, and the sibling PRs.

Then check every claim against the code or the evidence: "no behavior change", "already live", "behind a flag", any number. A claim that cannot be backed is cut or marked unverified. No secrets and no real person's content, per `security-principles.md`.

## 6. Open

- Push the branch. Force-push only with lease, only to the work's own branch, only when its history was rewritten.
- Open as a draft unless the repo's convention or the user says ready.
- Request the reviewers the user named, or the ones the repo's convention assigns. Do not choose people.
- Apply the repo's labels, including any that trigger a preview.
- Once every PR in the set exists, edit the descriptions so they link each other.

Create a ticket, post to chat or update a doc only when the user asked for it.

## 7. Report

PR links in merge order, each with draft or ready, reviewers requested, and anything left unverified. Name `pr-check` as the way to follow them up.
