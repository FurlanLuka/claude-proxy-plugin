# Review process

How a code review runs. `pair` and `solo` run it on what they just built and fix what it finds; `pr-review` runs it on a pinned PR snapshot and turns the findings into comments. The standards themselves live in the other references. This file only says which lenses run, what they are given, and what happens to their findings.

## Lenses

| Lens | Run by | Runs when |
| --- | --- | --- |
| Clean code | `proxy:clean-code-architect` | Always |
| Testing | `proxy:test-architect` | Always |
| Correctness | Claude Code's bundled `code-review` skill, invoked from the main session | Any change to code |
| Architecture | `proxy:architect` | A new module, API surface or data shape, or changes to more than a couple of existing files |
| Product | `proxy:product` | Same condition as architecture, or any change to what a user sees or reads |
| Security | The main session, tracing the changed paths end to end | Auth, payments, PII or permissions are touched |

A copy- or config-only change runs clean code and testing, scaled to what there is to check. A caller may ask for more than this table requires; it never runs less.

Use the plugin-scoped advisor names exactly as written. Spawn the advisors in parallel as fresh subagents, never as forks of the main session: a reviewer that inherits the builder's reasoning tends to agree with it. Run correctness alongside them.

## Brief

Reviewers know only what they are handed. Before spawning anything, write one brief file in the session's scratch space, outside every repo, and give its absolute path to each reviewer:

- The ask, in the user's terms.
- Decisions made and why, including what was deliberately left out. Reviewers do not re-raise these without new evidence.
- The approved plan, when there is one.
- The exact change under review, per repo: absolute clone path, base and head commits or a saved diff, and how to read the code at that revision.
- The repo's own conventions: its CLAUDE.md, applicable skills, and the reference paths each advisor needs.
- Points already settled in earlier rounds or existing discussions.

Tell each advisor: read-only, no questions, no subagents; decide from the references; label every finding blocking or non-blocking; flag assumptions and anything it could not verify.

## Correctness

Invoke `code-review` through the Skill tool once per repo touched, with `medium --max-findings 25` and the change as its target: `<base>...<head>` for committed work, no target for the working diff. Its default limit of ten findings is reached on almost every real feature, and what falls off the end is not always the least important.

Never pass `--fix`, `--comment`, `--post` or `ultra`. Use a higher effort level only when the user asks for one.

Require its report to name the repo, the commits reviewed and the code it read, including callers and callees outside the diff. Verify the cited evidence yourself. Discard a mis-scoped result and rerun it against the right change; if that cannot work, report missing correctness coverage rather than a clean review.

Trace the changed paths end to end in the main session too. The lenses do not replace reading the code.

## Verify and triage

No finding is acted on because a reviewer said so.

- Read the code behind every finding. Confirmed → it stands. Unconfirmed → drop it, or keep it as a question.
- Drop harmless deviations from proxy defaults that match the repo's conventions, restatements of decisions listed in the brief, and anything already settled.
- Compare the change with the plan: name anything built that the plan did not ask for, and anything the plan asked for that is missing.
- Label what remains.

**Blocking** — it cannot ship as it is: wrong behaviour or a crash; a break in another repo, an older client, a sibling change or the rollout order; a security problem; required behaviour with no test, or a test that passes for the wrong reason.

**Non-blocking** — everything else: naming, cleanup, comment and doc wording, optional suggestions.

A reviewer's label is a proposal. The main session sets the final one and says so when it changes it.

## Fix loop

For callers that fix what they find. `pr-review` does not fix; its findings become the draft.

- **Blocking:** fix it, rerun the relevant checks, and return the fix and the results to the lens that raised it, continuing that reviewer rather than starting a new one where possible. Repeat until that lens confirms the fix. When a fix changes behaviour, run correctness on the fix as well: fixes introduce their own defects.
- **Non-blocking:** fix once, or skip with a reason. No re-review.
- **Later changes:** code changed after the review — a steer, a QA fix — is a new change. Run the lenses that apply to it on that change alone.

The review is closed when no blocking finding is open on the current revision. Passing tests or an earlier clean pass does not close it.

## Report

- Lenses run, and any skipped with the reason.
- Blocking findings and how each was resolved.
- Non-blocking findings fixed, and those skipped with reasons.
- What could not be verified.
