# Full acceptance matrix

The 128 task-level criteria in TASKS.json are the primary acceptance checklist. This cross-cutting matrix prevents end-to-end gaps. Every row begins NOT RUN; populate evidence, never pre-fill a pass.

| Area | Required scenarios | Evidence method | Initial status |
|---|---|---|---|
| ENTRY | Double-click menu/Quit; single/file-folder/multi-drop; unattended exit | Windows Explorer + both shells | NOT RUN |
| ARGV | Spaces, !, ordinary %, !NAME!, &, (), apostrophes, [], Unicode; %PATH% through menu/direct PS1 under D005; long selection limits | Native recorder + actual Windows launch | NOT RUN |
| CONFIG | Missing, malformed, wrong-shaped JSON; file-vs-dir; offline drive; failed save | Pester + filesystem fault injection | PASSED for [M1-03](evidence/WVC-M1-03.md); actual disconnected-share/crash durability untested |
| SCAN | Zero/one/many files; inaccessible subtree; invalid explicit input; reparse cycle | Pester + disposable filesystem | NOT RUN |
| QUEUE | Overlap, duplicates, same input/output root, nested destination, originals named compressed | Queue tests + integration | NOT RUN |
| TOOLS | PATH/adjacent selection, invalid executable, missing encoder, timeout | Mocks + installed-tool check | NOT RUN |
| PROBE | Corrupt input, audio-only, attached pictures, missing duration, malformed probe JSON | Fixture JSON + synthetic files | NOT RUN |
| STREAM | Multiple video/audio streams, silent clip, discarded subtitles/data | Synthetic media + output probe | NOT RUN |
| GEOMETRY | Small, 1080p, 4K, portrait, rotation, odd dimensions, SAR, ultrawide | Probe + visual test patterns | NOT RUN |
| COLOUR | SDR, 10-bit SDR, PQ/HLG metadata, ambiguous colour fields | Synthetic/JSON + owner visual review | NOT RUN |
| METADATA | Valid dates, leap day, impossible dates, ambiguous digits, Unicode/tag precedence | Unit + tag read-back | NOT RUN |
| TEMP | Failure/start/cancel/validation/promotion; own-only cleanup | Fault injection + sentinel hashes | NOT RUN |
| COLLISION | Existing output, source=nominal-final, two concurrent instances | No-clobber integration | NOT RUN |
| VALIDATE | Exit zero with bad/empty/wrong/truncated output, unknown duration | Probe mocks + integration | NOT RUN |
| RESULT | Success, skip, failed, cancelled, scan errors, no eligible inputs | Exact exit/counter assertions | NOT RUN |
| PROGRESS | Partial/N/A records, no duration, container finalization, validation stage | Parser + native integration | NOT RUN |
| CANCEL | Ctrl+C, console close, crash leftovers; unrelated FFmpeg survives | Real Windows + process isolation | NOT RUN |
| RESUME | Changed source/settings, missing/corrupt output, foreign manifest, stronger hash | Manifest integration | NOT RUN |
| PREVIEW | No config, folder, log, output or manifest writes | Before/after filesystem snapshots | NOT RUN |
| LAYOUT | Flat default, relative roots, repeated names, traversal/reparse containment | Path plan + filesystem tests | NOT RUN |
| SAVINGS | Smaller/larger output, unknown size, genuine timings | Arithmetic unit + measured benchmark | NOT RUN |
| LOGS | Persistent reports, error stage, redacted sharing, write failure | Unit + diagnostic fixture | NOT RUN |
| CI | PS5.1 + supported PS7, least privilege, exact pushed commit results | Actual GitHub workflow inspection | NOT RUN |
| PACKAGE | Allowlist, source version, SHA-256, reproducibility, fresh ZIP extraction | Build + clean-workstation smoke | NOT RUN |
| WEBSITE | Draft-vs-release metadata, actual screenshots, no uploads/false links | Schema/content review; no deployment | NOT RUN |
| SYNC | Correct origin and push endpoint, clean worktree, matching live feature SHA | Live remote query + clean-clone reconstruction | NOT RUN |

Release blockers include source/final overwrite risk, unsafe cancellation/cleanup, false completion, silent output redirection, known unsupported launcher corruption, failing required automated checks, missing required manual Windows acceptance and unverified final GitHub synchronization. Cosmetic/editorial limitations can be documented separately without calling safety gaps cosmetic.
