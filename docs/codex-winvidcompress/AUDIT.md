# Baseline source audit and verification limits

Repository: `PikkuJanne/WinVidCompress`. Observed main commit: `5bab7fc698d153128babe3421ce19c0ca3012cc5`. Rechecked on 2026-10-04 using the GitHub connector. Files and blob IDs are in BASELINE.json. Source links in SOURCES.md are pinned to that commit. No Windows runtime or private interview footage was tested during bundle preparation. No repository write was made.

| Finding from the reviewed source | Evidence location | Required verification/action |
|---|---|---|
| Quit uses break inside switch inside an outer while loop | Run-TUI | Reproduce and fix function/outer-loop exit. See Microsoft break documentation. |
| Launcher enables delayed expansion and reconstructs argument text | WinVidCompress.bat | Characterize exact Windows argv; include ! and % variable-shaped names. |
| Config JSON parsing is protected but property access/type assumptions follow it | Load-Config | Exercise syntactically valid wrong-shaped JSON under strict mode. |
| Missing saved output paths are reset to Videos and saved | Load-Config | Separate unavailable drives from malformed config. |
| Folder prompt creates a missing path even for source selection | Prompt-Path / Run-TUI | Source validation must not create source folders. |
| Enumeration accesses FullName after a pipeline and processes selections separately | Collect-InputFiles / Process-Paths | Verify zero/one/many shape and overlapping selections; snapshot/dedupe first. |
| Probe reads only v:0 height and hides stderr without explicit exit validation | Get-VideoHeight | Structured probe and failure handling. |
| Encode has no explicit mapping | Compress-One | Probe/encode stream selection can diverge; select once, map explicitly. |
| Encoding writes directly to final filename with -n; success uses native exit code | Compress-One | Preserve no-overwrite intent; add temporary output, validation and no-clobber promotion. |
| Scaling uses scale=-2:1080 only after source-height check | Compress-One | Test rotation/display geometry, odd dimensions and aspect ratio without new defaults. |
| Metadata date regex constructs strings without calendar validation | Parse-MetadataFromName | Validate real dates without blocking compression. |
| No explicit batch exit-code contract, persistent log or resume manifest | Process-Paths / main | Add structured results and opt-in safe recovery. |

The tree read at the review anchor contains the main script/launcher, README, LICENSE and three existing visual assets; it has no test/CI directory. The earlier release read returned an empty release list. Recheck releases, tags, branches, issues and current files locally before versioning; do not infer current state indefinitely from this note.

## Review caveats

These are code-inspection findings, not claims that every failure was executed. Native argument marshalling, Explorer launch semantics, scalar/array behaviour, filesystem races and media-format details need the exact targeted tests in this bundle. A failed reproduction should lead to a documented refinement of the finding, not a fabricated bug or an unnecessary rewrite. Read current code before applying any recommendation.
