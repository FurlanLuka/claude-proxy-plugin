export const meta = {
  name: 'qa',
  description: 'Executes an approved QA plan against the real, running implementation and reports results.',
  phases: [{ title: 'Load Context' }, { title: 'Execute QA' }, { title: 'Report' }],
}

const CONTEXT_SCHEMA = {
  type: 'object',
  properties: {
    philosophy: { type: 'string' },
    architecturePrinciples: { type: 'string' },
    qaTesterAgent: { type: 'string' },
  },
  required: ['philosophy', 'architecturePrinciples', 'qaTesterAgent'],
}

const QA_SCHEMA = {
  type: 'object',
  properties: {
    exercised: { type: 'array', items: { type: 'string' } },
    passed: { type: 'array', items: { type: 'string' } },
    failed: { type: 'array', items: { type: 'string' } },
    couldNotVerify: { type: 'array', items: { type: 'string' } },
  },
  required: ['exercised', 'passed', 'failed', 'couldNotVerify'],
}

const HEADLESS_NOTE =
  'You are running headless inside a workflow, not as the named agent role via its normal invocation path. The persona/reference text below was written for that normal path and may tell you to "Read ../references/..." or similar — ignore those instructions, the paths won\'t resolve from here and the content is already included below. Also ignore any YAML frontmatter block (name/tools/model) — that\'s configuration for the normal invocation path, not relevant here. Also: never use AskUserQuestion, there is no user to answer.'

phase('Load Context')
if (!args?.pluginRoot) {
  throw new Error(
    'Missing args.pluginRoot — this workflow needs the absolute path to the proxy plugin directory to load its own reference/agent files. Pass { pluginRoot, qaPlan } when launching.'
  )
}
if (!args?.qaPlan) {
  throw new Error('Missing args.qaPlan — this workflow needs the approved QA plan text.')
}
log(`Reading plugin files from ${args.pluginRoot}`)
const ctx = await agent(
  `Read these files and return each one's full raw content, verbatim, under the matching key. Don't summarize or paraphrase — exact file contents.\n\n` +
    `philosophy: ${args.pluginRoot}/references/philosophy.md\n` +
    `architecturePrinciples: ${args.pluginRoot}/references/architecture-principles.md\n` +
    `qaTesterAgent: ${args.pluginRoot}/agents/qa-tester.md`,
  { schema: CONTEXT_SCHEMA }
)

phase('Execute QA')
log('Exercising the implementation against the approved QA plan.')
const result = await agent(
  `${HEADLESS_NOTE}\n\n${ctx.qaTesterAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n---\n\nExecute this approved QA plan against the real, running implementation. Use only tools already available — never install new tooling to make something testable.\n\nApproved QA plan:\n${args.qaPlan}`,
  { schema: QA_SCHEMA }
)

phase('Report')
return result
