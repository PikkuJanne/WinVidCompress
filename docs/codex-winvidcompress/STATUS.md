# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M2-03 is verified, A01-A04 passed.** Tasks: 11 verified/1 implemented/20 todo. Criteria: 46 passed/2 skipped/80 not_run. TASKS.json is authoritative. M2-02 remains implemented, A01/A03 skipped pending actual output confirmation. No milestone/release acceptance.

## Behavior and boundaries

Pure encoder tokens preserve maps, profile, height cap and filename metadata; `-nostdin`/closed child stdin protect menu input. The native adapter uses tested Windows quoting and concurrent UTF-8 chunk drains/live console diagnostics on both hosts. Results separate native exit/status/error/stdout/stderr; capture tails are bounded1048576 characters per stream with totals/truncation and a caller warning. No PowerShell callbacks, no total encoding deadline, bounded10-second post-exit drains and2-second direct-owned termination. Explicit readers/input/process cleanup and fatal cleanup propagation stop another job from starting.

Prior config/launcher/path/queue/environment/probe/stream behavior remains. Unique-default-or-first audio, silent source maps, omission reports, no -ac/-ar/-r override and compression defaults stay. D005 supported launcher boundary/prior owner observations are retained. Actual encoded identity/silent completion/channel/tag read-back remain unverified without tools. M2-04/M2-05 implement owned temporary publication/media validation; progress/full cancellation/geometry/manifests remain later. Direct process only; filesystem/network/process-start calls lack total deadlines. Done still reflects native execution success.

## Verification

Clean implementation `c2e714589afc8bcc910ae9ea8e6aad0fc5ace218`, Windows11 Pro10.0.26300 UBR9457 (26H2), PS5.1.26100.9444/PS7.6.5, existing Pester5.7.1/analyzer1.24.0. Each host Focused 122/0/2/0, Quick 305/0/2/0, Targeted 321/0/6/0, ManualArgv 3/0/0/0, all exit0, serial. Six pure/ten real native/one fatal-queue cases added. A02 agent-executed native argv inspection displays three PASS rows per host with exact comparisons/source hashes; no owner visual approval required. Eight Targeted entry cases pass. Focused/Quick skip two existing real-output checks; Targeted six media skips total. No new Explorer/Full/media/CI/milestone/release pass. [Evidence](evidence/WVC-M2-03.md), [exact commands](evidence/WVC-M2-03.json), [session](evidence/WVC-M2-03-session.md). Read-only review found no remaining material blocker; raw artifacts remain ignored .test-results/m203.

## Git and next task

Feature/upstream `codex/wvc-m2-03-process` / `origin/codex/wvc-m2-03-process` at D:/projects/WinVidCompress-main; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR11; inspected main `2be234cf79eba6c413e6a13c624d929bab7f688a` retains prior feature/reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/12); implementation CI 0 checks/0 statuses/0 workflow runs. Clean implementation live local/fetch/push equality at `2026-10-05T18:24:44.059808+00:00`. Final handoff commit/push equality is reported externally, avoiding self-SHA embedding.

Exact next task: **WVC-M2-04 - Implement owned temporary output and no-clobber promotion**. Retain M2-02 actual-output skips until already-installed tools supply both-host confirmation. No new approval/code blocker. Stop after this handoff.
