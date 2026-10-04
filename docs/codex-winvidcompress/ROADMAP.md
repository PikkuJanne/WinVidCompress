# Implementation roadmap

This is a plan for improving the existing tool. Nothing below is already implemented or verified by creating the bundle.

**Work one ready task per Codex thread.** Use TASKS.json for status and dependencies; a milestone is a review gate, not a context-sized unit. Split an oversized task into documented child IDs before proceeding.

The original 23 review items are mapped in TRACEABILITY.md. M0 is preparation; M1–M5 are implementation/release-readiness gates.

## M0 — Baseline, safe import and regression harness

| Task | Work | Priority |
|---|---|---|
| [WVC-M0-01](tasks/WVC-M0-01.md) | Reconcile the real checkout and install this handoff | P0 |
| [WVC-M0-02](tasks/WVC-M0-02.md) | Characterize existing behaviour and add the smallest test seam | P0 |
| [WVC-M0-03](tasks/WVC-M0-03.md) | Establish the regression harness and generated fixtures | P1 |

Gate: relevant tests and task evidence are complete; code and handoff are pushed to the matching GitHub feature branch. Any Windows-only or owner-review gap remains explicitly blocked/pending.

## M1 — Known bugs, configuration and input discovery

| Task | Work | Priority |
|---|---|---|
| [WVC-M1-01](tasks/WVC-M1-01.md) | Repair menu exit and separate source/output folder selection | P0 |
| [WVC-M1-02](tasks/WVC-M1-02.md) | Harden the .bat launcher using measured argument round trips | P0 |
| [WVC-M1-03](tasks/WVC-M1-03.md) | Make configuration validation and recovery safe | P0 |
| [WVC-M1-04](tasks/WVC-M1-04.md) | Normalize file discovery and expose scan failures | P0 |
| [WVC-M1-05](tasks/WVC-M1-05.md) | Freeze and deduplicate the full batch before encoding | P0 |
| [WVC-M1-06](tasks/WVC-M1-06.md) | Add dependency and output-environment diagnostics | P1 |

Gate: relevant tests and task evidence are complete; code and handoff are pushed to the matching GitHub feature branch. Any Windows-only or owner-review gap remains explicitly blocked/pending.

## M2 — Validated, no-clobber conversion pipeline

| Task | Work | Priority |
|---|---|---|
| [WVC-M2-01](tasks/WVC-M2-01.md) | Expand FFprobe into normalized JSON media inspection | P0 |
| [WVC-M2-02](tasks/WVC-M2-02.md) | Select and map the same real video and intended audio | P0 |
| [WVC-M2-03](tasks/WVC-M2-03.md) | Isolate command construction and native process execution | P0 |
| [WVC-M2-04](tasks/WVC-M2-04.md) | Implement owned temporary output and no-clobber promotion | P0 |
| [WVC-M2-05](tasks/WVC-M2-05.md) | Validate output before marking it complete | P0 |
| [WVC-M2-06](tasks/WVC-M2-06.md) | Define job results, counters and script exit codes | P1 |

Gate: relevant tests and task evidence are complete; code and handoff are pushed to the matching GitHub feature branch. Any Windows-only or owner-review gap remains explicitly blocked/pending.

## M3 — Media correctness, reporting and recoverable batches

| Task | Work | Priority |
|---|---|---|
| [WVC-M3-01](tasks/WVC-M3-01.md) | Harden resizing and rotation without a new resolution preset | P1 |
| [WVC-M3-02](tasks/WVC-M3-02.md) | Define SDR compatibility and reject untested HDR conversions | P1 |
| [WVC-M3-03](tasks/WVC-M3-03.md) | Validate interview metadata dates and preserve text | P1 |
| [WVC-M3-04](tasks/WVC-M3-04.md) | Report savings and benchmark rather than guess | P1 |
| [WVC-M3-05](tasks/WVC-M3-05.md) | Add machine progress and privacy-aware persistent logs | P1 |
| [WVC-M3-06](tasks/WVC-M3-06.md) | Cancel safely and terminate only this job’s child process | P0 |
| [WVC-M3-07](tasks/WVC-M3-07.md) | Add validated batch retry/resume with a versioned manifest | P1 |

Gate: relevant tests and task evidence are complete; code and handoff are pushed to the matching GitHub feature branch. Any Windows-only or owner-review gap remains explicitly blocked/pending.

## M4 — Optional CLI, compatibility and Windows acceptance

| Task | Work | Priority |
|---|---|---|
| [WVC-M4-01](tasks/WVC-M4-01.md) | Expose optional CLI controls and a truly non-writing preview | P1 |
| [WVC-M4-02](tasks/WVC-M4-02.md) | Add opt-in relative subfolder preservation | P1 |
| [WVC-M4-03](tasks/WVC-M4-03.md) | Stress concurrency, crash recovery and filesystem edge cases | P0 |
| [WVC-M4-04](tasks/WVC-M4-04.md) | Add Windows CI and targeted static analysis | P1 |
| [WVC-M4-05](tasks/WVC-M4-05.md) | Complete the real Windows workflow acceptance matrix | P1 |

Gate: relevant tests and task evidence are complete; code and handoff are pushed to the matching GitHub feature branch. Any Windows-only or owner-review gap remains explicitly blocked/pending.

## M5 — Documentation, release candidate and website handoff

| Task | Work | Priority |
|---|---|---|
| [WVC-M5-01](tasks/WVC-M5-01.md) | Write onboarding, help and troubleshooting for actual behaviour | P1 |
| [WVC-M5-02](tasks/WVC-M5-02.md) | Build deterministic tool-only release packages and checksums | P1 |
| [WVC-M5-03](tasks/WVC-M5-03.md) | Preserve licensing and review distribution security | P1 |
| [WVC-M5-04](tasks/WVC-M5-04.md) | Prepare website product metadata and genuine demonstration content | P1 |
| [WVC-M5-05](tasks/WVC-M5-05.md) | Reconstruct from GitHub and present a release candidate for approval | P1 |

Gate: relevant tests and task evidence are complete; code and handoff are pushed to the matching GitHub feature branch. Any Windows-only or owner-review gap remains explicitly blocked/pending.

## Do not add during this programme

No GUI/application-framework rewrite, GPU/HEVC/AV1 preset expansion, upload service, server-side processing, parallel encoding engine, automatic updater, bundled FFmpeg distribution, signing service or live website deployment. Stronger identity and relative output layout are explicitly opt-in; untested HDR is diagnosed, not tone-mapped by guesswork.
