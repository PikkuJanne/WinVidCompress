# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M2-04 is verified, A01-A04 passed.** Tasks: 12 verified/1 implemented/19 todo. Criteria: 50 passed/2 skipped/76 not_run. TASKS.json is authoritative. M2-02 remains implemented, A01/A03 skipped pending actual output confirmation. No milestone/release acceptance.

## Behavior and boundaries

Each encode uses a reserved GUID job directory on the destination volume, an independent exclusive provenance handle and an initially absent temporary MP4 with -n. File.Move refuses an existing final; rename collisions retry safely from the original basename, while skip retains the unused partial. Successful finals remain flat. Failure/ambiguous media is retained with stage/reason/provenance; cleanup never deletes media by path or recurses. Fatal encoder termination preserves even an empty job. Later batches warn about reserved jobs and discovery excludes their contents. Done requires native success and publication; structural validation remains M2-05.

PS1/BAT/menu/sequential batches/default libx264/veryfast/CRF22/AAC160k/faststart/no-upscale height policy/maps/filename metadata remain. Native stderr/exit/tails and direct-owned cleanup remain M2-03. Ordinary compressed/partial names remain inputs. D005 prior owner launcher observations are retained. Full cancellation, durable manifests/recovery, hostile file substitution, UNC/atomicity/power-loss and real encoded-output confirmation remain unaccepted boundaries.

## Verification

Clean implementation `731fa2fce26ad2fbc8b42b2ea2c54fbf8804015e`, Windows11 Pro10.0.26300 UBR9457 (26H2), PS5.1.26100.9444/PS7.6.5, existing Pester5.7.1/analyzer1.24.0. Each host Focused 169/0/2/0, Quick 331/0/2/0, Targeted 347/0/6/0, Full 347/0/6/8, serial. Focused/Quick/Targeted exit0; Full risk gate executed, zero failures but exit2/Incomplete with seven manual and one future coverage row NotRun. 23 unit and three actual concurrent native collision cases per host, plus eight Targeted entry cases, passed. Focused/Quick skip two real-output checks; Targeted/Full six media skips total without FFmpeg/FFprobe. Recorders write synthetic sentinels, not valid media. No Full/Explorer/playback/cancellation/CI/milestone/release pass. [Evidence](evidence/WVC-M2-04.md), [exact commands](evidence/WVC-M2-04.json), [session](evidence/WVC-M2-04-session.md). Read-only review found no remaining material blocker; raw artifacts remain ignored .test-results/m204.

Focused/Quick used clean production 6bed80c; Targeted/Full used clean 731fa2f after isolating each entry fixture's output/config. The first Targeted had four fixture failures caused by retained successful sentinels in a shared folder; corrected eight-case smoke and both-host Targeted/Full passed all executed checks. Product PS1 bytes are unchanged between those commits.

## Git and next task

Feature/upstream `codex/wvc-m2-04-output` / `origin/codex/wvc-m2-04-output`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR12; inspected main `e7e5bd600bea01e33fd6368dd203b395ed7d0b83` retains prior feature/reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/13); implementation CI 0 checks/0 statuses/0 workflow runs. Clean implementation live local/fetch/push equality at `2026-10-05T19:00:32.694633+00:00`. Final handoff SHA/live equality is reported externally after commit.

Exact next task: **WVC-M2-05 - Validate output before marking it complete**. Retain M2-02 actual-output skips and Full manual/future rows. No new approval/code blocker. Stop after this handoff.
