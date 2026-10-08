# Changelog

## 1.0.0 - local release candidate

Prepared on 2026-10-08 using the owner's selected completed-project version. This is a local candidate pending concrete owner acceptance; no tag or public release is implied.

- Keeps the established local Windows PowerShell/FFmpeg workflow and compression defaults: libx264 veryfast CRF22, AAC160k, MP4 faststart, no crop/upscale and the oriented-height cap.
- Includes the implemented path/config/queue, stream/geometry/SDR policy, filename metadata, output-safety, progress/logging, cancellation, opt-in resume, preview and relative-layout improvements.
- Ships the entry points, offline user guides, original Unlicense and distribution/security notices in a tool-only ZIP. FFmpeg and FFprobe remain separately supplied dependencies.
- Final candidate preparation reconstructs from the pushed GitHub feature branch and records package hashes, Windows tests, extraction smoke and all 23 improvement mappings in the repository's release evidence.

Earlier owner Explorer, physical Ctrl+C and bounded playback passes retain their recorded scopes. HDR is refused; broader SMB/disconnection, arbitrary long paths/filesystems, power-loss/console-close/detached descendants, whole-original/other-player playback, browser/MOTW and fresh-profile/default-Videos checks remain explicit limits. Structural/decode checks and checksums do not establish perceptual integrity, publisher authentication, signing or certification. See [verification limits](docs/user/VERIFICATION.md).

## 0.1.0-rc.1 - local candidate

Initial candidate version chosen after the 2026-10-07 live GitHub inventory returned no tags or releases. No tag or public release has been created.

- Local Windows PowerShell/FFmpeg compression keeps libx264 veryfast CRF22, AAC160k, MP4 faststart, no crop/upscale and the oriented-height cap.
- Existing hardening covers literal paths, config recovery, deterministic sequential queues, explicit streams, SDR/HDR limits, owned temporary outputs, no-clobber publication, structural validation, cancellation and opt-in resume.
- Onboarding/help document the implemented behavior and bounded acceptance evidence.
- Developer packaging builds a tool-only candidate from clean Git HEAD, records exact provenance/file hashes and verifies final ZIP SHA256. Dependency binaries and private files are excluded.

This is a lossy viewing-copy tool. Prior owner Explorer/Ctrl+C and short representative playback observations remain scoped; broader media/filesystem/durability/profile and publication gates remain explicit. See [verification limits](docs/user/VERIFICATION.md). Package checksums detect byte changes and do not authenticate a publisher or certify a signed release.
