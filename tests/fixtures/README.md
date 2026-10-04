# Synthetic fixture inventory

`inventory.json` is the authoritative recipe/expected-stream map. `New-WvcFixtures` copies eight hand-authored probe responses and generates four one-second media files only when installed FFmpeg and FFprobe are available. Runtime `fixtures/inventory.json` records every logical fixture's actual Passed/Failed/Skipped state, provenance, argv, required capabilities, expected streams and cleanup owner. A skipped media recipe never means a video was generated or tested.

| File | Generation/input | Expected streams | Main capability |
|---|---|---|---|
| sdr-av.mp4 | testsrc2 320x240/24 + 440Hz sine, one second | H264 yuv420p video; mono AAC48k | Small video/audio; height below cap |
| silent.mp4 | testsrc2 160x120/24, one second | H264 yuv420p video only | Silent input |
| multi-stream.mkv | two video and two sine sources, one second | Two H264 videos; two mono AAC48k tracks, second audio default | Mapping/default/language selection |
| audio-only.m4a | 440Hz sine, one second | Mono AAC48k only | No video stream |
| attached-picture.json | Copy hand-authored normalized JSON | Cover-art index0, real video index3, audio index7 | Attached picture/noncontiguous indexes |
| display-geometry.json | Copy normalized JSON | Odd 641x479 video, SAR16:15, rotation90 | Display geometry |
| hdr-pq.json | Copy normalized JSON | 4K 10-bit HEVC with PQ/BT2020 fields | HDR classification |
| hdr-hlg.json | Copy normalized JSON | Portrait 10-bit HEVC with HLG/BT2020 fields | HDR/portrait classification |
| ten-bit-sdr.json | Copy normalized JSON | Ultrawide 10-bit H264 with BT709 fields | SDR differs from HDR |
| unknown-duration.json | Copy normalized JSON | Video duration N/A; no format duration | Unknown duration |
| wrong-shape.json | Copy raw valid JSON | Invalid stream shape intentionally | Probe-schema failure |
| malformed.json | Copy raw malformed JSON | Not parseable intentionally | Probe-JSON failure |

All paths/arguments are synthetic. No real footage, filenames, absolute archives, interview tags or probe logs are used. These JSON records are parser/metadata fixtures, not observations from actual media and not playback/colour evidence. Untagged synthetic yuv420p video is not labelled calibrated BT709.

Media recipes store complete argument arrays ending in `{output}`, use `-nostdin -n`, select streams explicitly, and require lavfi/filter/codec/muxer capabilities. Installed-but-failing generators/probes are failures, never dependency skips; no fallback codec is chosen. Probe expectations use native FFprobe key/value types, explicit stream order, default dispositions/languages and a finite 0.8-1.5 second duration tolerance for AAC/muxer rounding. No lossy byte-hash expectations across builds.

Each fixture belongs to its `New-WvcTestRoot` token, and `Remove-WvcTestRoot` owns cleanup. Marker/inventory/stderr/error files are local supporting artifacts with the same cleanup owner; they contain no media streams and are not committed fixtures. Failures retain owned local diagnostics; successful/omitted runs remove only their contained root. Each source JSON is copied without rewriting its raw malformed/valid contents.

Recipes were checked against official [FFmpeg options](https://ffmpeg.org/ffmpeg.html), [synthetic source filters](https://ffmpeg.org/ffmpeg-filters.html) and [FFprobe JSON output](https://ffmpeg.org/ffprobe.html). Real generation/probing remains skipped on hosts without both native tools. Extend this bounded starter matrix in the relevant later media tasks; it does not cover the entire release matrix.
