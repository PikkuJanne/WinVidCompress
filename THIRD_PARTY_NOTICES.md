# Third-party dependencies and distribution boundary

Project code retains the original [Unlicense](LICENSE). It does not relicense external tools, platform components or their dependencies.

The local candidate distributes WinVidCompress scripts, documentation/license/notices and generated version/hash records. It **does not distribute FFmpeg, FFprobe, codec libraries, dependency archives, an installer or a bundled runtime**. Windows PowerShell/.NET are platform prerequisites; supported PowerShell 7 is an optional separately installed host. Git/Python/Pester/PSScriptAnalyzer and CI dependency setup are development tools and are excluded from the candidate.

## Separately installed FFmpeg and FFprobe

Use a Windows provider linked by the [official FFmpeg download page](https://ffmpeg.org/download.html). Retain that provider's license notices and build/source information. Both executables must support the documented profile; the application neither installs nor updates them.

FFmpeg's terms depend on its build options and included components. [FFmpeg's official legal guidance](https://ffmpeg.org/legal.html) describes LGPL/GPL variants and identifies libx264 as a GPL component. The required libx264 profile is not a basis for labelling an arbitrary build LGPL-only or Unlicense. Check the actual provider's terms, `ffmpeg -L`, `ffprobe -L` and build configuration; those reports are evidence about that build, not universal legal clearance.

The externally installed Gyan essentials build used in recorded tests, `2026-10-04-git-a35c879992`, reports GPL version 3 or later with `--enable-gpl`, `--enable-version3` and `--enable-libx264`. It is not in this candidate. A different dependency build needs its own review. No codec-patent, jurisdiction-wide or commercial-distribution clearance is claimed.

## Future redistribution

Bundling any dependency requires explicit owner approval before distribution. Review the exact binaries/components, source and build provenance, redistribution terms, applicable license texts/notices and corresponding-source obligations. Update the actual payload and notices together. Signing also requires a separate approved publisher/certificate plan; current checksums are not signatures. See the [security policy](SECURITY.md) for reporting and trust boundaries.
