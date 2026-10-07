# Changelog

## 0.1.0-rc.1 - local candidate

Initial candidate version chosen after the 2026-10-07 live GitHub inventory returned no tags or releases. No tag or public release has been created.

- Local Windows PowerShell/FFmpeg compression keeps libx264 veryfast CRF22, AAC160k, MP4 faststart, no crop/upscale and the oriented-height cap.
- Existing hardening covers literal paths, config recovery, deterministic sequential queues, explicit streams, SDR/HDR limits, owned temporary outputs, no-clobber publication, structural validation, cancellation and opt-in resume.
- Onboarding/help document the implemented behavior and bounded acceptance evidence.
- Developer packaging builds a tool-only candidate from clean Git HEAD, records exact provenance/file hashes and verifies final ZIP SHA256. Dependency binaries and private files are excluded.

This is a lossy viewing-copy tool. Prior owner Explorer/Ctrl+C and short representative playback observations remain scoped; broader media/filesystem/durability/profile and publication gates remain explicit. See [verification limits](docs/user/VERIFICATION.md). Package checksums detect byte changes and do not authenticate a publisher or certify a signed release.
