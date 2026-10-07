# WVC-M5-01 - onboarding, help and troubleshooting

2026-10-07: A01-A04 passed in the scopes below; task verified. Implementation/tested commit **2c2b45362ab14d18fd3c13635fa1d2f987cabc60**, feature `codex/wvc-m5-01-docs`, from owner-merged PR29/main **3b7bc1e28a2835da6d523753662c238ac0df1b13**. [Exact commands, hashes, hosts and projections](WVC-M5-01.json), [session](WVC-M5-01-session.md), [draft PR30](https://github.com/PikkuJanne/WinVidCompress/pull/30).

README now leads through source ZIP download/extraction, separately installed FFmpeg/FFprobe, doctor, no-write preview and first copy, then menu/drop/unattended use. `docs/user/REFERENCE.md` covers all public controls, stream/geometry/colour/metadata/output/retry policies. `TROUBLESHOOTING.md` covers unavailable drives, malformed/recovered/reset config, probe failure, growth, failed/cancelled jobs and private diagnostics. `VERIFICATION.md` maps behavior claims to verified records or explicit limits. The stale prose banner is replaced by one accurate comment-help block; no runtime code or quality/default change.

## Actual Windows checks

Host: Windows 11 Pro 10.0.26300 UBR9457/26H2 x64; registry ProductName still reports Windows 10 Pro. Windows PowerShell5.1.26100.9444/Desktop and supported stable PS7.6.6/Core; Pester5.7.1, analyzer1.24.0. Existing verified FFmpeg/FFprobe2026-10-04-git-a35c879992 essentials build; executable hashes rechecked against `tests/CiDependencies.psd1`. No dependency downloads, elevation, policy/profile/default-Videos changes or production APPDATA access.

| Scope at clean 2c2b453 | Pass/fail/skip/not_run | Exit | Observation |
| --- | --- | --- | --- |
| PS5.1 Quick, IncludeKnownDefects | 949/0/0/0 | 0 | Actual whole current Quick discovery plus parse/encoding/tracker/analyzer; installed native dependencies available. |
| PS7 affected WhatIf/CLI/Summary/Manifest | 129/0/0/0 | 0 | Includes three real Get-Help examples executed with owned placeholders; relevant no-write/help/default/fingerprint policy checks. |
| Clean tool-only extraction | 68/0/0/0 | 0 | 34 assertions per supported host; actual native source/output checks and unattended BAT. |
| Documentation/source audit | 86/0/0/1 | 0 | Runtime-body/BAT byte proof, public parameter/coverage/evidence-status/file-link checks; one pending M5-01 evidence link before this record existed. Final handoff audit87/0/0/0 closes it; omission is preserved here. |
| Changed-file static policy | 1 file, 0 diagnostics | 0 | Actual PS1 comment edit analyzed against full inspected main SHA. |

Exact runner commands/redirects/host/report hashes are in JSON. Prepared runtime/Python absolute directories are private local bindings rather than copied into evidence. Reports/logs remain ignored locally. No Full/manual gate is claimed or long unrelated suite repeated for prose-only work.

## A01 - clean extracted setup

Created a **local documentation-smoke ZIP** from the exact committed source, with no checkout/untracked/private/dependency content:

```powershell
git archive --format=zip --output=.test-results/m501/onboarding-2c2b453.zip 2c2b45362ab14d18fd3c13635fa1d2f987cabc60 README.md WinVidCompress.ps1 WinVidCompress.bat LICENSE docs/user
```

Seven file entries: PS1, BAT, README, LICENSE and the three user guides. SHA256 **5f32e813224b92806099714b66476bb1c66cafca0cd13b044fb106a5edc2f508**. Expanded separately with `Expand-Archive` into newly owned isolated roots for both hosts. Only after extraction, copied the existing verified native executables adjacent, as README describes; test-process PATH contained only Windows system directories. Source/output/APPDATA roots were separate; no hidden config/modules/runtime companion files were used by the application.

Generated a half-second 160x120/24fps moving pattern and 48kHz tone using `testsrc2`/`sine`, libx264 veryfast CRF18/yuv420p and AAC as a disposable source. Ran the documented PS1 entry options with actual owned paths substituted:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <extracted-PS1> -CheckEnvironment -OutputDir <output>
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <extracted-PS1> -Unattended -WhatIf -OutputDir <output> <sources>
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <extracted-PS1> -Unattended -OutputDir <output> <sources>
```

Repeated with the actual PS7 executable. Verified adjacent paths, doctor's no persistent changes, preview's exact no-file-write snapshot, Done1/nominal MP4, H264/AAC/geometry/filename tags, full native decode, fresh `(compressed)` rename, collision skip and source/pre-existing-final hashes. Both extracted Get-Help results contain all eleven public parameters/three examples. The real unattended BAT (always system PS5.1) skips safely without a pause. Missing config remains absent; four private session logs per isolated run group exist; successful jobs leave no reserved directories. Successful owned roots were safely cleaned by the existing containment/marker/reparse-aware helper; the local ZIP/reports remain available.

Initial checker preflight exited1 because it compared LICENSE checkout CRLF bytes to canonical Git ZIP LF bytes, **before source generation or application invocation**. Corrected only the checker to compare canonical LICENSE text; PS1/BAT raw-byte checks remain strict. Initial helper/log and its extraction-only root remain local. This is not a suppressed application failure. Project LICENSE itself is unchanged.

A01 covers a freshly extracted **local** tool-only ZIP and documented per-run first-copy route. It does not imply browser download/MOTW validation, an unmodified default-Videos/fresh-account first launch, new Explorer/manual playback, deterministic packaging or published-release acceptance. M5-02/M5-05 retain their own package/reconstruction gates.

## A02-A04 - agreement, coverage and honest claims

README/help/reference agree on PS5.1/BAT versus direct supported PS7, all eleven parameters and incompatible combinations, process-only execution policy, exact quality, oriented height/even rounding, stream omissions, HDR refusal, config behavior, collisions and exits. Plain Get-Help can fail under Restricted PS5.1; README uses a process-only Bypass child command. Named multiple Path values need a PowerShell array; -File/BAT examples use positional selections. Compatible timecode tags can generate a matching MP4 tmcd track despite source data omission. Unknown **source** duration does not waive measurable output-duration validation.

Read-only independent review reconciled config recovery/default known-folder behavior, failed-job versus scan outcomes, retained artifacts/private logs, metadata inheritance, native capability selection and dated owner observations. Resume queue/root/schema/path mismatch or strong-to-fast downgrade refuses; changed readable source/settings/application bytes invalidate completed skips and retry safely; fast-to-strong upgrade retries. **This help-only PS1 edit changes the existing exact-byte fingerprint**, so older manifests can re-encode affected entries under safe rename. That established conservative policy is unchanged and documented.

Troubleshooting explicitly covers all A03 situations without deleting the preference/original as first aid, disabling antivirus, permanent policy weakening, shell-expression metadata or implied dependency installation. A04's verification map links completed M1-M4 evidence and preserves actual dates/scopes. Owner2026-10-07 representative excerpt playback PASS and five-mode physical Ctrl+C, plus prior Explorer/menu evidence, are retained without repeats or broadened approval.

Whole-original/archive-wide/other-player/HDR/calibration judgement, remote SMB/disconnection/arbitrary long paths/power-loss/hostile substitution, console close/Ctrl+Break/crash/detached descendants, genuine default-folder fresh-profile launch and release/package reproducibility remain explicit distribution/release limits. No private media/config/paths/logs are uploaded; no merge/default-branch push/tag/release/settings/secrets/deploy/default-quality change.

## Synchronization and CI

Implementation checkpoint was clean local/live fetch/live push equal at **2026-10-07T18:25:47.365239+00:00**, all **2c2b45362ab14d18fd3c13635fa1d2f987cabc60**. Sole origin is PikkuJanne/WinVidCompress. Implementation [push37666721931](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37666721931) and [PR37666730987](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37666730987) both completed successfully with969/0/0/0 per host, exit0, analyzer1/zero diagnostics; all steps/four sanitized summaries inspected. Push tests exact2c2b453; PR tested merge3a5e56ec4cc5338c7e0f9061583bbf5dcd7dc285 has API-confirmed parents2c2b453/main3b7bc1e. Hosted PS5.1.26100.33438/PS7.6.6, runner image20260925.250.1 (Name null), seven-day sanitized artifacts, Targeted/ReleaseAcceptance=false. Final handoff CI/live refs are inspected after push and reported externally, avoiding a self-SHA loop. A preceding check cannot prove a future handoff commit.

Exact next: **WVC-M5-02 - Build deterministic tool-only release packages and checksums**. Stop after this task/handoff.
