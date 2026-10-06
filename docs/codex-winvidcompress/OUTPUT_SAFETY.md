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

M2-05 adds structural validation between native success and the existing no-clobber publication. Local Windows collision, lock, junction and hash-sentinel fixtures cover this boundary. UNC/network storage, power-loss durability and every filesystem's atomicity remain unaccepted support boundaries.

## Implemented structural validation (WVC-M2-05)

`Get-OutputValidation` holds the owned temporary file open with read-only sharing during inspection, refusing concurrent write/delete access. Require at least 16 readable bytes, a bounded initial FTYP box and a supported MP4 major brand (isom, iso1-iso9, mp41/mp42 or avc1). FFprobe's MOV/MP4 family name alone cannot distinguish QuickTime/3GP; the header and successful probe are both required. The existing bounded UTF-8 `-show_streams -show_format` probe preserves native exit/stderr. Read sharing ends before publication; this remains an accidental-collision protocol, not protection from hostile same-user file substitution.

Require exactly one real H.264 video, no attached artwork and exactly the selected AAC audio count (zero for silent input, otherwise one). AAC needs positive channel/sample-rate metadata and preserves known source channel count. Explicit zero video frame count fails; unavailable frame count is disclosed. Extra streams fail except one generated tmcd data track whose timecode and output-video tag match retained source timecode. Global source timecode takes priority over selected-video timecode. This narrowly accommodates the muxer's automatic track generation without changing encoder flags. [FFmpeg muxer documentation](https://ffmpeg.org/ffmpeg-formats.html#Options-9), [current muxer source](https://ffmpeg.org/doxygen/trunk/movenc_8c_source.html).

Unscaled, unrotated coded dimensions must match. The existing height cap requires 1080 output height and width within two pixels of the current aspect-ratio calculation, accommodating `scale=-2:1080` integer rounding. Quarter turns accept unchanged/swapped unscaled dimensions or the two scaled width candidates; arbitrary-angle geometry is disclosed as deferred. These are plausibility checks, not a new rotation/SAR/colour policy or proof of orientation; M3-01 remains open. [FFmpeg scale documentation](https://ffmpeg.org/ffmpeg-filters.html#scale).

### Duration policy

Compare each selected video/audio duration independently. Output durations must be positive finite metadata; audio/container duration cannot hide truncated video. Only a sole-video file with absent or explicitly unavailable (N/A/unknown/unspecified) video duration may use container duration as its video fallback, with a warning. Supplied zero/negative/nonfinite/malformed video duration fails rather than being hidden by a positive container duration. Unknown source references proceed with an explicit unavailable-comparison warning; output still needs measurable duration. Source video may use its container fallback only if there is one source stream; omitted streams never supply retained-stream references.

The base allowance in seconds is `min(2, max(0.25, 2/fps + 2048/sampleRate))`, omitting unavailable FPS and unselected/unknown audio sample rate. Each reference further caps shortening at 10% of reference duration. Lengthening uses `max(0.05, 10% of duration)` as that cap, allowing small positive timestamp padding; neither cap grows the base allowance. A one-microsecond comparison epsilon handles floating-point boundaries. Short references below 0.5 seconds disclose the positive 50ms padding allowance. For example 10s/24fps allows 9.75-10.25s; 0.1s rejects 0.051s and 0.01s, while 0.04s allows 0.06s positive padding. Fractional/unknown FPS gives a 0.25s base; very low FPS never exceeds 2s.

An aggregate comparison additionally uses genuine container durations only when all source streams are retained and selected references are known. A source aggregate that differs from the longest selected reference by more than the base allowance is disclosed as ambiguous (timestamp/edit offsets may be rebased). Missing output container duration is disclosed; normalized video fallback never substitutes for it. Selected-stream checks still run. These deterministic normalized fixtures establish policy boundaries, not measured compatibility with every FFmpeg build. Real short SDR A/V and silent encode/probe/decode fixtures require already-installed tools; absent tools stay skipped. Timing, packet loss, frame content and playback require further testing. [FFmpeg timestamp options](https://ffmpeg.org/ffmpeg.html#Advanced-options).

Validation failures retain source/job/temp identity and diagnostics in the existing unverified-job record; no final is published. Done increments only after successful native encode, structural validation and final no-clobber promotion. Structural validation is not full decoding or proof of perfect visual/audio integrity.

### Explicit developer decode check

For release investigation, dot-source the script with isolated APPDATA and use the owned-job workflow demonstrated in `tests/integration/OutputValidation.Tests.ps1`: encode to the initially absent temp, call `Get-OutputValidation`, then explicitly call `Invoke-OutputDecodeCheck $ffmpeg $job $validation`. Check both results before `Publish-OutputJob`; always close the owned job in finally. This internal helper requires matching successful structural-validation job/source/temp identity and never publishes by itself. Normal `Compress-One` does not call it, and there is no new menu/config switch.

The helper decodes only validated output A/V indexes to `-f null NUL`, using `-xerror`, `-err_detect explode` and `-abort_on empty_output_stream`; it preserves native diagnostics and uses the existing owned-process runner. This performs a full decode pass, not a second saved conversion. It has the encoder runner's cleanup/tail behavior and no total runtime deadline. Unsupported flags or decoder errors fail the optional check. Successful decoding still does not establish perceptual quality or intended content. [FFmpeg error/abort options](https://ffmpeg.org/ffmpeg.html#Main-options), [decoder error detection](https://ffmpeg.org/ffmpeg-all.html).

## Manifest and resume

A versioned manifest records job/source identity, size/mtime and optional hash, settings fingerprint, output identity, state and observed tool versions. Save atomically. Resume is explicitly batch-level: keep verified completed outputs and rerun unfinished jobs from their original source. Never append to a partial MP4.

Before a completed skip, validate source identity, settings and current output validity. Default size/mtime identity cannot detect every content change; expose optional stronger hashing and document the distinction. Validate manifest types/paths/ownership: a corrupted or edited manifest must not drive arbitrary deletion, traversal or shell commands. Moving a source, changing settings or replacing an output invalidates a blind completion assumption.

## Fault injection gate

Test failures at source open, destination create, FFmpeg start/nonzero/zero-with-bad-output, output probe, promotion, manifest save and cancellation. Also test two simultaneous instances targeting the same basename/config. Hash pre-existing sentinels before/after each scenario. Terminate only the child belonging to the active job; never all processes named ffmpeg.
