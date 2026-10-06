# Output, ownership, validation and crash safety

## Invariants

Original source files and existing final outputs are never overwritten, removed, renamed or edited. A successful job requires successful native encode, validation and no-clobber promotion. A failed or cancelled job must not acquire a finished-looking final name. Only job-owned temporary artifacts may be cleaned. No wildcard deletion of `.partial`, `(compressed)` or arbitrary directories.

## Transaction outline

Plan source identity and final-name policy. Allocate a high-entropy job ID and an owned temp MP4 on the destination volume, with a collision-resistant provenance record. Keep the filename/muxer compatible (for example `name.<job-id>.partial.mp4`, not an unexplained `.tmp` extension). Validate destination containment and source/output nonidentity.

Avoid a common reservation mistake: pre-creating the exact temp file and then running FFmpeg `-n` against it guarantees refusal. Either use an independently reserved job/lock path while FFmpeg creates a previously nonexistent unique media path with `-n`, or justify/test a different tightly scoped ownership protocol. Do not solve it by globally allowing overwrite. No blanket `-y` on user-controlled final paths.

Encode, capture native exit, validate the temp, then use a tested same-volume no-clobber move/rename. Existence checking before a force-capable move is not sufficient. Handle final-name races by safe retry of the rename naming policy or explicit skip/failure. `Move-Item -Force` is not a substitute for no-clobber promotion. Source-path equality checks are defence-in-depth, not the only overwrite protection.

If anything fails, report exact stage and outcome. Cleanup may remove only the artifact whose job ownership and containment are proven. On crash/power loss, surviving owned partials are reported on a later run; do not assume a finally block always ran. Network/filesystem atomicity limits belong in the support matrix.

## Implemented publication boundary (WVC-M2-04)

Each encode now reserves `<OutputDir>/.wvc-job-<32-hex-GUID>/active.owner` with CreateNew, exclusive sharing and DeleteOnClose. That separate held handle contains job/source/nominal-output provenance. FFmpeg receives the initially nonexistent `encode.partial.mp4` in that directory with `-n`; the media file is never pre-created and no overwrite switch is added. The private directory keeps temporary paths short and on the destination volume; successful final outputs remain flat.

Before encoding and publication, guards check the open reservation, canonical job paths, final-directory containment, source/output distinction and absence of reparse points. Destination spellings with trailing separators or dot segments normalize consistently. Output paths crossing a reparse point are refused. Unexpected job artifacts or a substituted non-regular temporary path refuse publication. A held reservation is not proof against another process with the same user's filesystem access replacing a regular media file; this is an accidental-collision/cleanup protocol, not a hostile-user security boundary.

After native success, the two-argument `System.IO.File.Move` publishes without replacing any existing destination on PS5.1 and PS7. Only an actual destination-exists error triggers the rename retry, always from the original nominal basename, with a 64-attempt bound. The configured skip policy records a skip if a final appears during encoding. Permission, sharing, missing-source and other move failures retain/report the job. Done increments after publication; a console display failure cannot reverse a recorded Done/Skipped outcome.

Media is never deleted by path during cleanup. Failed, ambiguous, locked or unused partials remain in their job directory with a CreateNew `retained.json` containing stage/reason and unverified state. A foreign record is not overwritten. Cleanup releases only the owned reservation handle and removes only an empty directory with non-recursive Delete. If owned encoder termination fails, even an empty job directory is retained with provenance because that encoder may still create its file. Interrupted/fatal exceptions survive retention-reporting failures. Full cancellation and detached-process handling remain M3-06.

Exact `.wvc-job-<32-hex-GUID>` directories are reserved: input discovery excludes them and explicit paths inside them. A read-only immediate-child check of OutputDir warns about active/unverified jobs before subsequent batches, including when sources are elsewhere. Ordinary compressed/partial filenames and nonmatching directories remain eligible inputs. A hard crash may remove `active.owner` without creating `retained.json`; surviving directories are reported as unverified, never adopted or automatically deleted. Durable manifests/recovery remain future work.

M2-04 checks native success, a regular temporary file and no-clobber publication. It does **not** yet check nonempty/readable MP4, streams, codecs, geometry or duration; those requirements below belong to M2-05. Native-success publication does not establish structural or visual/audio integrity. Local Windows collision, lock, junction and hash-sentinel fixtures cover this boundary. UNC/network storage, power-loss durability and every filesystem's atomicity remain unaccepted support boundaries.

## Planned structural validation (WVC-M2-05)

Require nonempty readable expected container, real encoded video, expected selected-audio presence/absence, plausible geometry and expected codecs. For known source duration, compare output with a documented tolerance grounded in fixtures and timestamp behaviour. Unknown duration should cause a disclosed limitation, not an invented match. Native exit zero alone is insufficient.

Structural validation is not full decode validation, proof of every frame, perceptual quality measurement, or lossless archival certification. A deeper decode check can run in full/release testing or as an explicit optional mode. Job Done increments only after final promotion, never at the final progress timestamp.

## Manifest and resume

A versioned manifest records job/source identity, size/mtime and optional hash, settings fingerprint, output identity, state and observed tool versions. Save atomically. Resume is explicitly batch-level: keep verified completed outputs and rerun unfinished jobs from their original source. Never append to a partial MP4.

Before a completed skip, validate source identity, settings and current output validity. Default size/mtime identity cannot detect every content change; expose optional stronger hashing and document the distinction. Validate manifest types/paths/ownership: a corrupted or edited manifest must not drive arbitrary deletion, traversal or shell commands. Moving a source, changing settings or replacing an output invalidates a blind completion assumption.

## Fault injection gate

Test failures at source open, destination create, FFmpeg start/nonzero/zero-with-bad-output, output probe, promotion, manifest save and cancellation. Also test two simultaneous instances targeting the same basename/config. Hash pre-existing sentinels before/after each scenario. Terminate only the child belonging to the active job; never all processes named ffmpeg.
