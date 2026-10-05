# Process, CLI, progress and reporting

## Native adapter

Keep command construction as an argument-token array and execution as a small separate adapter. No Invoke-Expression or dynamically concatenated cmd/PowerShell expressions. Literal path APIs protect filesystem operations; native quoting still needs host-specific argv round-trip tests. .NET Framework/Windows PowerShell 5.1 do not have every API available in PowerShell 7, so verify ProcessStartInfo usage rather than importing a 7-only pattern.

Capture native exit code and stderr. Do not interpret any stderr output as automatic process failure or hide it entirely. Drain both output streams without deadlock. If supporting callbacks/asynchronous readers, clean up resources and consider runspace requirements. Noninteractive stdin/FFmpeg -nostdin must not conflict with a chosen graceful cancellation mechanism. Every bounded probe/doctor call has a timeout. The long-running encoder uses user cancellation and may report a stall without an arbitrary short kill timeout.

The .bat wrapper remains thin. Test actual incoming argv with benign filename fixtures and a recorder. Windows shell expansion, PowerShell -File binding, .bat command-line limits and native argument marshalling are separate layers; avoiding delayed expansion alone does not prove all layers correct. Do not double-evaluate arguments with CALL. Keep interactive and unattended launch modes explicit.

## Supported filename boundary

Owner-approved D005 (2026-10-05): BAT drag/drop excludes environment-variable-shaped percent segments such as `%PATH%` anywhere in the full path. Use menu option 2/3 with a literal path or invoke the PS1 from PowerShell with single-quoted literal string arguments. Ordinary percent names remain supported. Direct Explorer percent substitution is retained as a measured limitation, not repaired behavior. Shell limits and delayed expansion in an outer CMD caller still apply.

## Optional CLI

Preserve positional file/folder paths. Proposed small controls: -OutputDir, -CollisionMode rename|skip, -WhatIf, -CheckEnvironment; opt-in -Resume / -ManifestPath, -PreserveSubfolders and stronger-identity choice may be added as the associated tasks mature. Only expose options actually implemented and tested; no speculative full preset menu. A per-run override does not implicitly rewrite config.

-WhatIf is a genuinely non-writing plan: no config/backup creation, output folders, encode, persistent log or manifest writes. Read-only filesystem inspection and optional native probes are allowed and disclosed. -CheckEnvironment reports dependencies/versions/capabilities and path availability without starting conversion or installing anything. Unattended calls never prompt.

## Result and exit contract

Job records include schema version, job ID, source/output identifiers, outcome, reason/stage, selected streams, applied settings, elapsed time, input/output bytes and size change, and diagnostics/log location. Distinguish completed, skipped, failed, cancelled and unstarted; keep scan errors separate. Counters must reconcile with these records.

Proposed executable exit codes: 0 = completed without failures, including intentional valid skips; 1 = one or more job/scan failures; 2 = startup/config/invalid-request/no-eligible-input failure; 3 = explicit cancellation. Cancellation takes precedence when it actually ends the run. A user quitting/cancelling before requesting a batch exits normally. An explicit invalid/empty unattended batch is not a misleading success. Helpers return results; only the top-level executable entry boundary exits the process.

## Progress/logs

Use FFmpeg machine progress key/value records, not human stderr scraping. Handle partial records, unavailable numeric values and differing timestamp fields. Show file index/total, current state, elapsed and approximate remaining time. Unknown duration produces indeterminate progress; do not divide by zero or invent an ETA. Distinguish encoding, finalizing (including container work), validating and complete.

Keep a concise console view and persistent bounded local text/JSON reports. Record actual versions and settings. Log-write failure must be visible but cannot justify deleting a good final output; define its warning/batch-failure policy consistently. Never upload logs. Provide redacted sharing that removes user-specific roots and filenames/metadata as selected, and document what remains. Test redaction against nested paths, non-ASCII names and FFmpeg diagnostics.

## Cancellation

Cancel active work, stop scheduling the next job, release process/callback resources, and preserve the status of completed jobs. Attempt graceful termination only with a designed bounded mechanism; kill only the owned process/tree if needed. Ctrl+C, console close and hard crash are different cases. Do not promise cleanup under power loss; provenance and subsequent inspection cover those artifacts.
