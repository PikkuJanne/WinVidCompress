# Security policy

WinVidCompress is a local viewing-copy tool. Identify the exact source commit/candidate version and separately installed FFmpeg/FFprobe build when reporting a problem. The current candidate is unsigned; no certification, security audit guarantee or response deadline is promised.

## Report a security concern

As checked on 2026-10-07, GitHub private vulnerability reporting is disabled for this repository. Open a minimal [security contact request](https://github.com/PikkuJanne/WinVidCompress/issues/new) asking the maintainer for a preferred private reporting channel. **Do not include vulnerability details, exploit instructions, media, logs or personal information in that public request.** Wait for a confirmed private channel before sharing sensitive details. This follows [GitHub's reporting guidance](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately).

If the repository later offers **Report a vulnerability** on its Security/Advisories page, use that private form. Creating this policy does not enable that feature. No project security email address is published here.

For an ordinary non-sensitive bug, use [repository issues](https://github.com/PikkuJanne/WinVidCompress/issues). Supply Windows/PowerShell and native-tool versions, failure stage/exit code, expected behavior and a small synthetic reproduction. Share only reviewed, sanitized diagnostics; see [troubleshooting](docs/user/TROUBLESHOOTING.md#logs-and-bug-reports).

## Trust and privacy boundaries

Run without administrator rights. Obtain dependencies through the [FFmpeg download page](https://ffmpeg.org/download.html), check the chosen provider's integrity/provenance information and keep that build updated. PATH takes precedence over adjacent executables. Review the exact paths shown by the doctor before using them: the doctor executes the selected binaries and checks compatibility, not publisher identity, signatures or harmlessness. Keep executable/script folders and PATH locations under your control. Respect organizational script policy; no permanent policy change or antivirus bypass is required.

The application has no upload, account, telemetry or automatic dependency-download feature. Explicit UNC selections can access shares; native media processing is not a network or hostile-file sandbox. Use disposable synthetic inputs when investigating failures.

Config, logs, manifests, native diagnostics and output metadata can contain private paths, interview names/tags or other sensitive data. Compression does not sanitize source metadata. The optional local diagnostic exporter reduces identifying fields but still requires review before voluntary sharing; it does not encrypt logs or establish private filesystem permissions. Do not attach private footage, credentials or raw diagnostic folders to public issues.

## Distribution decisions

Project code retains the [Unlicense](LICENSE). External dependencies keep their own terms; see [third-party notices](THIRD_PARTY_NOTICES.md). A package SHA256 verifies bytes against the supplied checksum, not a publisher or code signature. Code-signing setup and bundling dependencies require separate owner approval and review before any publication. No signed publisher, certificate or bundled FFmpeg distribution is established by this policy.
