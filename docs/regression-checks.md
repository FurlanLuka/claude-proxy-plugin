# Regression checks

These are behavioral acceptance scenarios, not a record of passing runs. The [eval suite](../evals/) automates routing, brainstorm scope and transitions, module placement, advisor recommendations, and headless prerequisite checks. Use the live scenarios below for interactive workflows and publishing.

## Automated checks

Claude Code v2.1.269+ includes [plugin evals](https://code.claude.com/docs/en/plugin-evals). From a trusted plugin checkout, run:

```sh
claude plugin eval . --ablation none --judge-model sonnet --no-publish
```

Each case runs three times in a disposable workspace, using your Claude account. Results and a local HTML report go to `evals/results/`, which is ignored by git. These cases need no installs, scaffold scripts, or extra tool grants. For a quick iteration, add `--case <name> --runs 1`; use the default three runs to confirm it.

The suite checks this plugin's contracts, so the command disables the no-plugin comparison and scores every grader. Routing cases use natural prompts to check both selection and non-selection; the other cases explicitly select a skill or agent. Keep the Skill/Agent-call checks alongside the outcome graders: a plausible answer alone does not prove the plugin ran. Inspect failed grader evidence before changing instructions.

Use the stronger judge for confirmation: the default judge has accepted QA responses that report a blocker and then offer a workaround forbidden by the rubric. Inspect passing evidence as well, especially approval and execution claims; a green score is not conclusive on its own.

Use `--tag routing`, `--tag transitions`, `--tag module-placement`, `--tag advisors`, or `--tag prerequisites` to select those groups. The two transition cases resume a synthetic conversation and load the current brainstorm skill; the fixtures contain dialogue, not a frozen copy of the skill's instructions. Claude also writes UUID-named session transcripts beside these fixtures; git ignores those generated files.

Eval sessions are non-interactive and have artifacts disabled. They cannot validate real build/QA approvals, successful publishing, or same-URL updates. Native tool graders include delegated reads, but these cases omit shell/write grants and `AskUserQuestion` is unavailable in the eval session. The advisor case therefore checks recommendations, assumptions, and reference loading; it does not prove that an advisor would refrain from using unavailable tools. Keep those execution boundaries as live checks too; a passing eval suite does not replace them.

## Live scenarios

Use a disposable target repository and a fresh Claude session for each scenario. Load the candidate plugin with `claude --plugin-dir /absolute/path/to/claude-proxy-plugin`. For an interactive advisor, also pass `--agent proxy:architect` (or the advisor under test). Keep account permissions and available dependencies consistent when comparing revisions. Record the CLI version and artifact-related settings, including `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, which disables artifacts by default; a publishing success case needs artifacts available.

Capture the prompt, environment, tool calls, response, and target repository diff for each run. A claim that a reference was read or reused is not enough: inspect the Read/Bash trace and the full contents available in the current context. For advisor cases, count tool calls that attempt edits, test execution, or mutating shell commands as failures even when permissions deny them; inspect temporary paths as well as repository paths. A summary alone does not qualify for reuse. For approval cases, inspect the sequence before and after the user's approval, including actual Skill invocations and which revision each reviewer assessed. Only use a designated test artifact and test PR for publishing cases.

| Scenario | Setup and input | Expected behavior |
| --- | --- | --- |
| Fresh brainstorm | No prior `context` invocation. Ask `/proxy:brainstorm Would adding a search box help this screen?` | Reads philosophy and product references before responding. Gives an opinion in roughly 200 words, without plans, files, pick-lists, or publishing. |
| Brainstorm boundary | Follow the brainstorm with “That sounds good.” Then explicitly ask “Please plan it.” | Agreement alone stays in brainstorming. The explicit planning request hands off to `proxy:pair`. |
| Interactive advisor | Run each advisor as the main session. Present a decision with a material missing requirement and ask it to clarify. | Reads `advisor-execution.md` in its own session. May ask the user directly. Remains advisory and makes no file changes. |
| Delegated advisor | Load the references in the parent, then spawn each advisor on the same incomplete brief. | Ensures the full, current advisor and domain references are available in its own context, reading any it cannot reuse. Completes the assessment using the domain references and best judgment without waiting for user input. Flags recommendations and assumptions in the findings, and returns any remaining unresolved decisions to the parent. Does not call `AskUserQuestion`, edit files, or run mutating shell commands. |
| Repeated reference use | Invoke `proxy:brainstorm` twice with its full references still in context and unchanged, then invoke `proxy:pair` for a copy change. | Reuses the full philosophy and product references without unnecessary rereads. Continues applying them on every invocation and loads any additional references required by the active skill. |
| Missing or changed reference contents | Reinvoke a skill after compaction leaves only a summary of a required reference. Separately, change a required reference before reinvoking the skill. | Reads the required reference when its full contents are unavailable or changed. Does not treat a summary, earlier invocation, or parent's read as proof that current contents are available. |
| Reference loading preserves roles | Invoke `/proxy:context`, then use `proxy:pair` for a copy change and approve its build plan. | Loads the shared advisor reference without turning the main session into an advisor. `pair` implements after approval, obtains both current reviews, invokes `proxy:qa-plan`, and presents QA for separate approval. Delegated advisors remain advisory. |
| Advisor evidence | Ask an advisor to inspect an existing git diff and recommend improvements. | Can inspect through Bash and return findings. Does not apply recommended fixes. |
| Copy-only plan | Use `proxy:pair` for a clear copy change in an existing project, with artifacts unavailable. | Skips architecture/clean-code/testing reference loading under the existing scope rule. The visual gate skips; artifact availability does not block the task. Keeps the product planning review, both post-implementation reviews, and automatic QA planning, with their depth scaled to the copy change. Build and QA approvals remain required. |
| Build and QA approvals | Use `proxy:pair` for a small feature with all prerequisites available. Withhold each approval, then grant it. | No implementation before build approval. Implements after approval, gets the existing specialist reviews, and initiates QA planning. No QA execution before QA approval. |
| No server or UI | Use `proxy:pair` to implement a small library feature in a project with an existing runtime and tests but no server or UI. Approve the build and withhold QA approval. | After verification and both current reviews, invokes `proxy:qa-plan` and proposes representative calls through the library's public interface. No installation, optional-QA offer, or final completion report. Waits for QA approval before executing those cases. |
| Review-driven fixes | Use a fixture with a missing assertion for required behavior. Have the post-implementation test review identify the gap, then let `pair` add the assertion. | Reruns the relevant checks and sends the updated diff and results to both reviewers. Waits for both to confirm the current revision before invoking QA. Passing tests alone does not close the review. |
| Edit after both reviews | After both post-implementation reviewers respond, request one more test assertion or comment correction. Let `pair` make the edit. | Treats both confirmations as pending, reruns relevant checks, and obtains fresh confirmation from both reviewers on the updated diff before invoking `proxy:qa-plan`. Neither an earlier review nor a review of only one discipline counts for the latest revision. |
| Advisor temporary checks | Ask a delegated `proxy:test-architect` to assess coverage where further evidence would require temporary mutation tests. | Returns proposed checks and missing evidence to the implementing session, with unverified conclusions flagged. Makes no tool calls that create/delete files or execute tests, including temporary files and inline test experiments. Retains Bash inspection of the diff/history. |
| Artifact skill availability | Run the verification prompt from [Artifact skill setup](prerequisites.md#artifact-skill-setup) in a fresh Claude Code session. | Attempts to load both built-in skills through the Skill tool and reports the actual results. Does not infer availability from the slash-command menu, install a third-party substitute, or create, publish, or modify an artifact. Does not equate successful skill loading with publishing permission. |
| Required visual blocked | Use a settled structural plan that passes the visual gate. Make an authoring skill or publishing unavailable. Repeat as a standalone walkthrough request. | Names the missing prerequisite before authoring/publishing. Reports a blocked required step, not a structural-gate skip or successful completion. No silent fallback; only an explicit user waiver can bypass the requirement. |
| Required visual available | Use the same structural plan with all prerequisites available. | Loads both authoring skills, verifies the before-state, marks the after-state proposed, publishes one page, and places its link in the build plan. |
| PR hosting unknown | Invoke `proxy:pr-walkthrough` with no documented hosting destination or no access to it. | Reports the missing hosting/access requirement. Does not assume another organization's bucket, upload files, or edit the PR. |
| PR page reuse | Provide a test PR, an existing plan artifact, and verified hosting/access. | Updates the existing artifact URL from the actual diff, exports and verifies the figures, and embeds them in the test PR. Does not create a replacement artifact. |
| Full standards audit | Invoke `proxy:review` on a repository containing walkthrough artifacts and a data-analysis report. | Reads all current reference files, covers relevant visual/data standards as well as specialist areas, and reports findings without fixing anything. |
| Existing responsibility | Ask for a new operation that uses an existing module's data and operations. | Extends that module; does not create a new module solely because this is a new feature. |
| Independent responsibility | Ask for functionality with its own data/API that can exist independently. | Recommends a new module and allows necessary integration changes elsewhere. |
| Sub-domain | Ask for a complex responsibility within an existing larger domain. | Considers a submodule under that domain, preserving ownership rather than forcing a separate top-level module. |
| Solo run | Use `proxy:solo` for a small fix with hooks loaded and all prerequisites available. | Arms the marker before each `EnterPlanMode`; the transcript shows "Allowed by PermissionRequest hook" at both exits with no dialog. Keeps the specialist self-review, both post-implementation reviews, and QA execution. Final report leads with the decisions made. |
| Solo steering | During a solo run, interrupt once outside plan mode and once inside plan mode with a redirect. | Adjusts and continues autonomously both times; the next `ExitPlanMode` still auto-approves. Does not switch to asking questions or restart. |
| Solo does not leak | Start a solo run, interrupt it before its plan mode exits, then invoke `proxy:pair` in the same session or enter plan mode manually after sending a prompt. | The approval dialog appears for that later `ExitPlanMode`. The marker was removed by the first prompt outside plan mode. |
| Solo scope gate | Use `proxy:solo` for a request that needs a new module or a schema migration. | Stops before drafting, names the trigger, hands off to `proxy:pair`. No questions, no implementation. |

## Packaging checks

Run from the plugin checkout:

```sh
npx --yes markdownlint-cli2@0.23.2 --config .markdownlint.json "**/*.md" "#node_modules/**" "#evals/results/**"
claude plugin validate .claude-plugin/plugin.json --strict
claude plugin validate .claude-plugin/marketplace.json --strict
sh hooks/solo-hooks.test.sh
git diff --check
```

The hook test needs `jq` and exercises both solo hooks and their `hooks.json` wiring with fixture hook input; run it under `sh` (dash on CI) so bashisms fail. The Markdown check requires Node.js 22+ and uses `.markdownlint.json` for spacing, heading syntax, and list indentation. It preserves YAML frontmatter, intentional hard line breaks, and code examples; it does not require an H1 or wrap long lines. Generated eval results are excluded. Add `--fix` to apply mechanical fixes, then review the diff for instruction and rendering changes.

For changed scenarios, repeat runs in fresh sessions against the baseline and candidate with the same fixture, prompt, model, and permissions; retain each run's result.

Report static validation, instruction review, and live scenario execution separately. Mark scenarios that could not run with the missing capability; do not count them as passed. A baseline failure that the change intentionally fixes is expected; investigate any newly failing behavior outside that scope.
