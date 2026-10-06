# Full acceptance matrix

The 128 task-level criteria in TASKS.json are the primary acceptance checklist. This cross-cutting matrix prevents end-to-end gaps. Every row begins NOT RUN; populate evidence, never pre-fill a pass.

| Area | Required scenarios | Evidence method | Initial status |
|---|---|---|---|
| ENTRY | Double-click menu/Quit; single/file-folder/multi-drop; unattended exit | Windows Explorer + both shells | M2-06 unattended/native scripted menu continuation PASSED ([evidence](evidence/WVC-M2-06.md)); new actual Explorer observation and broader entry acceptance remain NOT RUN; prior D005 evidence retained |
| ARGV | Spaces, !, ordinary %, !NAME!, &, (), apostrophes, [], Unicode; %PATH% through menu/direct PS1 under D005; long selection limits | Native recorder + actual Windows launch | NOT RUN |
| CONFIG | Missing, malformed, wrong-shaped JSON; file-vs-dir; offline drive; failed save | Pester + filesystem fault injection | PASSED for [M1-03](evidence/WVC-M1-03.md); actual disconnected-share/crash durability untested |
| SCAN | Zero/one/many files; inaccessible subtree; invalid explicit input; reparse cycle | Pester + disposable filesystem | PASSED A01-A04 for [M1-04](evidence/WVC-M1-04.md); tested localhost UNC/local paths only, broader SMB/media limits recorded |
| QUEUE | Overlap, duplicates, same input/output root, nested destination, originals named compressed | Queue tests + integration | PASSED A01-A04 for [M1-05](evidence/WVC-M1-05.md); both Windows hosts, synthetic file-writing recorders; file-ID/source-change/ownership/media limits recorded |
| TOOLS | PATH/adjacent selection, invalid executable, missing encoder, timeout, destination write access | Controlled real native processes + actual Windows ACL | PASSED A01-A04 for [M1-06](evidence/WVC-M1-06.md); both hosts; actual FFmpeg absent/media skipped; filesystem/descendant limits recorded |
| PROBE | Probe failures, audio-only, attached pictures, missing/invalid duration, malformed probe JSON | Fixture JSON + synthetic native processes/files | PASSED A01-A04 for [M2-01](evidence/WVC-M2-01.md); both hosts; real FFmpeg/media omitted; mapping/transforms later |
| STREAM | Multiple video/audio streams, artwork, silent clip, discarded types | Native argv recorder + plan/report + actual output probe | PASSED A01-A04 [M2-02](evidence/WVC-M2-02.md); prior media skips closed by existing both-host installed-tool cases during [M3-01](evidence/WVC-M3-01.md), history retained |
| NATIVE | Exact encoder tokens/argv, large concurrent streams, native exits, stdin, inherited pipes and owned cleanup | Pure cases + actual Windows native processes + explicit both-host argv inspection | PASSED A01-A04 for [M2-03](evidence/WVC-M2-03.md); full cancellation/progress/media publication remain later |
| GEOMETRY | Small, 1080p, 4K, portrait, rotation, odd dimensions, SAR, ultrawide | Probe + decoded patterns + owner source/output viewing | PASSED A01-A04 [M3-01](evidence/WVC-M3-01.md), both Windows hosts/current installed build, no forced FPS; owner six-pair PASS; broader playback/colour compatibility remains separate |
| COLOUR | SDR, 10-bit SDR, PQ/HLG metadata, ambiguous colour fields | Synthetic/JSON + owner visual review | NOT RUN |
| METADATA | Valid dates, leap day, impossible dates, ambiguous digits, Unicode/tag precedence | Unit + tag read-back | NOT RUN |
| TEMP | Failure/start/cancel/validation/promotion; own-only cleanup | Fault injection + sentinel hashes | PASSED M2-04 failure/start/promotion/retention subset ([evidence](evidence/WVC-M2-04.md)); structural validation/retention subset PASSED [M2-05](evidence/WVC-M2-05.md); result/controlled cancellation/retention subset PASSED [M2-06](evidence/WVC-M2-06.md); full cancellation remains NOT RUN |
| COLLISION | Existing output, source=nominal-final, two concurrent instances | No-clobber integration | PASSED A01/A02 for [M2-04](evidence/WVC-M2-04.md), both hosts, actual concurrent native barrier workers and unchanged sentinel hashes; UNC/durability remain unaccepted |
| VALIDATE | Exit zero with bad/empty/wrong/truncated output, unknown duration | Probe mocks + integration | PASSED A01-A04 [M2-05](evidence/WVC-M2-05.md), both actual hosts with file/metadata faults and native probe processes; existing real-media decode/timing cases passed during [M3-01](evidence/WVC-M3-01.md) on the recorded installed build; structural checks do not prove full visual/audio integrity |
| RESULT | Success, skip, failed, cancelled, scan errors, no eligible inputs | Exact exit/counter assertions | PASSED A01-A03 [M2-06](evidence/WVC-M2-06.md), both actual Windows hosts and native exits; controlled cancellation only. A04 manual Explorer menu/prompt observation NOT RUN |
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
