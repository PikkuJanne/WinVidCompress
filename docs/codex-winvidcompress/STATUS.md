# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M2-01 is verified; A01-A04 passed.** M0/M1 tasks and M2-01 are verified: 10 verified/22 todo, 40 criteria passed/88 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

One bounded UTF-8 all-stream/format JSON probe replaces height-only probing. Structured native/source/JSON/video failure retains diagnostics and stops encoding. Normalization preserves stream indices/dispositions, coded geometry/rotation/SAR/DAR, pixel/colour/frame-rate/time-base metadata, audio details and nullable duration. Artwork is excluded from first-real-video candidates. Unknown/invalid duration remains null with indeterminate-progress warning and an unavailable duration-comparison limitation. Parsing is invariant; extra fields tolerated.

Compression uses first-real-video coded height, while encoder selection remains automatic until M2-02. DisplayGeometry is null/MetadataOnly; display transforms remain M3-01. Probe file whitelist/playlist response checks do not guarantee offline encoder execution or eliminate UNC access. Native calls have process/pipe deadlines plus bounded direct-process cleanup; filesystem/network/process-start calls lack total deadlines and detached descendants are not tracked.

Prior config/launcher/path/queue/environment acceptance remains. PATH-before-adjacent exact dependency/capability checks, read-only doctor config and disclosed temporary destination write checks remain verified. Destination capacity is advisory. Queue freezes paths, not immutable bytes/file IDs. Source-change checks, owned media-temp/no-clobber promotion, structural validation and manifests remain later tasks. Defaults, menu/drag-drop boundary, flat output, sequential batches and FFmpeg -n remain.

## Verification

Clean implementation `8efa0b82224fd1793715b2f7369697c71b73fb87`, Windows 11 Pro 10.0.26300 UBR9457 (26H2), PS5.1.26100.9444/PS7.6.5. Existing pinned Pester5.7.1/analyzer1.24.0; each host Focused123/0/0/0, Quick275/0/0/0, Targeted291/0/4/0, exit0, serial. Forty-four Probe regressions include actual native JSON/UTF-8/exit/timeout and encoder refusal/hash checks. Eight entry cases pass. Four media skips per Targeted host lack FFmpeg/FFprobe. No actual binary/media success, new Full/manual/Explorer or CI pass claimed. Existing owner manual evidence is retained.

[Evidence](evidence/WVC-M2-01.md), [exact commands/results](evidence/WVC-M2-01.json), [session](evidence/WVC-M2-01-session.md). Read-only review found no remaining material blocker. Raw reports/logs remain ignored .test-results/m201; passing roots cleaned.

## Git and next task

Feature/upstream `codex/wvc-m2-01-probe` / `origin/codex/wvc-m2-01-probe` at D:/projects/WinVidCompress-main; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR9; inspected base `118d5f1534a82d06b6fc534a6c5e03237d45faff` retains prior feature and reviewed baseline ancestry. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/10); implementation CI 0 checks/0 statuses/0 workflow runs.

Clean live local/fetch/push equality at `2026-10-05T17:30:34.704492+00:00` describes implementation `8efa0b82224fd1793715b2f7369697c71b73fb87`. Final documentation commit/push equality is pending here and reported externally; no self-SHA loop.

Exact next: **WVC-M2-02 - Select and map the same real video and intended audio**. No M2-01 task blocker/new owner approval. Stop after this handoff.
