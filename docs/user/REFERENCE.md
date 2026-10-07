# Options and media reference

Start with the [README](../../README.md). Commands below run in the extracted script folder; replace example paths with existing folders and chosen sources. The fixed quality settings have no public CRF/codec/preset switch.

## Options

`Get-Help .\WinVidCompress.ps1 -Full` describes the same public parameters. Common PowerShell parameters are also available through `CmdletBinding`; this tool's `-WhatIf` is its explicit filesystem preview.

| Parameter | Behavior |
| --- | --- |
| `-Path` (also positional, multiple values) | Literal file/folder selections; no wildcard expansion. A relative filename starting with a dash needs `.\` or an absolute path. |
| `-OutputDir` | Existing absolute drive/UNC output folder for this run; does not save preferences. |
| `-CollisionMode rename\|skip` | `rename` by default, or optional saved value. `skip` preserves an occupied nominal name without validating/adopting that file. |
| `-WhatIf` | No-write estimated filesystem plan; requires inputs. No native tools, write test, config recovery, logs or manifests. |
| `-PreserveSubfolders` | Opt-in relative output layout for this run; requires inputs and disjoint input/output roots. |
| `-CheckEnvironment` | Doctor, with a temporary create/write/remove check. Allows `-OutputDir`; ignores input selections without converting them. |
| `-Unattended` | Never opens the menu. Put first in BAT calls; requires inputs except with doctor. |
| `-KeepOpen` | Interactive BAT's retained prompt. Cannot combine with `-Unattended`. |
| `-ManifestPath` | Opt-in absolute canonical local `.json` path in an existing parent. Must be absent for a new batch; requires inputs. |
| `-Resume` | Validate and retry the original queue using the same manifest. Requires `-ManifestPath`. |
| `-StrongSourceHash` | Use source SHA-256 instead of size/mtime identity with a manifest. Requires `-ManifestPath`; keep the same mode on resume. |

Defaults apply first, then saved config, then explicit options. Saved config needs `OutputDir`; optional `CollisionMode` is `rename` or `skip`. Unknown fields are retained when saving. Explicit output/collision/layout controls do not save preferences, and a missing config stays absent. They refuse invalid config instead of repairing it. An unavailable but otherwise valid saved destination can be overridden by a valid per-run `-OutputDir`.

For multiple inputs with `-File` or BAT, use separate positional paths as in the examples. In a direct PowerShell script call, named `-Path` can take an array: `& .\WinVidCompress.ps1 -Path @('D:\Sources\one.mov','D:\Sources\two.mov')`. Do not put several space-separated values after named `-Path`.

`-WhatIf` cannot combine with doctor or any manifest control. `-PreserveSubfolders` cannot combine with doctor or manifest controls. Doctor cannot combine with `-CollisionMode` or manifest controls. Output/collision/layout controls need explicit inputs except doctor's output override. Use separate preview, doctor and conversion commands.

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -CollisionMode skip -OutputDir 'D:\Output' 'D:\Sources'
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -WhatIf -PreserveSubfolders -OutputDir 'D:\Output' 'D:\Shoot\camera-a' 'D:\Shoot\camera-b'
```

One selected folder in preserve mode keeps paths below it. Multiple roots get stable folder labels, with ` (root 2)` suffixes for duplicate labels. Explicit files use their parent folders as roots; overlapping selections use the shallowest root. Conversion creates needed descendants beneath an existing output root. Input/output overlap in either direction is refused. Rename/skip applies within each mapped output folder; manifests remain flat-only. Preview names can change if another process creates a file before conversion.

## Output safety and retry

The nominal output is the source basename plus `.mp4`. Default rename tries the nominal name, then ` (compressed)`, ` (compressed 2)`, etc., including when the nominal output equals the source. The final move refuses to overwrite a file that appeared during encoding. Collision skip counts as `Skipped`, not `Done`.

Each encode uses an owned `.wvc-job-<GUID>` directory in its destination, with `encode.partial.mp4`. Native exit success is followed by MP4/stream/codec/geometry/colour/duration structural checks before no-clobber publication. Ordinary failed jobs continue the batch; cancellation or a fatal process/dispatch safety failure stops remaining work. Failed/cancelled/ambiguous artifacts are retained with `retained.json` where possible. Later runs warn about reserved job directories and exclude them from scanning. They never adopt, append or automatically delete retained partials. Production structural checks are not a full decode or playback test.

A normal rerun is a fresh encode. For explicit resume, start with a new manifest and later repeat the original input selection, output, settings and hash mode:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -OutputDir 'D:\Output' -ManifestPath 'D:\BatchState\interviews.json' -StrongSourceHash 'D:\Sources'
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -OutputDir 'D:\Output' -ManifestPath 'D:\BatchState\interviews.json' -Resume -StrongSourceHash 'D:\Sources'
```

Create `D:\BatchState` first. UNC manifests are unsupported. Completed skips require current source/settings/output structural checks. Fast identity uses size/mtime and can miss same-size/restored-time edits; strong hashing reads whole sources and costs time. Queue/root/schema/path mismatches or strong-to-fast downgrade refuse resume. Fast-to-strong upgrade is allowed and retries all jobs. Changed readable sources, settings or invalid completed outputs lose skip eligibility and are re-encoded safely. The fingerprint includes exact PS1 bytes: updating even its help comments can cause completed entries to retry. Retries create fresh jobs and always rename safely around old finals, even if collision mode is `skip`. Do not edit manifests to force acceptance.

## Exact media policy

| Concern | Implemented behavior and limit |
| --- | --- |
| Profile | `-c:v libx264 -preset veryfast -crf 22`, `-c:a aac -b:a 160k`, MP4 `-movflags +faststart`; no fixed size/reduction guarantee. |
| Discovery | `.mp4 .mov .mkv .m4v .avi .mpg .mpeg .mts .m2ts .wmv`, case-insensitive. Folder scans omit other extensions; explicit unsupported files fail. Reparse points/linked ancestors are not followed and produce scan errors. Hard links at different paths remain different inputs. |
| Streams | First non-cover-art video by index; unique default audio, otherwise first audio by index. Silent remains silent. Extra video/audio, subtitles, source data and attachments omitted. Compatible retained timecode tags may generate a matching MP4 `tmcd` data track. Selected indices/channels and omissions are printed. |
| Geometry | Supported quarter-turn/reflection autorotation precedes a 1080 **oriented-height** cap. Both dimensions are even and never enlarged; odd small sources may shrink by one pixel. Width may exceed 1920. Known sample/display aspect is preserved within validation tolerance. Unknown aspect warns; contradictory/arbitrary rotation or ambiguous display matrices fail. No crop or forced frame rate. |
| Audio | AAC 160k for selected audio, with no explicit channel-count/downmix override. Encoder support can still fail for unusual layouts. |
| SDR | 8-bit 4:2:0 `yuv420p`; supported 8/10-bit and 4:2:2/4:4:4 YUV SDR become this compatibility format. Known compatible colour tags are carried; full-range samples are rescaled to limited range. This loses bit depth/chroma detail. |
| HDR/other colour | PQ/HLG, mastering/content-light, Dolby Vision or dynamic HDR evidence is refused before encoding. No HDR preservation/tone mapping. RGB, log/linear and specialized matrix transforms are untested and refused. Missing/ambiguous colour metadata warns and uses the SDR path without inventing missing Rec709 tags; fidelity and HDR absence remain unverified. |
| Validation | MP4 structure, intended streams/codecs, oriented geometry/aspect, supported colour and bounded duration. Unknown source duration stays unknown; progress may be indeterminate. Output still needs measurable positive selected-stream durations. Success does not certify every frame/sample or player. |

## Filename metadata

Examples: `Band Name 29092025 - CamA.mov`, `Band Name 29.09.2025.mov`, `Band Name 29-09-2025.mkv`. Real Gregorian dates are required, independent of Windows language settings.

| Field | Value |
| --- | --- |
| `title` | Base filename without extension, overriding source title |
| `artist` | Parsed band name, when a unique valid band/date pair exists |
| `date` | `YYYY-MM-DD`, when valid |
| `comment` | `Interview date dd.mm.yyyy; Band: <name>`, when valid |

Invalid dates, blank bands or multiple date tokens warn and omit generated artist/date/comment; conversion continues and compatible source fields may remain. A legacy fallback such as `Band Name 29092025 CamA` accepts one whitespace-delimited valid compact date with an ambiguity warning. Longer numbers or dates embedded in letters are ignored. Other compatible global/selected-stream source tags follow FFmpeg/MP4 copying, including copyright and audio language where supported; arbitrary tags are not guaranteed. Review metadata before sharing outputs.

## Local diagnostics

Conversion/menu sessions write best-effort `session.txt` and `results.jsonl` under `%APPDATA%\WinVidCompress\logs\<GUID>`. Each file is capped at 1 MiB; admission stops at 128 session directories. No automatic pruning. A log/quota warning does not change compression outcomes. Paths, filenames, generated tags, arguments and native diagnostic tails can be private. Manifests and retained-job records also contain paths and source/output identities.

An optional developer helper, `Export-WvcDiagnostic`, can be loaded by dot-sourcing the PS1 and exporting to a **new** destination. It is not a CLI switch. Its default export removes path/name/metadata fields and free-form diagnostic text; review any export yourself before sharing. See [troubleshooting](TROUBLESHOOTING.md#logs-and-bug-reports) and [verification limits](VERIFICATION.md).
