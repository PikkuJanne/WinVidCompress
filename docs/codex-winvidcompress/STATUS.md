# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M1-03 is verified; A01-A04 passed.** M0-01/M0-02/M0-03/M1-01/M1-02/M1-03 are verified; 26 tasks remain todo. Criteria: 24 passed, 104 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

Config now validates object root, OutputDir presence/string/absolute Windows filesystem syntax before property access. Missing config uses an accessible known Videos directory; malformed config is backed up byte-exactly before explicit recovery. Saved offline/inaccessible/file-as-directory destinations stop without preference redirection. Saves use an exclusive persistent sidecar lock, exact stale-snapshot checks, owned flushed/verified temp, no-clobber previous copy and File.Replace/no-clobber File.Move. Failed menu save preserves active preference. Unknown compatible keys survive; excessive depth is refused and older PS7 date normalization/network/external-editor limitations are documented.

Default compression/media behavior and BAT remain unchanged. M1-02 remains verified under owner-approved D005: variable-shaped percent segments such as %PATH% in BAT drop paths use literal menu or direct PS1 routes. Ordinary percent and BAT !NAME! support remain required; historical unsupported BAT percent substitution remains recorded.

## Verification

Clean tested implementation `4582ce187ee7b3179785bc29b7e61352c8e7cb76`, Windows11 Pro10.0.26300 UBR9457, PS5.1.26100.9444 Desktop/PS7.6.5 Core. Existing Pester5.7.1/analyzer1.24.0 reused. Each host Focused47/0/0/0, Quick154/0/0/3 and Targeted168/0/4/3 (passed/failed/skipped/NotRun), exit0. Full both hosts318/6/4/8, exit1: all six failures are M1-04 discovery; four media fixtures lack FFmpeg/FFprobe and eight broader manual/future checks remain NotRun.

Initial overlapping PS7 Quick/Targeted attempts timed out in the harness (4/1/0/0 and18/1/4/0, exit1); retained as failures, then serial reruns passed on the same clean commit. All config criteria are targeted; no config-specific manual/owner gate. Overall Explorer/media/manual requirements remain for applicable tasks/milestone/release acceptance.

[Evidence](evidence/WVC-M1-03.md), [exact JSON commands/results](evidence/WVC-M1-03.json), [session](evidence/WVC-M1-03-session.md). Eighteen raw report/log files and five diagnostic roots archived locally under ignored .test-results with hash equality. Owned diagnostic roots cleaned after process/ownership/containment/reparse checks; fixture ACL restored. No private paths/raw environment values uploaded.

## Git and next task

Feature/upstream `codex/wvc-m1-03-config` / `origin/codex/wvc-m1-03-config` at D:/projects/WinVidCompress-main; sole origin fetch/push URL https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR5; fetched main `2f6f4eed33bf8458f520b90da4b0f24efdd7ec32` contains prior feature work with an identical tree. Draft [PR6](https://github.com/PikkuJanne/WinVidCompress/pull/6) is open; zero implementation CI/check/workflow runs, no CI pass.

Previous clean live local/fetch/push equality at `2026-10-05T15:08:48.811892+00:00` describes implementation4582ce1. Final documentation push/live equality pending when committed and reported externally; no self-SHA loop.

Exact next: **WVC-M1-04 — Normalize file discovery and expose scan failures**. Stop after this bounded handoff. No main push/merge, release/tag, policy/default-quality/deployment or settings/secrets action.
