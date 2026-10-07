# WVC-M4-05 - real Windows workflow acceptance

Recorded 2026-10-07. **WVC-M4-05 verified: A01-A04 passed in their recorded scopes.** Owner confirmed `Playback verdict PASS for all files`, completing A03 for the two prepared sample pairs and the task-local media/manual gate. Broader release/default-quality approval is not implied. Exact commands, source/host bindings, real counts, report hashes and sanitized CI projections are in [JSON](WVC-M4-05.json); [review record](WVC-M4-05-review.md) describes the retained local samples.

## Current implementation and automated gates

Implementation `603decf0da782b4d1d49ad75de1d1b8e12b0c9a9`, following checkpoint `dae8e76f94e5e9fa8c3ae9ffc23283af34a91508`, descends from owner-merged PR28/main `073e4d62633bea4d10954652ea53a198ced579f5`. Application/launcher bytes match the prior implementation (SHA256 dd099c8a... and 0d97c046...). No quality, menu, entry point, layout or source/final policy change.

Actual workstation: Windows 11 Pro10.0.26300 UBR9457/26H2 x64; Windows PowerShell5.1.26100.9444 Desktop and supported PS7.6.6 Core; Pester5.7.1/analyzer1.24.0; existing verified FFmpeg/FFprobe2026-10-04-git-a35c879992. No new downloads, elevation or persistent policy/profile changes. Test APPDATA/output roots are isolated.

| Run | Exact source | Passed/Failed/Skipped/NotRun | Observed exit and interpretation |
|---|---|---|---|
| Clean PS5.1 Quick, known defects included | dae8e76 | 949/0/0/0 | 0, passed |
| Initial clean both-host Full | 603decf | 969/1/0/8 | 1, failed: PS7 whole-suite420000ms timeout; PS5.1: 945 Pester cases and24 shared gates passed |
| Affected PS7 Full alone | 603decf | 969/0/0/8 | 2, incomplete only for seven combined manual rows plus future-coverage row; automation passed |
| Split native directories, four workflow cases each host | 603decf | 4/0/0/0 per host | 0 on each host |
| Changed-file analyzer | dae8e76 and603decf | 1 file/zero diagnostics each | 0 |

The initial timeout remains a failed run, with retained owned diagnostics. Representative sample preparation overlapped that PS7 run; its causal contribution is unproven. Only the affected PS7 full scope was rerun alone; no deadline or test expectation was relaxed. Do not report the initial Full as passed or combine separate reports into an invented single green run. The eight combined NotRun IDs/reasons are preserved verbatim in both Full reports/JSON; dated evidence overlays do not rewrite them.

The four new cases execute byte-identical real PS1/BAT entry points with two synthetic moving-pattern/tone sources and an existing final sentinel. Fresh APPDATA with explicit output leaves config absent intentionally. Legacy OutputDir-only PS1/BAT and extended saved preferences preserve exact config bytes. Both actual host suites check exit/Done2, source/final hashes, two flat outputs/no leftover directories, H264/AAC/geometry/duration, exact filename-derived artist/date, full video/audio decode and two matching Completed log records. Native tools in separate directories are supported and tested; BAT itself selects PS5.1 even from a PS7 Pester parent. Structural/decode success does not establish perceptual integrity.

Initial exploratory test-summary assertion failures0/4 and empty-FFREPORT report creation are retained locally, then corrected before clean acceptance runs. Initial representative verification assumed optional color_range and failed in the verifier; corrected nullable inspection passed. Actual representative encoding/decode was successful, and no explicit output color_range tag or visual range acceptance is invented.

## Hosted CI and A01

Actual [implementation push37655443989](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37655443989) completed successfully: both Windows hosts969/0/0/0, exit0, one changed file/zero diagnostics. Both sanitized summary artifacts and upload steps were inspected: exact source603decf, allowlisted fields/ordinal cases, no raw/private paths/logs, ReleaseAcceptance=false. Artifacts expire after seven days; mutable runner OS/image versions remain reported.

Actual [PR37655449563](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37655449563) failed before starting any jobs, with zero jobs/artifacts/check runs. GitHub's run page reports `Internal server error`, correlatione3dddbf1-6db8-4208-92be-cf38d2c6622a. Two `gh run rerun 37655449563` attempts returned HTTP500; subsequent metadata remained attempt1/failure. That run was reproducibly infrastructure-blocked, with no tested merge SHA or pass for it claimed. A01 explicitly permits reproducibly blocked gates; successful local supported-host scopes and exact push CI are recorded separately. Subsequent handoff results follow below.

Subsequent [handoff push37659526964](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37659526964) and [PR37659531727](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37659531727) both succeeded:969/0/0/0 per host, exit0, all steps and four sanitized artifacts inspected. Push tested exact `bfef3942f6ffbda417bf12951bcc8b166a96bad1`; PR tested merge `e702a94bd9cc612e13e7306c8e8ccd8ae72e0ead`, with API-confirmed parentsbfef394 and main073e4d6. Changed-file analysis covered0 files on the documentation-only push and1 on PR, zero diagnostics. Earlier pre-job failure remains historical; subsequent PR execution supplies positive evidence. ReleaseAcceptance=false remains explicit. The final acceptance-record commit's own CI will be inspected externally after push.

## Retained Explorer observations and A02/A04

A02 passes from composite dated owner evidence under D005, without asking for repeats: [M1-02](WVC-M1-02.md) and JSON401/486/545 retain single-file, folder, ten-file supported punctuation/Unicode selections and literal menu paths on2026-10-05; [owner2026-10-07 menu/Quit/prompt](MANUAL-2026-10-07.md) and [five-mode physical Ctrl+C35/0](MANUAL-CANCEL-2026-10-07.md) remain passing. Historical unsupported variable-shaped percent BAT corruption and initial cancellation26/9 stay intact. Launcher recorders prove binding/selection, while controlled cancellation fixtures have their stated synthetic limits; this is not a newly performed current-source Explorer matrix.

A04 passes from actual Windows PS5.1/PS7 execution, unchanged real Explorer/cancellation observations, owner representative playback PASS, source/report provenance and honest task/manual state. No Linux/mocked result or fixture preparation supplies human/release acceptance.

## Representative preparation and A03

Owner answered the explicit local-source approval request on2026-10-07: `Theres two interview videos in Downloads folder`. Exactly two identified interview files were copied into an owned temporary root; original and full-copy hashes match after preparation. Private names, paths, tags, full-media/sample hashes, probes and logs remain local only. No private media was uploaded or committed.

Each approved copy supplied a stream-copy excerpt requested at30s for20s. Keyframe padding produced23.136016s/24.48s source samples; current default PS7 PS1 sequential batch produced23.12s/24.48s outputs with exit0/Done2. Both geometry/duration/audio/filename-metadata/full-decode/source-safety checks passed on clean603decf. The owner was shown both SOURCE/OUTPUT pairs and the retained folder in Explorer, then asked PASS/FAIL/UNSURE for picture/orientation, duration, speech/synchronization and face/text detail. Owner2026-10-07 answered **`Playback verdict PASS for all files`**. A03 passes from that actual observation plus automated filename metadata read-back; no separate human metadata-property inspection is claimed. This supersedes the pending-playback state in the precedingbfef394 handoff. Sample acceptance does not establish whole-interview integrity or archive/other-player/HDR quality, nor authorize default-quality changes.

## Remaining limits and corrected bounded scope

The initial preparation treated unmodified default-MyVideos first launch as a possible additional task gate. The original brief requires new-user/upgraded-config workflows, without that separate destination-route criterion. Native missing-config CLI override and legacy/extended saved workflows exercise step2 on the active workstation. Unmodified MyVideos first launch remains not_run as a distribution/support limit; it requires an isolated Windows profile because APPDATA does not redirect that known folder. No requirement in A01-A04 was removed and no owner profile/actual Videos directory was touched.

| Severity | Remaining observation/support limit | Acceptance/release impact |
|---|---|---|
| High | Unmodified default-Videos first launch; candidate ZIP/clean extraction/reproducibility/package smoke | Distribution/release limits and later M5 work; tested fresh CLI override is not default-folder acceptance |
| High | Broader remote/disconnected SMB, arbitrary long paths/filesystems, power loss and hostile substitution | Existing release-blocking limits retained from M4-03; local240/300-character roots are bounded passing evidence |
| High | Console-close/Ctrl+Break/crash/detached descendants | Broader cancellation acceptance remains unobserved; five-mode physical Ctrl+C remains passed |
| Medium | D005 variable-shaped percent BAT path components and CMD expansion/length/spelling limits | Owner-approved supported-route boundary; literal menu/direct PS1 alternatives and historical failures retained |
| Historical CI block | Earlier GitHub PR pre-job internal error/HTTP500 | Preserved failure; laterbfef394 push/PR both passed, so this is no longer the current PR-execution blocker |

Previous clean/live implementation equality at2026-10-07T16:52:25.871408+00:00 describes603decf only; followup-start clean equality at2026-10-07T17:38:36.688684+00:00 describesbfef394. Root alone wrote the checkout; internal agents performed read-only audits. Final acceptance handoff local/live fetch/live push SHA and current draft PR29/CI state will be reported externally after push. Exact next: **WVC-M5-01 - Write onboarding, help and troubleshooting for actual behaviour**. Stop after this task's acceptance handoff.

Clean source reconstruction used `git clone --single-branch --no-tags --branch codex/wvc-m4-05-acceptance https://github.com/PikkuJanne/WinVidCompress.git .test-results/m405/reconstruction`, then `tools/codex-winvidcompress/validate_tracker.py --repo .test-results/m405/reconstruction` with the existing bundled Python. At603decf the clone was clean and tracker valid32 tasks/128 criteria/23 improvements; product PS1/BAT raw bytes and all three canonical Git blobs matched. Initial raw test-PS1 equality failed because localLF becomes cloneCRLF under .gitattributes; the canonical test blob matched. JSON retains this result. Final clone fast-forward will be checked externally after handoff push; this source reconstruction does not establish package/ZIP/fresh-account acceptance.

The preceding handoff clone was fast-forwarded with `git -C .test-results/m405/reconstruction fetch origin` then `git -C .test-results/m405/reconstruction merge --ff-only origin/codex/wvc-m4-05-acceptance`: cleanbfef394, eleven canonical files and both product-entry byte sequences matched; tracker valid. This acceptance followup changes only records. Existing applicable local tests/CI remain evidence; no long native suite or media preparation was repeated for the owner verdict.
