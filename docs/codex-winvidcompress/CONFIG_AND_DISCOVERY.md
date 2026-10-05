# Configuration and input discovery specification

## Configuration

Continue to understand the existing `%APPDATA%\WinVidCompress\config.json` with `{ "OutputDir": "..." }`. Inject config/output roots into tests; never test against the actual user profile. Validate JSON root, property presence/type and path semantics before strict property access. Unknown keys should survive a compatible save where possible.

A missing config may use the Windows known Videos folder on a normal first run. A malformed config may be preserved under a collision-safe diagnostic backup and replaced with explicit defaults, with an explanatory message. If the known-folder path is empty or unusable, fail clearly; do not choose an arbitrary root. An offline destination/permission failure is not malformed JSON. Do not overwrite the saved destination or quietly put videos somewhere else.

Use owned temporary writes and tested atomic replace/no-clobber primitives; retain a last valid file on failure. Protect simultaneous writers or diagnose conflict. Do not claim all network filesystems provide identical atomicity. `-WhatIf` and `-CheckEnvironment` do not create config, directories or backups.

M1-03 implements object-root/type validation and absolute drive/UNC path syntax checks. A usable known Videos directory is required for first-run defaults or malformed recovery. Recovery preserves exact original bytes in `config.invalid-<unique>.json` and prints the reason and backup location. A valid saved directory that is missing, offline, a file, or inaccessible stops startup without changing the saved destination. Directory access is checked without creating output; a later write-only denial still fails at the actual write.

Saves use an exclusive `config.json.lock` sidecar, a byte-exact loaded snapshot, an owned sibling CreateNew temporary file, a no-clobber `config.previous-<unique>.json` backup, and File.Replace (existing) or no-clobber File.Move (first run). The empty lock sidecar remains to avoid lock-deletion races. Backups are retained; no automatic pruning. A stale session must restart/reload before saving. The menu saves a copied config before changing its active preference. These primitives coordinate participating instances; external editors that ignore the lock can still race, and network filesystem/crash durability is not guaranteed by the local Windows checks.

Unknown compatible keys survive deep serialization without a schema reset. Objects/arrays beyond JSON depth 100 are refused before writing, including on PS5.1 where the serializer otherwise silently truncates. Hosts exposing ConvertFrom-Json DateKind use String to retain timestamp strings; older PowerShell 7 hosts can normalize ISO timestamp formatting through their standard DateTime conversion. PS5.1 and tested PS7.6.5 preserve the tested unknown timestamp string exactly. Preview/environment flags are later CLI scope; M1-03 does not introduce them.

## Selection/discovery

Resolve existing filesystem sources with literal semantics. Reject web URLs and unsupported filesystem-provider inputs; UNC sources may be supported as explicit user-selected network files, not as an upload service. Source-folder selection never creates missing folders. Output-folder creation requires actual output selection/run intent and is disabled under WhatIf.

Keep the existing extension list as the baseline. An extension is only a candidate filter, not proof that the content is video. Explicit files need the same supported-media/preflight policy as discovered files. Adding extensions is a deliberate tested change, not a generic accept-anything bypass.

Normalize results into arrays; expose inaccessible subtrees and invalid selections as scan errors. Establish a reparse-point policy before recursion; do not follow junction loops or silently traverse out of selected roots. Case-insensitive normalized Windows path identity is the default deduplication key; document that alternate filesystem identities/hard links need additional evidence.

Collect the entire queue once, deduplicate and sort, then encode sequentially. Resolve intended output paths before/at job boundaries with race-safe final promotion. Inputs changing during a run must be detected (at least size/mtime before/after); report/retry rather than present a result as a faithful copy of a moving input.

## Destination overlap and layout

Do not exclude all MP4 files, all files containing `(compressed)`, or every original inside OutputDir. Snapshotting prevents same-run output re-ingestion. Across runs, only a trusted ownership manifest or specifically managed job-temporary area can prove a generated output; ambiguous files remain visible, never silently deleted.

Preserve flat output by default. An opt-in relative layout must define stable root mapping for multiple inputs and repeated root names. Derived paths must stay beneath the destination root; forbid rooted relative names, traversal and reparse escapes. If input equals the nominal final destination, choose a safe new output or skip by policy—never overwrite it.
