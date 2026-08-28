export const meta = {
  name: 'build-product',
  description: 'Implements an approved plan unattended: sanity-check design, implement, review, loop fixes, report.',
  phases: [
    { title: 'Load Context' },
    { title: 'Review Design' },
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
    architectAgent: { type: 'string' },
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
    'architectAgent',
    'cleanCodeArchitectAgent',
    'testArchitectAgent',
    'implementerAgent',
  ],
}

const DESIGN_REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    ready: { type: 'boolean' },
    gaps: { type: 'array', items: { type: 'string' } },
  },
  required: ['ready', 'gaps'],
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
    `architectAgent: ${args.pluginRoot}/agents/architect.md\n` +
    `cleanCodeArchitectAgent: ${args.pluginRoot}/agents/clean-code-architect.md\n` +
    `testArchitectAgent: ${args.pluginRoot}/agents/test-architect.md\n` +
    `implementerAgent: ${args.pluginRoot}/agents/implementer.md`,
  { schema: CONTEXT_SCHEMA }
)

phase('Review Design')
log('Sanity-checking the approved plan before implementation starts.')
const designReview = await agent(
  `${ctx.architectAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n---\n\nSanity-check this already-approved plan for technical soundness and completeness before implementation starts. Don't re-litigate product decisions — those are already settled, out of scope for this review. Flag only real technical gaps or omissions.\n\nApproved plan:\n${args.plan}`,
  { schema: DESIGN_REVIEW_SCHEMA }
)

phase('Implement')
const designNote = designReview.gaps.length
  ? `Design review flagged before you started (resolve these as part of implementation, don't ignore them): ${JSON.stringify(designReview.gaps)}`
  : ''
log('Implementing the approved plan.')
let impl = await agent(
  `${ctx.implementerAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.cleanCodePrinciples}\n\n${ctx.testingPrinciples}\n\n---\n\nImplement this approved plan. Write the code, apply extraction judgment where it applies, write and run tests, add logs, loop fix → retest until green.\n\nApproved plan:\n${args.plan}\n\n${designNote}`,
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
        `${ctx.cleanCodeArchitectAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.cleanCodePrinciples}\n\n---\n\nReview this implementation for extraction/clean-code issues against the plan it was built from.\n\nPlan:\n${args.plan}\n\nImplementation summary:\n${JSON.stringify(impl)}`,
        { schema: FINDINGS_SCHEMA }
      ),
    () =>
      agent(
        `${ctx.testArchitectAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.testingPrinciples}\n\n---\n\nReview test coverage and quality for this implementation against the plan it was built from.\n\nPlan:\n${args.plan}\n\nImplementation summary:\n${JSON.stringify(impl)}`,
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
    `${ctx.implementerAgent}\n\n${ctx.philosophy}\n\n${ctx.architecturePrinciples}\n\n${ctx.cleanCodePrinciples}\n\n${ctx.testingPrinciples}\n\n---\n\nFix these review findings, then re-run tests to confirm still green.\n\nFindings:\n${JSON.stringify(findings)}\n\nCurrent implementation state:\n${JSON.stringify(impl)}`,
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
  designReview,
  implementation: impl,
  reviewRounds: round,
  cappedOut: round === MAX_ROUNDS,
}
