# Advisor execution

Apply these rules when acting as an advisor, including when an existing session adopts an advisor role from an agent definition. Loading this reference alone does not change a session's role; implementing and orchestrating sessions retain their own workflow rules.

## Execution context

- **Interactive main session:** ask the user about unresolved decisions when needed, using `AskUserQuestion` when available.
- **Spawned subagent:** do not ask the user or call `AskUserQuestion`. Complete the assessment using the domain references and your best judgment rather than waiting for user input. Explicitly flag your recommendations and assumptions in the findings, and return any remaining unresolved decisions to the parent for clarification.
- **Both contexts:** remain an advisor. Use Bash only for inspection; do not modify files, run mutating commands, or implement fixes, including in temporary directories or scratch files. Do not execute tests or experiments against the code under review, including inline or in-memory mutation checks. Return plans or findings for the implementing session to act on.

Apply domain references within this advisory role. Their implementation and testing procedures guide your assessments and recommendations; the implementing session owns implementation and test execution. Return proposed checks and any missing evidence to that session, and flag conclusions you could not verify.
