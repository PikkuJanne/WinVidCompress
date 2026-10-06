# Local benchmark protocol

Production defaults remain libx264, veryfast, CRF 22, yuv420p SDR, AAC 160k, MP4 +faststart and the existing no-crop/no-upscale height cap. Results vary; a valid output can grow. No fixed reduction or quality claim follows from CRF.

Use installed tools; the runner never downloads dependencies. From the repository root, run in a fresh shell:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/benchmark.ps1 -FFmpeg C:/ffmpeg/bin/ffmpeg.exe -FFprobe C:/ffmpeg/bin/ffprobe.exe -Repeats 3 -CandidatePresets medium
```

PowerShell 7 uses the same arguments. The default source is a two-second 320x240/24 fps testsrc2 pattern plus 440 Hz/48 kHz sine, encoded as FFV1/PCM. Its exact generation tokens, measured source properties, hashes and tool versions are in the report. Adjust `-SyntheticSeconds` (0.2-30) for longer synthetic runs. These patterns are repeatable structural fixtures, not representative interviews.

For owner-approved representative copies (talking heads, low light, movement, text), call from PowerShell with literal paths:

```powershell
& ./tools/benchmark.ps1 -FFmpeg C:/ffmpeg/bin/ffmpeg.exe -FFprobe C:/ffmpeg/bin/ffprobe.exe -ApprovedCopies @('D:/local-review/talking-head-copy.mov','D:/local-review/text-copy.mp4') -Repeats 3 -CandidatePresets medium -CandidateCRFs 20
```

Only pass copies you approve for this local experiment. The runner makes further disposable duplicates with opaque names, verifies supplied/disposable source hashes and leaves them intact. Each preset candidate keeps CRF 22; each CRF candidate keeps veryfast. Candidates are separate experiments, not a preset/CRF cross product, and never modify the application defaults. Approval is required before any production quality change.

All generated files stay under ignored `.test-results/benchmarks/<fresh RunId>/`. An existing RunId is refused. APPDATA/output roots are isolated; APPDATA/FFREPORT are restored. Production defaults use `Compress-One`; candidates use its planning/argument/owned-output/validation/publication helpers with only the preset or CRF token changed. Existing finals are never replaced; larger valid outputs are retained. No automatic upload or cleanup occurs. Local `job.local.json` files retain raw probe/encoder diagnostics, paths and source tags; never commit or share these or private media. Failures retain a local diagnostic and do not produce a success report.

`report.json` is a deliberately projected report: actual encoder tokens retain their order with source/temporary paths replaced by placeholders; input tags and raw diagnostic objects are excluded. It records source/runner/application provenance, exact settings, selected streams, OS/PowerShell/CPU/memory/tool builds and hashes, input/output bytes, size change, source duration, measured stage/total times and repeated-run min/median/max/range. EncodeAndMuxSeconds includes FFmpeg faststart relocation; separate relocation timing is unavailable. Total job times include application overhead/cleanup (candidate also includes size accounting), and exclude fixture creation, review, hashes and batch scanning. Profile order is interleaved within repeats; these are local warm-cache measurements, not controlled cold-start timings. Do not generalize a short single-host result into a performance promise.

Reports/media remain local even when projected. Before committing an example, restrict it to synthetic fixtures, inspect every field and use [the report template](REPORT_TEMPLATE.md). Private source IDs/hashes can still identify a clip; no private benchmark is committed by this task. Structural validation does not establish complete visual/audio integrity.

For manual review, compare each retained default/candidate output against its source. Record PASS, FAIL or UNSURE for facial detail, readable text, motion, audio and sync, with observer/date/notes. Leave unavailable judgments NotRun. Synthetic patterns alone cannot establish facial detail or talking-head sync. A04 remains incomplete until an actual owner observation is recorded. No default approval is implied by measurements or playback.
