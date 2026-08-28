export const meta = {
  name: 'build-product',
  description: 'Implements an approved plan unattended: implement, review, loop fixes, report.',
  phases: [
    { title: 'Load Context' },
    { title: 'Implement' },
    { title: 'Review Code' },
    { title: 'Report' },
  ],
}

const CONTEXT_SCHEMA = {
  type: 'object',
  properties: {
    philosophy: { type: 'string' },
    productPrinciples: { type: 'string' },
    architecturePrinciples: { type: 'string' },
    cleanCodePrinciples: { type: 'string' },
    testingPrinciples: { type: 'string' },
    cleanCodeArchitectAgent: { type: 'string' },
    testArchitectAgent: { type: 'string' },
    implementerAgent: { type: 'string' },
  },
  required: [
    'philosophy',
    'productPrinciples',
    'architecturePrinciples',
    'cleanCodePrinciples',
    'testingPrinciples',
    'cleanCodeArchitectAgent',
    'testArchitectAgent',
    'implementerAgent',
  ],
}

const IMPL_SCHEMA = {
  type: 'object',
  properties: {
    filesChanged: { type: 'array', items: { type: 'string' } },
    testResults: { type: 'string' },
    decisions: { type: 'array', items: { type: 'string' } },
    couldNotVerify: { type: 'array', items: { type: 'string' } },
  },
  required: ['filesChanged', 'testResults', 'decisions', 'couldNotVerify'],
}

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: { type: 'string' } },
  },
  required: ['findings'],
}

const HEADLESS_NOTE =
  'You are running headless inside a workflow, not as the named agent role via its normal invocation path. The persona/reference text below was written for that normal path and may tell you to "Read ../references/..." or similar — ignore those instructions, the paths won\'t resolve from here and the content is already included below. Also ignore any YAML frontmatter block (name/tools/model) — that\'s configuration for the normal invocation path, not relevant here. Also: never use AskUserQuestion, there is no user to answer.'

const EDIT_TOOL_NOTE =
  'For any file change: use the Edit or Write tool directly. Do not use Bash with sed, python/node heredocs, or any other shell-script workaround to modify files — the dedicated tools are available here and are what should be used, regardless of any other default guidance about preferring shell scripts for file changes.'

phase('Load Context')
if (!args?.pluginRoot) {
  throw new Error(
    'Missing args.pluginRoot — this workflow needs the absolute path to the proxy plugin directory to load its own reference/agent files. Pass { pluginRoot, plan } when launching.'
  )
}
if (!args?.plan) {
  throw new Error('Missing args.plan — this workflow needs the approved plan text.')
}
log(`Reading plugin files from ${args.pluginRoot}`)
const ctx = await agent(
  `Read these files and return each one's full raw content, verbatim, under the matching key. Don't summarize or paraphrase — exact file contents.\n\n` +
    `philosophy: ${args.pluginRoot}/references/philosophy.md\n` +
    `productPrinciples: ${args.pluginRoot}/references/product-principles.md\n` +
    `architecturePrinciples: ${args.pluginRoot}/references/architecture-principles.md\n` +
    `cleanCodePrinciples: ${args.pluginRoot}/references/clean-code-principles.md\n` +
    `testingPrinciples: ${args.pluginRoot}/references/testing-principles.md\n` +
    `cleanCodeArchitectAgent: ${args.pluginRoot}/agents/clean-code-architect.md\n` +
    `testArchitectAgent: ${args.pluginRoot}/agents/test-architect.md\n` +
    `implementerAgent: ${args.pluginRoot}/agents/implementer.md`,
  { schema: CONTEXT_SCHEMA }
)

phase('Implement')
log('Implementing the approved plan. Plan already went through architect self-review before you approved it — this is straight execution, not a second design review.')
let impl = await agent(
  `${HEADLESS_NOTE}\n\n${EDIT_TOOL_NOTE}\n\n${ctx.implementerAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.cleanCodePrinciples}\n\n${ctx.testingPrinciples}\n\n---\n\nImplement this approved plan. Write the code, apply extraction judgment where it applies, write and run tests, add logs, loop fix → retest until green.\n\nApproved plan:\n${args.plan}`,
  { schema: IMPL_SCHEMA }
)

phase('Review Code')
let round = 0
const MAX_ROUNDS = 3
while (round < MAX_ROUNDS) {
  log(`Review round ${round + 1}: clean-code and test review in parallel.`)
  const reviews = await parallel([
    () =>
      agent(
        `${HEADLESS_NOTE}\n\n${ctx.cleanCodeArchitectAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.cleanCodePrinciples}\n\n---\n\nReview this implementation for extraction/clean-code issues against the plan it was built from.\n\nPlan:\n${args.plan}\n\nImplementation summary:\n${JSON.stringify(impl)}`,
        { schema: FINDINGS_SCHEMA }
      ),
    () =>
      agent(
        `${HEADLESS_NOTE}\n\n${ctx.testArchitectAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.testingPrinciples}\n\n---\n\nReview test coverage and quality for this implementation against the plan it was built from.\n\nPlan:\n${args.plan}\n\nImplementation summary:\n${JSON.stringify(impl)}`,
        { schema: FINDINGS_SCHEMA }
      ),
  ])

  const findings = reviews.filter(Boolean).flatMap((r) => r.findings)
  if (!findings.length) {
    log('No findings — implementation is clean.')
    break
  }

  log(`${findings.length} finding(s) — sending back to implementer.`)
  impl = await agent(
    `${HEADLESS_NOTE}\n\n${EDIT_TOOL_NOTE}\n\n${ctx.implementerAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.cleanCodePrinciples}\n\n${ctx.testingPrinciples}\n\n---\n\nFix these review findings, then re-run tests to confirm still green.\n\nFindings:\n${JSON.stringify(findings)}\n\nCurrent implementation state:\n${JSON.stringify(impl)}`,
    { schema: IMPL_SCHEMA }
  )
  round++
}

if (round === MAX_ROUNDS) {
  log(`Hit the ${MAX_ROUNDS}-round review cap — reporting current state rather than looping indefinitely.`)
}

phase('Report')
return {
  plan: args.plan,
  implementation: impl,
  reviewRounds: round,
  cappedOut: round === MAX_ROUNDS,
}
