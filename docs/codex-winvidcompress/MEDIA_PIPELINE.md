# Media inspection, selection and encoding contract

These are proposed implementation requirements derived from the agreed review. Consult the current FFmpeg/FFprobe documentation and verify behaviour with pinned tool builds. Do not treat a suggested filter expression as already tested.

## Normalized probe result

Use a bounded native probe with captured stderr/exit code and JSON parsing. Return an object with input identity, all stream indices/types/dispositions, selected real video/audio indices, coded and display geometry, rotation/display matrix, SAR/DAR, pixel format, colour primaries/transfer/matrix, frame-rate information, audio channels/sample rate and source duration where known. Store unknown values explicitly. Reject malformed responses, probe failures and no-real-video inputs before encoding.

Do not infer duration from filename or file size. Duration can be absent/uncertain; progress becomes indeterminate and duration-validation limitations must be reported. Bounded retries, when justified, must not mask corrupt media. Inputs are user-selected files, not URLs or scripts; reject playlists/unsupported protocol-style inputs and review FFmpeg protocol/demuxer restrictions against actual supported containers. Never promise an absolute offline guarantee without verifying all process paths.

M2-01 implements `Get-MediaInspection` and the pure `ConvertFrom-ProbeJson` normalizer. Each input gets one UTF-8 JSON `-show_streams -show_format` call with a 10-second process/pipe deadline, retained native status/stdout/stderr and structured source/probe/JSON/validation failure. Source selection requires an existing literal filesystem file with a supported video extension. The probe allows only the `file` protocol and rejects hls/dash/concat format responses. These checks do not establish an absolute offline guarantee: UNC file access and the existing encoder path retain their separate boundaries.

The normalized schema preserves all stream indices/types/dispositions, coded width/height, display matrix or rotation tag, SAR/DAR, nullable pixel/colour/frame-rate/time-base values and audio channels/sample rate/layout/language. Streams are ordered by absolute index; attached pictures are excluded from real-video candidates. A real video requires a codec and positive integer coded dimensions. Optional absent/unusable values remain null. Duration prefers a positive finite format value, then the first real video's duration; missing/invalid values carry explicit Unknown/Invalid state, indeterminate progress and the unavailable-duration-comparison warning/limitation. Parsing uses invariant culture and tolerates extra fields.

Compression refuses inspection failures. M2-02 carries the first real video's coded height and absolute index into the stream plan and explicit mapping. Display geometry remains null with `GeometryState=MetadataOnly`; rotation/SAR-aware transforms belong to M3-01. M2-04 supplies owned temporary publication, and M2-05 validates that temporary MP4 before promotion. Optional normalized frame count, codec tag and stream/global timecode support output checks without changing input selection. See [output validation and duration policy](OUTPUT_SAFETY.md). Unknown source duration discloses unavailable comparisons; structural checks still run. Structured progress remains later work.

## Stream contract

Select the first real video stream by index for the documented first-video behaviour, excluding attached pictures. Probe this same selected stream's fields and explicitly map its absolute index in the encode. Select uniquely default-disposition audio when available, otherwise the first audio; log the selection and warn about alternatives omitted. No audio is a valid input case.

Do not silently add audio, downmix channels, force FPS, or preserve arbitrary subtitle/data/attachment streams. Subtitles remain out of scope and omitted streams are disclosed. Language/disposition metadata should be retained deliberately where relevant. Any owner preference for another audio policy belongs in DECISIONS.md before changing the default again.

M2-02 implements the pure `Get-StreamPlan` and `Write-StreamPlan` console report. The plan carries the inspection's existing PrimaryVideo object/index, selects exactly one unique-default audio stream or otherwise the lowest audio index (including ambiguous multiple defaults), and records every omitted index/type/reason. No audio yields a null audio selection. Selected channels/layout/sample rate/language/disposition flags remain the normalized values; absent values are reported as unknown. Explicit unknown stream types remain identifiable and are omitted rather than rejected as missing metadata.

The same plan supplies `-map 0:<absolute-video-index>` and, when present, `-map 0:<absolute-audio-index>`; height-cap decisions read its Video.Height. There are no optional maps, channel/sample-rate/FPS overrides, synthetic audio or complex filters. AAC 160k options are emitted only with selected audio; libx264/veryfast/CRF22/faststart remain. Selected stream metadata/dispositions use FFmpeg's default mapped-stream copying, with no clearing/forced-default override. Actual muxer read-back remains unverified without installed FFmpeg/FFprobe; recorder argv alone does not establish output identity or playback integrity.

## Geometry

Keep no crop/no upscaling and the existing height-cap product policy, not a new width-bounded preset. Compute based on display geometry and selected stream. Account for FFmpeg autorotation exactly once; test rotation metadata handling and output orientation. Preserve display aspect ratio, handling non-square pixels intentionally. Ensure encoder-compatible even dimensions with bounded rounding; do not add a generic crop or upscale a small clip to make dimensions convenient.

Required cases: small/SD source, 1080p, 4K, portrait, 90/180/270 rotation, ultrawide, anamorphic SAR and odd width/height. Confirm output geometry by probe and visual test patterns, not only command string inspection. VFR and high-frame-rate input must not receive a hidden frame-rate conversion policy.

## Colour

Establish tested SDR yuv420p output compatibility. Use transfer/colour evidence to recognize PQ/HLG HDR; bit depth alone is insufficient. For a known HDR path not deliberately supported, return an actionable unsupported result without silent washed-out conversion. Do not merely change colour tags to claim SDR. Ambiguous colour metadata warrants explicit warning/limitations rather than fabricated certainty.

Tone mapping is outside the initial implementation. Any later path needs separate colour transforms, tests and owner review. Keep accepted quality settings unless the owner authorizes a measured change.

## Filename metadata

Retain the three existing date formats and title fallback. Use culture-independent real-date parsing; test leap years, impossible dates, extra/multiple date tokens, missing artist and the eight-digit fallback. Never fabricate a date when parsing is ambiguous. Compression continues if tags cannot be parsed. Unicode text and shell-looking punctuation remain data, never executable syntax.

Define tag precedence: generated filename title and valid interview artist/date/comment intentionally override those fields; preserve other compatible source tags only by documented policy. Document privacy implications and prove selected tag read-back with FFprobe on the packaged dependency baseline. Do not copy unrelated private tags blindly while claiming the output contains only four fields.
