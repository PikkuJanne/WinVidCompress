# Traceability: all 23 reviewed improvements

| Review | Improvement | Tasks |
|---|---|---|
| 01 | Correct the text-menu Quit option | WVC-M1-01 |
| 02 | Harden launcher and native argument handling | WVC-M1-02, WVC-M2-03 |
| 03 | Validate, recover and safely save configuration | WVC-M1-03 |
| 04 | Handle empty folders, invalid paths and source/output selection | WVC-M1-01, WVC-M1-04 |
| 05 | Snapshot and deduplicate batches; avoid re-ingesting generated outputs | WVC-M1-05, WVC-M4-03 |
| 06 | Transactional temporary output and post-encode validation | WVC-M2-04, WVC-M2-05, WVC-M4-03 |
| 07 | Structured FFprobe media inspection | WVC-M2-01 |
| 08 | Explicit matching video/audio stream selection | WVC-M2-02, WVC-M2-03 |
| 09 | Rotation-aware, no-crop/no-upscale resizing | WVC-M3-01 |
| 10 | Explicit SDR/pixel-format policy and conservative HDR handling | WVC-M3-02 |
| 11 | Validate filename-derived metadata dates | WVC-M3-03 |
| 12 | Report size savings and benchmark the existing preset | WVC-M3-04 |
| 13 | Machine-readable per-file and batch progress | WVC-M3-05 |
| 14 | Persistent logs, structured results and process exit codes | WVC-M2-06, WVC-M3-05 |
| 15 | Safe cancellation and batch-level retry/resume | WVC-M3-06, WVC-M3-07, WVC-M4-03 |
| 16 | Optional CLI controls and preserve-subfolders mode | WVC-M4-01, WVC-M4-02 |
| 17 | Dependency and destination diagnostics | WVC-M1-06 |
| 18 | Unit, integration and manual regression coverage | WVC-M0-02, WVC-M0-03, WVC-M4-03, WVC-M4-04, WVC-M4-05, WVC-M5-05 |
| 19 | Minimal testability refactor and Windows CI | WVC-M0-02, WVC-M0-03, WVC-M2-03, WVC-M4-04, WVC-M4-05 |
| 20 | New-user documentation and accurate capability claims | WVC-M5-01 |
| 21 | Versioned, reproducible release packaging | WVC-M5-02, WVC-M5-05 |
| 22 | Preserve licensing; review dependency/security notices | WVC-M5-03 |
| 23 | Website-ready product information for local distribution | WVC-M5-04, WVC-M5-05 |

## Optional and approval-gated details

Included as opt-in implementation: preserve-subfolders layout, stronger source hashing, batch retry/resume and read-only CLI planning. Included as review/candidate preparation only: benchmark alternatives, code-signing assessment, dependency-distribution review and website download metadata.

Automatic updates, GPU codecs, tone mapping, bundled FFmpeg and deployment are not silently added. A declined optional change must have an owner-recorded decision; do not claim an unimplemented feature completed. All core reliability items remain required.
