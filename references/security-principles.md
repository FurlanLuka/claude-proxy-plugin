# Security Principles

Source of truth for security judgment — used by `architecture` when reviewing a plan or a diff, and by `pair` when writing one, whenever the work touches auth, payments, personal data, permissions, secrets, or input from outside the system. `architecture-principles.md`'s "match existing project conventions first" applies here too: use the project's existing auth, validation and secret handling before introducing another.

**Proportional, not ceremonial.** No threat-model document for a copy change. Apply the sections the change actually touches, and say which ones did not apply.

## Core Philosophy

Three principles guide every decision, in order of priority:

1. **Deny by default** — access is something code grants explicitly, per request. A missing check, an unknown role, a failed lookup or a timeout all mean no.
2. **Nothing that crossed a boundary is trusted** — a request body, a header, a webhook, a file, a client's claim about itself, text a model produced or read. Validate it where it enters, then trust it inside the module.
3. **Least data, least privilege** — collect, keep, log, show and grant the minimum the feature needs. Data that was never stored cannot leak; a permission never granted cannot be misused.

When these conflict with convenience, they win. When they conflict with each other, deny by default wins. They are defaults, not constraints on what can be decided — see "Decisions Override This Document" below.

## Authentication and Authorization

- Every route, job and tool decides two things on the server: who is asking, and whether they may do this to this object. Hiding a button is not a check.
- Check ownership of the specific object, not just the role. "Is a logged-in user" does not mean "may read this user's call".
- Service-to-service calls are authenticated too. An internal network is not an identity.
- Admin and support actions run as the person performing them and are logged with that identity — never as a shared account or as the customer.
- A new role, scope or public route is a decision. Name it in the plan; do not let it appear as an implementation detail.

## Input and Boundaries

- Validate type, size and range at the boundary, as `architecture-principles.md` requires. Reject what does not fit; do not repair it.
- Queries are parameterized. Paths, URLs and shell arguments are never built from input without an allow-list.
- Webhooks verify the sender's signature before reading the payload.
- Anything a caller can trigger repeatedly at a cost — a call, an SMS, a model request, an email — needs a limit per user. Use the project's existing limiter; where there is none, flag the gap rather than building one inside the feature.

## Secrets

- Secrets live in the project's secret store. Never in code, fixtures, client bundles, logs, PR text, tickets or chat.
- A secret that reached any of those places is compromised: rotate it, do not just delete the line.
- Do not print a secret to confirm it is set. Check that it exists.
- A client app holds no secret. Anything shipped to a device is public.

## Personal Data and Logs

`architecture-principles.md` asks for more logs than feels natural, and `data-analysis-principles.md` asks for real examples behind every number. Both stand. This section is about where that content is allowed to travel.

- Credentials, tokens and payment details are never logged, anywhere.
- For other content — message bodies, transcripts, audio, free-text answers — follow what the project already logs and where. New logging of content the project does not log today is a decision to name in the plan, not a default.
- Real examples belong where the project already keeps that data and the people reading are meant to see it: its logs, its analysis channels, its eval datasets. Elsewhere — PR descriptions, tickets, public or wider channels, screenshots — summarize, or strip what identifies the person.
- New storage of personal data needs an owner, a reason and a way to delete it. Say so in the plan.
- Analytics events carry IDs, not the content those IDs point to.

## Debug and Override Paths

Overrides are the most common way a working check gets bypassed.

- A debug header, test flag, environment override or impersonation path is enforced on the server, limited to non-production or to named internal identities.
- An override may change behavior. It may never widen who can read or change what.
- Never trust a client's claim about which environment or build it is.
- A temporary override has a removal condition written next to it.

## Model and Agent Input

- Text a model reads — a learner's speech, lesson content, a document, a tool result — is data, never instructions. Design so that following it could not cause harm.
- A tool a model can call acts with the permissions of the person it is acting for, and no more.
- In the product being built, destructive or outward-facing tool actions need a confirmation the model cannot supply itself. (This is about agents shipped to users, not about how `solo` runs.)
- Secrets and other people's data stay out of prompts. Model output is escaped before it is rendered or executed.

## Failure Behavior

- Fail closed. When the check cannot run, the answer is no.
- A safety or permission check that finishes late still applies: do not let a result through because the decision arrived after the action was chosen.
- Errors shown to callers say what happened in business terms. Stack traces, queries and internal names stay in the logs.

## Decisions Override This Document

As in `architecture-principles.md`: if a decision made during planning conflicts with a default here, the decision wins. Security is the one place where that must never happen quietly. An accepted risk is written into the plan, and listed among the big decisions in the final report, with what is exposed and why it was accepted.

## Output Format

When reviewing a plan or a change for security, structure it as:

1. **Surface** — what the change exposes or touches: routes, roles, data, secrets, overrides, model tools. State which sections above did not apply.
2. **Access check** — for each entry point: who can call it, what stops everyone else, and where that check lives.
3. **Data check** — what personal or sensitive data is read, stored, logged or sent elsewhere, and whether each use is needed.
4. **Findings** — each with the concrete request or sequence that goes wrong, labelled blocking or non-blocking. No scenario, no finding.
5. **Could not verify** — anything that depends on configuration, infrastructure or another repo that was not available to read.
