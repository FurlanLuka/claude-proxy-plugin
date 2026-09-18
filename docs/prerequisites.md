# Prerequisites

Check only the requirements for the active workflow. Missing capabilities do not authorize installations, permission changes, or a different hosting destination; handle setup separately with user approval.

## Planning and implementation

`proxy:pair` and `proxy:qa-plan` require an interactive main session with plan-mode approval and the target repository's existing development/test tooling. `pair` also requires the advisors selected for its reviews.

When the interactive session or plan-mode approval tools are unavailable, report the blocked workflow before drafting or implementing. Describing a headless environment or saying "you decide the implementation details" does not waive the build or QA approval gate. A plain-text approval cannot replace the required plan-mode tools.

When reporting this blocker, identify the missing capabilities and how to restore them; do not offer to waive approval or draft the blocked plan as a separate document.

Follow `pair`'s infra-gap procedure, including explicit user overrides, for missing project infrastructure. Follow `qa-plan`'s reporting rules for cases it cannot exercise.

`proxy:solo` has the same requirements plus `jq` or `python3` on the machine. Its approvals are answered by the plugin's hooks rather than by the user (invoking the skill arms a per-session marker; `ExitPlanMode` is approved while it exists), but the plan-mode tools must still exist and the hooks must be loaded; when they are not, the normal approval dialog appears and the run waits for it. A non-interactive session blocks `solo` exactly as it blocks `pair`.

## Plan walkthrough

Check artifact prerequisites only when the structural gate requires a walkthrough or the user requests one directly.

Before authoring, require:

- Claude Code's built-in `artifact-design` and `artifact-diagramming` skills. Load both; see [Artifact skill setup](#artifact-skill-setup).
- Artifact publishing in the current session, with permission to create a page and update it at the same URL.
- Access to the real code needed to verify the before-state.

If a requirement is missing, report it and stop before authoring or publishing. In `pair`, handle it as an infra gap before presenting the build plan. Missing capabilities do not make the structural gate skip; only an explicit user instruction can waive the required step.

## PR walkthrough

Require artifact publishing. Updating an existing plan page also requires access to it; when no plan page exists, creating one requires both authoring skills above.

Before exporting or uploading, verify the target repository's hosting destination, upload procedure, credentials, and permitted audience, plus GitHub access to update the PR and existing tools to export and inspect SVGs. Follow repository policy for public engineering material; never publish PII or customer content publicly.

If hosting, access, or audience is unknown, report the gap and stop before upload or PR edits. Preserve the existing page and PR description; do not create a replacement artifact as a workaround.

## Artifact skill setup

Both skills are built into Claude Code; no extra plugin installation is needed. See Anthropic's [built-in artifact design guidance](https://code.claude.com/docs/en/artifacts#improve-the-visual-design).

Artifact publishing requires `/login` with an eligible Claude account and artifacts enabled under session and organization policy. API-key and cloud-provider sessions cannot publish. See the [availability requirements](https://code.claude.com/docs/en/artifacts#availability) and [organization settings](https://code.claude.com/docs/en/artifacts#enable-or-disable-artifacts).

Check the session's launch configuration too: `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` disables artifacts by default. Artifact settings, `CLAUDE_CODE_DISABLE_ARTIFACT=1`, or an `Artifact` permission denial can also disable them; see [Disable artifacts](https://code.claude.com/docs/en/artifacts#disable-artifacts). Use a normal interactive session for the capability check below; the plugin eval runner disables artifacts.

Verify skill access through the Skill tool; slash-command visibility alone is insufficient. Ask Claude:

```text
Load the built-in artifact-design and artifact-diagramming skills through
the Skill tool. Report whether each loads successfully. Do not create,
publish, or modify any artifact or install anything.
```

If loading fails, report the skill name and error, then check the requirements above and whether Claude Code [needs updating](https://code.claude.com/docs/en/setup#update-claude-code). Follow the walkthrough's blocking rule instead of substituting a similarly named third-party skill. Successful skill loading does not prove publishing permission or same-URL updates.
