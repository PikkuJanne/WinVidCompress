# Local candidate packaging

`tools/package.ps1` is a developer tool requiring Git and Windows PowerShell5.1 or supported stable PowerShell7. It never installs dependencies, publishes, uploads, tags or merges. Run from a clean tracked repository root whose origin is PikkuJanne/WinVidCompress. VERSION currently selects **0.1.0-rc.1**, a local candidate; live tags/releases were empty when chosen. Commit the intended source before packaging. No own-commit SHA is embedded in tracked version/release files.

```powershell
New-Item -ItemType Directory -Path .test-results/packages -Force | Out-Null
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/package.ps1 -OutputDirectory "$PWD\.test-results\packages" -ExpectedCommit '<full-current-HEAD>'
```

Use `pwsh.exe` for PowerShell7. `ExpectedCommit` is an optional full-SHA guard, not a branch selector. The build always uses clean current HEAD. Output must be an existing absolute local directory outside the repository or under ignored `.test-results`; linked/reparse directories are refused. Existing candidate destinations are never overwritten. Use separate fresh output folders for repeated builds. Any failed owned `.wvc-package-<GUID>` staging directory is retained for inspection; no automated recursive cleanup.

The builder reads binary Git blobs, independent of checkout CRLF conversion. The positive source allowlist is PS1/BAT/README/LICENSE/VERSION/CHANGELOG and the three user guides. No FFmpeg/FFprobe, tests, developer tools, handoff/evidence bundle, .git, private config/logs/media or credentials are included. The application and launcher bytes are unchanged. Package copies of Markdown links to excluded development files become exact-source-commit GitHub URLs; included links remain local. Source docs are not edited.

The ZIP adds `PACKAGE.json` with version/source/candidate state and the tracked, hash-bound **prior application** tested environment. `MANIFEST.json` records ordered entry paths/sizes/SHA256, original Git blob IDs and transformations. Its own hash is excluded to avoid a cycle; the closed ZIP and external manifest hashes cover it. Package-specific checks are recorded in task evidence rather than pretending a prior runtime test approved a new package.

Each candidate directory contains the ZIP, `.zip.sha256`, identical external `manifest.json`, a sanitized `build.json` recording actual builder host/runtime, and an ownership marker. The artifact directory is local ignored output, not release content. Builder-host data stays outside the ZIP so identical source inputs can be compared across shells.

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/package.ps1 -VerifyDirectory '<absolute-candidate-directory>'
```

Verification checks final ZIP/sidecar/manifest hashes, internal provenance, the exact allowlist/order, normalized metadata and every entry's size/hash. A SHA256 checksum detects changed bytes; it is not publisher authentication, signing or a guarantee that hostile content is safe.

ZIP entries use ordinal path order, explicit UTF8 names, timestamp1980-01-01, zero external attributes and NoCompression. Generated JSON is compact UTF8 without BOM, with LF termination and ordered properties. This small text/script package favors predictable bytes over compression ratio. Repeated PS5.1/PS7 and cross-host equality are measured in [M5-02 evidence](../codex-winvidcompress/evidence/WVC-M5-02.md), with exact source/ZIP hashes. API choices alone do not establish reproducibility on untested runtimes/filesystems. Build reports may differ by actual host while payload manifests should agree for identical inputs.

Extract a candidate into a fresh folder and follow its README with separately installed verified dependencies and isolated source/output/config for smoke tests. Task evidence records the pushed-commit clean-clone reconstruction and extracted synthetic smoke. Browser/MOTW/fresh-profile/default-Videos/new Explorer/playback and final-candidate distribution retain separate gates. M5-03 reviews licensing/security; M5-05 reconstructs/presents the final candidate. Do not publish/tag/merge/deploy or bundle dependencies without explicit owner approval.
