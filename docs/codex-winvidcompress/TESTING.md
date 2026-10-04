# Testing strategy and honest evidence

## Separate bundle tests from application tests

This bundle includes tested development helpers and planned application acceptance criteria. It does not include an implemented replacement compressor or passed application regressions. Python helper tests run on the bundle-authoring Linux environment; real Windows/PowerShell/Explorer checks remain for Codex and the owner.

Use Pester for the PowerShell test harness and PSScriptAnalyzer for targeted static analysis. Verify and pin compatible versions during M0. Record exact PowerShell, Windows and FFmpeg/FFprobe versions, including executable paths where safe. Do not substitute a Linux FFmpeg result for Windows argument/Explorer acceptance.

## Test tiers

| Tier | When | Scope |
|---|---|---|
| Quick | Every small change | Parse/load, focused unit regressions, task/schema consistency and changed-file static checks |
| Targeted | Each task | Affected units + short synthetic integration cases; failure/collision/argument regressions |
| Full | Milestone/risk gates | All automated supported-host tests, media matrix, CLI, packaging and safety tests |
| Manual/extended | Release gates and platform-sensitive changes | Windows Explorer, real Ctrl+C, playback/colour judgement, UNC/long paths, representative benchmark copies |

Typical scope budgets are quick about 2 minutes and targeted about 10 minutes on the active workstation; these are planning targets, not promised execution times. Do not rerun long unrelated suites after every doc-only edit. If a failure is deterministic, isolate it, add/fix the relevant regression, rerun that scope, then run the next required gate. Never skip a relevant safety check to meet a budget.

## Isolation

Inject or temporarily override application config/output roots inside an isolated test process. Never touch real APPDATA, Videos, external archives or production configuration. Use fixture-local sentinel files and compare hashes to prove no-clobber behaviour. Create synthetic fixtures at test runtime; no copyrighted/private interviews or FFmpeg binaries in Git. Clean only the fixture directory created by the test, with containment checks.

Use ffmpeg-generated short test patterns/audio when installed, and normalized FFprobe JSON fixtures for malformed/rare metadata. Document generation commands, dependencies and expected streams. Make fixtures deterministic enough for structural assertions; do not assume lossy output byte hashes remain identical across FFmpeg versions.

## Required coverage

Menu/launcher, literal paths, empty/single/multi enumeration, missing/offline/invalid config, source/output overlap, duplicates, reparse policy, dependency selection, probe errors, silent/multi-stream/cover-art media, rotation/SAR/odd dimensions, SDR/HDR classification, date validity, native stderr/exit/progress, non-writing WhatIf, cancellations, manifest tampering/changed inputs, no-clobber races, larger outputs and clean ZIP extraction.

Actual Explorer argv tests must cover `!`, `%PATH%`, `!NAME!`, `&`, parentheses, brackets, apostrophes, spaces and Finnish/German/non-Latin characters. Record Windows filename/command-line limitations honestly; do not put forbidden Windows filename characters into a test and claim the resulting inability is a codec bug.

## Evidence requirements

Use evidence/TASK_EVIDENCE_TEMPLATE.json or the markdown template. Record task+acceptance IDs, exact command, tested source SHA/tree, host/tool versions, observed exit and pass/fail/skip counts, artifacts (sanitized) and limitations. A screenshot alone is not evidence for all paths. A test that was not run remains not_run/skipped, not passed. Manual approval must cite the actual owner decision and date; the agent may not approve on their behalf.

Application test command paths in the plan are future deliverables until M0 creates them. Do not report them as already executed. Update the documented commands to the real harness after implementation. CI must run the same relevant test scopes and fail on real failed tests.
