# Output, ownership, validation and crash safety

## Invariants

Original source files and existing final outputs are never overwritten, removed, renamed or edited. A successful job requires successful native encode, validation and no-clobber promotion. A failed or cancelled job must not acquire a finished-looking final name. Only job-owned temporary artifacts may be cleaned. No wildcard deletion of `.partial`, `(compressed)` or arbitrary directories.

## Transaction outline

Plan source identity and final-name policy. Allocate a high-entropy job ID and an owned temp MP4 on the destination volume, with a collision-resistant provenance record. Keep the filename/muxer compatible (for example `name.<job-id>.partial.mp4`, not an unexplained `.tmp` extension). Validate destination containment and source/output nonidentity.

Avoid a common reservation mistake: pre-creating the exact temp file and then running FFmpeg `-n` against it guarantees refusal. Either use an independently reserved job/lock path while FFmpeg creates a previously nonexistent unique media path with `-n`, or justify/test a different tightly scoped ownership protocol. Do not solve it by globally allowing overwrite. No blanket `-y` on user-controlled final paths.

Encode, capture native exit, validate the temp, then use a tested same-volume no-clobber move/rename. Existence checking before a force-capable move is not sufficient. Handle final-name races by safe retry of the rename naming policy or explicit skip/failure. `Move-Item -Force` is not a substitute for no-clobber promotion. Source-path equality checks are defence-in-depth, not the only overwrite protection.

If anything fails, report exact stage and outcome. Cleanup may remove only the artifact whose job ownership and containment are proven. On crash/power loss, surviving owned partials are reported on a later run; do not assume a finally block always ran. Network/filesystem atomicity limits belong in the support matrix.

## Structural validation

Require nonempty readable expected container, real encoded video, expected selected-audio presence/absence, plausible geometry and expected codecs. For known source duration, compare output with a documented tolerance grounded in fixtures and timestamp behaviour. Unknown duration should cause a disclosed limitation, not an invented match. Native exit zero alone is insufficient.

Structural validation is not full decode validation, proof of every frame, perceptual quality measurement, or lossless archival certification. A deeper decode check can run in full/release testing or as an explicit optional mode. Job Done increments only after final promotion, never at the final progress timestamp.

## Manifest and resume

A versioned manifest records job/source identity, size/mtime and optional hash, settings fingerprint, output identity, state and observed tool versions. Save atomically. Resume is explicitly batch-level: keep verified completed outputs and rerun unfinished jobs from their original source. Never append to a partial MP4.

Before a completed skip, validate source identity, settings and current output validity. Default size/mtime identity cannot detect every content change; expose optional stronger hashing and document the distinction. Validate manifest types/paths/ownership: a corrupted or edited manifest must not drive arbitrary deletion, traversal or shell commands. Moving a source, changing settings or replacing an output invalidates a blind completion assumption.

## Fault injection gate

Test failures at source open, destination create, FFmpeg start/nonzero/zero-with-bad-output, output probe, promotion, manifest save and cancellation. Also test two simultaneous instances targeting the same basename/config. Hash pre-existing sentinels before/after each scenario. Terminate only the child belonging to the active job; never all processes named ffmpeg.
