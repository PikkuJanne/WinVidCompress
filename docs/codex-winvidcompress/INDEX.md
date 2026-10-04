# WinVidCompress improvement workspace

Start with STATUS.md and NEXT_SESSION.md. TASKS.json is the machine-readable status authority; ROADMAP.md describes the milestones, TRACEABILITY.md maps the 23 review items, and tasks/ contains bounded task briefs. This programme improves the local tool, not a hosted video converter.

## Files to consult by concern

| Concern | File |
|---|---|
| Current repository anchor and source findings | BASELINE.json; AUDIT.md |
| Must-preserve behaviour and design choices | PRODUCT_CONTRACT.md; DECISIONS.md |
| Safe local/GitHub workflow | GIT_SYNC.md |
| Configuration, path discovery and queueing | CONFIG_AND_DISCOVERY.md |
| Probe, stream choice, scaling, colour and tags | MEDIA_PIPELINE.md |
| Temporary files, validation, collisions and resume | OUTPUT_SAFETY.md |
| Native process, CLI, progress, logs and exit codes | PROCESS_AND_CLI.md |
| Automated/manual tests and evidence | TESTING.md; ACCEPTANCE_MATRIX.md; evidence/ |
| Measurements without preset drift | BENCHMARKS.md |
| CI, packaging, licensing and publication gates | SECURITY_AND_RELEASE.md |
| Static product/download content | WEBSITE_HANDOFF.md |
| Primary references | SOURCES.md |
| Continue in a fresh thread | NEXT_THREAD_PROMPT.md |

## Status rules

A task starts `todo`, then `in_progress`. Use `blocked` for a genuine prerequisite failure; `implemented` for committed code whose full verification is still pending; `verified` only when every applicable acceptance item has passing evidence; and `accepted` only after any required owner approval. `deferred` needs a specific owner-authorized reason. Criteria can be not_run, passed, failed, skipped, blocked or not_applicable; the last requires a reason.

Implementation dependencies may be satisfied by an implemented task when its usable behaviour and relevant automated checks have been demonstrated. Outstanding Windows/manual checks remain explicit and block the applicable milestone/release acceptance, not unrelated safe documentation work. Never build on a known failed file-safety prerequisite just to keep moving.

All tasks in the supplied bundle are initially `todo`, all acceptance items `not_run`. Bundle-tool self-tests are not application test results. Existing instructions and newer repository work must be reconciled, not replaced.
