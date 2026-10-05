# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M2-02 is implemented: A02/A04 passed; A01/A03 skipped pending actual output confirmation.** Tasks: 10 verified/1 implemented/21 todo. Criteria: 42 passed/2 skipped/84 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

One bounded UTF-8 JSON inspection returns normalized metadata and nullable duration; malformed/no-real-video failures stop encoding. M2-02 reuses its first-real-video object/index for coded height and explicit absolute video map. Unique default audio wins, otherwise first audio by index; silence gets no audio map/options. Selected channels/layout/rate/language/dispositions and every omitted index/type/reason appear in the plan/console. No channel/sample-rate/FPS overrides, invented audio or default-quality change. Explicit unknown stream types remain identifiable.

Actual encoded stream identity, silent completion and channel/metadata read-back remain unverified. Selected metadata/dispositions rely on FFmpeg mapped-stream defaults. DisplayGeometry remains null/MetadataOnly until M3-01; native encoder execution remains the previous adapter until M2-03. Progress/transaction/structural validation/source-change/manifests remain later tasks.

Prior config/launcher/path/queue/environment/probe acceptance remains. Defaults, flat outputs and sequential batches stay. Queue freeze covers paths, not immutable content/file IDs. Probe file whitelist does not guarantee offline encoding or eliminate UNC access. Filesystem/network/process-start calls lack total deadlines; bounded cleanup tracks direct owned processes only. Destination capacity remains advisory. Existing owner manual observations remain retained.

## Verification

Clean implementation `ed3a91676c350d6718741d30b7b9f4127286f528`, Windows11 Pro10.0.26300 UBR9457 (26H2), PS5.1.26100.9444/PS7.6.5. Existing Pester5.7.1/analyzer1.24.0; each host Focused 105/0/2/0, Quick 288/0/2/0, Targeted 304/0/6/0, all exit0, serial. Thirteen Stream regressions plus prior affected coverage; eight Targeted entry cases pass. FFmpeg/FFprobe absent PATH/adjacent: two real-output tests skipped in all scopes plus four existing Targeted media skips. No actual-media/Full/new manual/Explorer/CI pass. [Evidence](evidence/WVC-M2-02.md), [exact commands/results](evidence/WVC-M2-02.json), [session](evidence/WVC-M2-02-session.md). Read-only review found no material blocker; raw reports/logs remain ignored .test-results/m202.

## Git and next task

Feature/upstream `codex/wvc-m2-02-streams` / `origin/codex/wvc-m2-02-streams` at D:/projects/WinVidCompress-main; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR10; inspected base `aac681a0f8873792dc46e9ba599801d4ff11f9b4` retains prior feature and reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/11); implementation CI 0 checks/0 statuses/0 workflow runs.

Clean live local/fetch/push equality at `2026-10-05T17:55:31.725417+00:00` describes implementation `ed3a91676c350d6718741d30b7b9f4127286f528`. Final documentation commit/push equality is pending here and reported externally; no self-SHA loop.

Exact next safe task: **WVC-M2-03 - Isolate command construction and native process execution**. M2-02 usable implemented behavior satisfies the dependency under INDEX. A01/A03 require installed-tool confirmation before verification; no new owner approval or code blocker. Stop after this handoff.
