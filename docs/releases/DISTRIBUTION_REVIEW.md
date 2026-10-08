# Tool-only distribution review

M5-03 keeps the existing LICENSE bytes and Git blob intact. PS1/BAT runtime bytes and the fixed profile are unchanged. The current 0.1.0-rc.1 is a local unsigned candidate, not a published or certified release. This checklist records the inspected scope; it does not certify safety or legal clearance.

| Item | Current boundary | Later decision |
|---|---|---|
| Project license | Original Unlicense, without warranty | Any license change requires owner approval |
| Payload | Positive allowlist of scripts/docs/LICENSE/SECURITY/notices/version/hash records | Review every added distributed component |
| FFmpeg/FFprobe | Separately supplied and executed; no executable/library archive in ZIP | Bundling requires approval plus actual build/license/source-obligation review |
| Signing | PS1/developer builder inspected as NotSigned; no publisher/certificate claim | Owner-approved identity, certificate custody and signing/verification plan |
| Privacy | No application uploads/telemetry; private config/log/media/developer output excluded | Inspect exact final payload and diagnostic examples before publication |
| Reporting | GitHub issues enabled, private vulnerability reporting disabled on 2026-10-07 | Minimal public contact request only; sensitive detail waits for confirmed private channel |

The [security policy](../../SECURITY.md) and [third-party notices](../../THIRD_PARTY_NOTICES.md) ship in the tool-only ZIP, with local README links. The developer builder and test harness are excluded. Verification proves hash/provenance consistency, not an authenticated publisher. The initial package still includes no dependency binary or installer. Normal compression performs no dependency download or system configuration change; explicit development CI setup is separate and uploads sanitized summaries only.

For a final candidate, build from a clean pushed source with [PACKAGING.md](PACKAGING.md), verify each artifact's checksum/provenance, inspect every entry for unexpected binaries/private values/telemetry and reconstruct/extract into fresh isolated roots. Review the current provider's integrity information and actual license/build output before using its native tools. Confirm README/policies agree with the selected source and payload. Keep only sanitized evidence in GitHub.

M5-03's bounded candidate inspection does not replace M5-05 final-candidate reconstruction/acceptance or approval to publish/tag/merge/deploy. Preserve M5-02's measured same-runtime ZIP repeatability and cross-runtime container difference; no universal byte-identical claim. Earlier owner Explorer/Ctrl+C/playback evidence stays scoped. Browser/MOTW/fresh-profile/default-Videos/other-player/HDR/remote filesystem/durability/hostile substitution limits remain.

Primary references checked 2026-10-07: [FFmpeg legal guidance](https://ffmpeg.org/legal.html), [FFmpeg downloads](https://ffmpeg.org/download.html), [GitHub private-reporting fallback](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately). No repository settings, external contact/account or signing/bundling setup was created.
