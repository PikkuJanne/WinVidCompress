# Security, CI and release candidate preparation

## Runtime and diagnostics

Run without administrator rights. No automatic executable downloads, installer execution, telemetry, uploads, global PATH edits, permanent execution-policy changes or antivirus-disable instructions. Treat media and metadata as untrusted data, use supported tools, and document dependency maintenance. A local tool can still read explicitly selected UNC files; that is not a cloud converter, but do not describe network shares as literally no network access.

Resolve exact executable paths/capabilities and report versions. If a command name resolves to a function/alias or unexpected binary, fail rather than executing it as trusted FFmpeg. Do not capture credentials or private media in shared logs. Ensure diagnostic exports are redacted and voluntary.

## CI

Use Windows PowerShell 5.1 and a supported stable PowerShell 7; pin selected versions after checking official support. GitHub Actions should run the repository's real tests with minimal `contents: read` style permissions unless a specific task justifies more. Pin third-party actions to reviewed full commits. Keep dependency-download sources and integrity/provenance recorded. No secret-bearing workflow for untrusted pull requests; no privileged pull_request_target execution of contributor code.

CI checks report actual source commit and test outcomes. A newly written YAML file is not a passed CI run. Do not enable auto-merge, change branch protection or create releases merely by adding the testing pipeline.

## Packaging

Inspect actual repository tags/releases before choosing a version. Build a tool-only candidate ZIP from a clean tracked commit using a positive file allowlist: script, launcher, any companion runtime helper/module they actually import, needed assets, user instructions, LICENSE and applicable notices. Development handoff/Python tools, tests, .git, config, logs, source videos and dependency binaries stay out of the user package unless specifically justified.

Record package version, exact source commit and tested environment/dependencies. Sort contents and normalize packaging metadata where feasible. Compare two builds; claim byte reproducibility only when demonstrated, otherwise describe reproducible contents and the precise remaining metadata variation. Generate SHA-256 for final ZIP bytes, verify extraction and inspect contents. A checksum detects changed bytes; it is not publisher authentication or a code-signature guarantee.

Reconstruct from a clean clone of the pushed feature branch on the active workstation, with only documented dependencies. Extract the candidate into a new folder and run a synthetic first-use smoke test there. A developer checkout that happens to work is not sufficient distribution validation.

## Licensing and signing

Keep the repository's existing Unlicense. FFmpeg uses separate build-dependent license terms; refer to its official legal guidance. The initial candidate does not bundle FFmpeg, so do not relabel external binaries as covered by the project's Unlicense. Third-party notices should describe actual distributed components only. This is a distribution-review checklist, not a claim of legal clearance for every jurisdiction or codec patent situation.

Bundled dependency distribution or code signing is a separate owner-approved decision with build/provenance/notices/source-obligation review as appropriate. Do not invent certificates, publishers, verified badges or signed status. SECURITY.md must use a real reporting route approved/available to the owner, not a fabricated email address.

## Publication gate

Prepare local release notes and artifacts but do not push tags, merge main, publish a release, alter repository settings or deploy the website without explicit owner approval for each action. A draft PR is not a release. A local candidate version is not yet a published download. After authorized publication, verify that the distributed bytes match the recorded checksum before connecting website metadata.
