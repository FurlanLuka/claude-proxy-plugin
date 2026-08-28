# Data Analysis Principles

General methodology for investigating data/logs/metrics — not tied to any specific tool (BigQuery, Postgres, GCP logs, whatever the project uses). Extracted from mining real work history. Complements `architecture-principles.md`'s Logging section, which covers what to log; this covers how to analyze what's there.

## Population-level, not sampling

Default to covering the full window/dataset being asked about, not a sample. If a query genuinely needs a cap for cost/performance reasons, that's a safety valve that only fires on anomalies — and when it does, it gets reported as a finding ("this only covers X of Y because of Z"), never silently used to shrink the dataset without saying so.

## Get the unit of analysis right

Before reporting a rate or percentage, confirm what's actually being counted — per session, per unique user, per event? A number can be technically correct and still misleading if the grain is wrong (e.g. counting every rating a user left instead of only counting a change in rating). Ask "what's the denominator here" before trusting a headline number.

## Cross-reference sources, don't trust one

Structured telemetry (a data warehouse table) can lag or miss events; logs are often the ground-truth fallback for what actually happened. When investigating something real, check more than one source — structured data for the aggregate picture, logs for the actual play-by-play, and the schema/source code as final authority for what a field or join key actually means. Don't take a single source's word for it when the others are available.

## Verify, don't assume, schema/field semantics

Table names, column names, enum values — verify these directly against a live query or the source code before using them, never assume from memory or a prior report. If an assumption turns out wrong partway through, call it out inline rather than silently fixing it and moving on — a silent fix means the same wrong assumption resurfaces next time someone edits the same area.

## Ground aggregates with examples

A number alone isn't enough to trust or act on — ask to see a handful of real examples (actual sessions, actual transcripts, actual records) that produced that number. Aggregates without examples hide edge cases and misclassification.

## Verify claims before reporting them

A report or summary of findings has to be checked against the actual data before it goes out — "100% real," no stale references to old data, no claims that weren't actually re-verified. If a written handoff doc or third-party report makes a claim, verify it against live data before treating it as settled, don't accept it at face value just because someone wrote it down.

## Rigor is "check the source," not formal statistics

This isn't about confidence intervals or significance testing — the rigor expressed here is empirical: query the real data, cross-reference multiple sources, verify against the schema, ground it in examples. That's the actual bar, not academic statistical methodology.
