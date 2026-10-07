# WVC-M4-04 evidence - 2026-10-07

Implementation `1e11f759e8de691f575837eeb9d0647c4a0e7e68`; A01-A04 passed. Exact commands, host versions, report hashes, actual workflow/job/artifact identities and sanitized projections are in [JSON](WVC-M4-04.json). This is CI task verification, not milestone/release acceptance.

The Windows workflow runs the repository's actual Targeted tier on Windows PowerShell5.1 and pinned stable PowerShell7.6.6. Developer-only setup checks pinned Pester5.7.1/analyzer1.24.0, PowerShell and FFmpeg archives before extraction/import/execution, including digest, archive containment/alias/size, module/version and extracted native hash checks. Full-commit action pins, `contents: read`, nonpersistent checkout credentials and ordinary PR events are used. Primary sources matched committed pins in the independent read-only audit; maintenance/support limits remain in [provenance](../../../tests/CI_PROVENANCE.md).

Whole-tree parse/encoding/error/tracker gates remain; changed PowerShell code also receives error plus four selected safety-rule checks. No suppressions or application formatting rewrite were needed. The only shared harness expansion supplies ModuleRoot to the new CI test container. The application and launcher bytes, default quality and output/file-safety policies are unchanged.

| Criterion | Observed evidence | Outcome |
|---|---|---|
| A01 | Real analyzer-violation subprocess returns1; existing actual failing/all-skipped Pester subprocesses return nonzero. CI probes reject failed/skipped/NotRun, wrong host/modules/native tools, corrupt source/dirty/counts and static failures. Wrapper/workflow propagate native exits and refuse missing/invalid reports; no continue-on-error. | Passed |
| A02 | All four hosted jobs/upload steps succeeded. Downloaded artifacts each contain only summary.json, validated host/native versions, counts, fixed issues and ordinal case IDs; no arbitrary test names/reasons/paths/raw diagnostics. | Passed |
| A03 | Workflow/source review and local contract tests establish read-only credentials/no secrets or privileged PR-target event, immutable actions/accepted-content dependency pins, no automatic merge/tag/release/deploy. | Passed |
| A04 | Actual completed push and PR runs/jobs inspected through GitHub CLI/API; artifact identities and source commits checked independently. Queue/YAML existence is not the evidence. | Passed |

| Scope | Exact tested checkout | Results (passed/failed/skipped/NotRun) | Exit |
|---|---|---|---|
| Local PS5.1 Quick including known-defect coverage | clean `1e11f759e8de691f575837eeb9d0647c4a0e7e68` | 945/0/0/0 | 0 |
| Local CI + Harness, PS5.1 | clean `1e11f759e8de691f575837eeb9d0647c4a0e7e68` | 45/0/0/0 (26 CI cases) | 0 |
| Local CI + Harness, PS7.6.6 | clean `1e11f759e8de691f575837eeb9d0647c4a0e7e68` | 45/0/0/0 (26 CI cases) | 0 |
| Local PS5.1 changed analysis versus inspected main cbcecf7 | clean `1e11f759e8de691f575837eeb9d0647c4a0e7e68` | 8 files, zero diagnostics | 0 |
| [Push run37641576132](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37641576132), each host | exact feature `1e11f759e8de691f575837eeb9d0647c4a0e7e68` | 965/0/0/0; changed analysis8/0 | 0, success |
| [PR run37642013618](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37642013618), each host | generated merge `f0fc177eb02ce842fb85391b2666ab936ee37db8` | 965/0/0/0; changed analysis8/0 | 0, success |

GitHub's PR run reports feature head1e11f75 in run metadata but checks out generated mergef0fc177. Its API-confirmed parents are current maincbcecf7 and feature1e11f75; the uploaded SourceCommit identifies the tested checkout. These identities are not conflated. Hosted versions: PS5.1.26100.33438 Desktop / PS7.6.6 Core, Windows10.0.26100.0 (Server2025), image20260925.250.1, native2026-10-04-git-a35c879992-essentials_build-www.gyan.dev. Local Windows11 Pro26300/UBR9457/26H2: PS5.1.26100.9444 / PS7.6.6. Counts include harness/static/fixture checks, not exclusively application tests.

Only the allowlisted summary is uploaded for seven days. Its compact projections, hashes and run/job/artifact links are preserved in committed JSON; raw diagnostics and synthetic media remain local/ignored. RunnerImage.Name is null under the conservative ImageOS allowlist; actual OS/image version is reported and inspected logs name windows-2025-vs2026. Hosted images change; archive hashes pin accepted bytes rather than publisher signing. No deliberate failing workflow was pushed: A01 uses actual local negative subprocesses, admission regressions and reviewed workflow exit propagation.

Pre-continuation exploratory reports remain unchanged locally. No Full rerun or new Explorer/private-media/playback claim is made. Owner2026-10-07 menu/Quit/prompt, scoped motion/tone playback and physical cancellation acceptance remain intact; broader Explorer/representative-media/player/network/filesystem/durability/release gates stay open. Structural checks do not establish perceptual integrity.

Draft [PR28](https://github.com/PikkuJanne/WinVidCompress/pull/28) is open. Clean local/live fetch/live push equality at `2026-10-07T16:18:59.070668+00:00` describes implementation1e11f75 only. Final evidence commit push/live synchronization and its actual CI state are reported externally after commit/push to avoid embedding its own SHA. Exact next: **WVC-M4-05 - Complete the real Windows workflow acceptance matrix**.
