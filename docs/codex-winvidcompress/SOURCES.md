# Sources and evidence provenance

Accessed/rechecked 2026-10-04. Repository source came from connected GitHub reads; public technical documentation was consulted through web browsing. Engineering requirements, task breakdown and helper design are original recommendations, not quotations. No external article, executable, media or font is redistributed.

## SRC-REPO — Reviewed source, script, launcher, README and license

https://github.com/PikkuJanne/WinVidCompress/tree/5bab7fc698d153128babe3421ce19c0ca3012cc5

Immutable inspection anchor; current checkout must be rechecked.

## SRC-PS-BREAK — Microsoft: about_Break

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_break?view=powershell-5.1

A break leaves its current construct; labelled exits have a different target.

## SRC-PS-STRICT — Microsoft: Set-StrictMode

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode

Missing-property errors and strict-mode rules motivate wrong-shaped config tests.

## SRC-CMD — Microsoft: cmd

https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cmd

Delayed expansion and shell special characters must be considered in launcher tests.

## SRC-PS-PARSE — Microsoft: about_Parsing

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing?view=powershell-7.5

Native argument handling differs across PowerShell generations; run the actual host matrix.

## SRC-FFMPEG — FFmpeg command documentation

https://ffmpeg.org/ffmpeg.html

Reference for explicit stream mapping, progress output, overwrite control, native options and encoding behaviour.

## SRC-FFPROBE — FFprobe documentation

https://ffmpeg.org/ffprobe.html

JSON writer and structured stream/container inspection.

## SRC-FILTERS — FFmpeg filter documentation

https://ffmpeg.org/ffmpeg-filters.html

Reference when deriving tested scale/aspect/colour handling; not an already-validated recipe.

## SRC-FFLEGAL — FFmpeg license and legal considerations

https://ffmpeg.org/legal.html

Build-dependent licensing is separate from the tool project license.

## SRC-GIT-LS — Git: git-ls-remote

https://git-scm.com/docs/git-ls-remote

Queries live remote references and commit IDs; it does not synchronize work by itself.

## SRC-GIT-PUSH — Git: git-push

https://git-scm.com/docs/git-push

Explicit branch/refspec push behaviour and non-fast-forward safety.

## SRC-PESTER — Pester Quick Start

https://pester.dev/docs/quick-start

PowerShell testing reference; select verified compatible versions during implementation.

## SRC-CI — GitHub: building and testing PowerShell

https://docs.github.com/en/actions/tutorials/build-and-test-code/powershell

Workflow reference for running real PowerShell tests, not proof that this repo already passes.

## SRC-CODEX — OpenAI: custom instructions with AGENTS.md

https://developers.openai.com/codex/guides/agents-md

Repository instructions and contextual instruction discovery; consult current docs and applicable instruction hierarchy.

## Verification boundary

M1-06 option reference (consulted 2026-10-05): [FFprobe documentation](https://ffmpeg.org/ffprobe.html) for show_program_version/show_entries/select_streams, CSV/JSON writers and FFREPORT; [FFmpeg documentation](https://ffmpeg.org/ffmpeg.html) for version, encoders and component-specific help. These describe the interface; synthetic Windows recorder tests do not verify a real installed FFmpeg build.

M2-01 option reference (consulted 2026-10-05): [FFprobe documentation](https://ffmpeg.org/ffprobe.html) for JSON, show_streams/show_format and stream metadata; [FFmpeg protocol documentation](https://ffmpeg.org/ffmpeg-protocols.html) for protocol_whitelist and file access. Native synthetic fixtures verify our invocation/parsing contract, not installed demuxer behavior or an absolute offline guarantee.

M2-02 option reference (consulted 2026-10-05): [FFmpeg stream selection documentation](https://www.ffmpeg.org/ffmpeg.html#Stream-selection) for automatic versus explicit mapping and zero-based absolute stream indices; mapped-stream metadata/disposition and channel-layout defaults. Synthetic argv checks establish requested mapping; installed-tool output read-back is separately required.

Public documentation is a reference, not a guarantee of the exact installed build. Codex must verify supported versions/capabilities when implementing. Container network access was not available to exercise live Git operations during helper tests; remote-query behaviour is tested against disposable local Git fixtures via a test-only transport seam. The live repository anchor was read through the GitHub connector. No Windows PowerShell, Explorer launch or actual interview conversion was executed by this bundle.
