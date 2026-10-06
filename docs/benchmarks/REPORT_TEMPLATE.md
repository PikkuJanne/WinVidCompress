# Benchmark report template (unmeasured)

Template only. Replace fields from an actual local report; leave unavailable observations unfilled. Results vary; valid output can be larger. No production change is approved by this template.

- Date/source implementation SHA and dirty state: NotRun
- Application/runner hashes, OS/build/architecture, PowerShell edition/version: NotRun
- CPU/logical processors/memory and FFmpeg/FFprobe build/hash: NotRun
- Opaque source ID and provenance (synthetic recipe or approved copy), source hash: NotRun
- Source codec/dimensions/rotation/SAR/FPS/duration/bytes; selected stream indices: NotRun
- Exact settings and actual command tokens with path placeholders: NotRun
- Profile (default or experimental), repeat count, run order/cache conditions: NotRun

| Source/profile/repeat | Input bytes | Output bytes | Reduction/growth/unknown | Source duration s | Encode + mux s | Validation s | Publication s | Total job s | Structural check |
|---|---|---|---|---|---|---|---|---|---|
| NotRun | | | | | | | | | NotRun |

Record min/median/max/range for each repeated timing and output size. Weighted savings = `(sum comparable input - sum comparable output) / sum comparable input * 100`; report which completed pairs were included. Unknown/zero inputs have no individual ratio. A negative savings value is growth. Faststart relocation is included in encode/mux time and is not separately measured.

| Observer/date | Profile | Facial detail | Text | Motion | Audio | Sync | Notes |
|---|---|---|---|---|---|---|---|
| NotRun | | NotRun | NotRun | NotRun | NotRun | NotRun | |

Use PASS/FAIL/UNSURE and preserve actual owner wording. Structural checks do not establish playback integrity. State representativeness/host/tool limitations and any default-change proposal separately; changing defaults requires explicit owner approval. Inspect report privacy before sharing; private clips, paths, tags, raw diagnostics and local logs stay outside Git.
