# WVC-M1-06 evidence - 2026-10-05

**Verified; A01-A04 passed.** Clean implementation `a91bfa6b2d35839e3296570843beeeb34a81f2ef` on Windows 11 Pro 10.0.26300 UBR9457 (26H2), Windows PowerShell 5.1.26100.9444 Desktop and PowerShell 7.6.5 Core. Existing Pester 5.7.1/analyzer 1.24.0 reused without downloads. [Exact commands, counts, report hashes and limitations](WVC-M1-06.json).

Each host, serial runs: Focused **112/0/0/0**, Quick **231/0/0/0**, Targeted **247/0/4/0** (passed/failed/skipped/NotRun), all exit 0. Quick/Targeted reports independently record the exact implementation SHA and Dirty=false. Thirty-one Environment cases exercise actual Windows synthetic native processes; eight Targeted entry cases include two actual PS1 doctor launches alongside existing direct/BAT/menu dispatch. Four Targeted media fixtures per host lack FFmpeg/FFprobe. No real FFmpeg/media, new Full/manual/Explorer or milestone/release pass is claimed.

## Behavior and acceptance

- A01: actual application resolution; missing/unreadable/non-executable/wrong/swapped binaries and unsupported exact encoders/muxer/filter/probe responses fail before config load/conversion. PATH remains before adjacent copies; command shadows are refused.
- A02: doctor reports exact binary paths, versions/build details and required capabilities. It reads existing preferences without saving/recovery/locks; absent config stays absent. Child FFREPORT is removed, with the parent environment intact. Runtime has no dependency download/replacement or PATH change.
- A03: seven calls have separate 10-second process/pipe deadlines, PS5.1-compatible argv marshalling, concurrent drain, native exit/stderr diagnostics and bounded failure cleanup. Actual hang/inherited-pipe/large-dual-stream/argv regressions pass on both hosts without elevation.
- A04: a GUID/CreateNew one-byte write/flush with DeleteOnClose proves current create/write/remove access in the existing destination. Actual create-file ACL denial preserves config bytes and active menu preference; unavailable local/injected drive/UNC paths do not redirect. Checks run at startup, before menu save and before each batch. Capacity low/unknown reports are advisory and never guarantee output size.

Doctor's disclosed temporary file is its only filesystem write; it creates no config, backups or output folders. Source/final sentinels and output directory contents remain unchanged after checks. Capacity is unknown on UNC/reparse/mount-point destinations. Windows filesystem/network calls and process creation are outside a total startup deadline. Timeout cleanup tracks only the directly started process; detached descendants are not tracked. Current media probing/encoding and later transaction/validation/source-change/manifest work remain outside this task.

## Git and review

One root writer; subagent design/final review was read-only and found no final material issue. Minimal integration scope additions keep existing entry/launcher/menu/config tests and manual fixture usable; no human check was repeated. Legacy application encoding/CRLF and compression defaults remain. Passing fixture roots are cleaned; raw draft/final reports remain local under ignored .test-results/m106. Draft harness failures and their fixes are retained in JSON/session evidence.

Implementation checkpoint was pushed on `codex/wvc-m1-06-environment` and clean live local/fetch/push equality was verified at `2026-10-05T17:07:35.638654+00:00`. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/9); implementation CI: 0 checks, 0 statuses, 0 workflow runs. No CI pass inferred. Final documentation commit/push equality is pending inside this record and reported externally after that commit.

Exact next: **WVC-M2-01 - Expand FFprobe into normalized JSON media inspection**. No M1-06 owner approval/task blocker; broader milestone/release gates remain. Stop after this task.
