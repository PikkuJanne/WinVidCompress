# Decisions and owner approval ledger

## Binding owner constraints carried into this bundle

D001: Improve, do not rewrite. Keep the local PowerShell/FFmpeg application and its existing entry points.

D002: The website presents/distributes the local tool. No server-side processing or upload service.

D003: Preserve the established simple default workflow and encoding profile while hardening reliability.

D004: Local and GitHub work must remain synchronized at meaningful checkpoints and session handoffs; preserve current work/history.

## Conservative implementation choices for this roadmap

P001: Use a feature branch and draft PR; main is not automatically updated. Feature pushes are part of this work; merge/publication is gated.

P002: Keep PATH-before-adjacent dependency precedence initially, with exact resolution diagnostics. A different default requires a recorded reason/approval.

P003: Use first real video by stream index, excluding attached pictures, and uniquely-default audio otherwise first audio. Warn on omissions; do not downmix or force FPS silently. Validate with owner workflow fixtures.

P004: Preserve the height-cap policy rather than introduce a width-bound preset. Fix rotation/aspect/odd-dimension handling with tests. Material changes go through review.

P005: Implement tested SDR compatibility; recognized untested HDR is actionable unsupported input, not guessed tone mapping. Any new default colour transformation receives sample review.

P006: Flat output and collision rename remain defaults. Relative layout, resume and stronger hashing are opt-in. Larger valid output is reported, not automatically destroyed/re-encoded.

P007: First candidate is tool-only; FFmpeg remains an external dependency. No silent updater or packaged executable is added by this handoff.

P008: No production upload/telemetry; private sources and diagnostic paths stay off GitHub. Developer Python helpers do not become an application dependency.

These are roadmap choices, not fabricated owner acceptance of implemented code. If current verified behaviour or later owner instructions require a different choice, record it here and adjust task/acceptance dependencies before changing code.

## Approval gates still pending

Changing default codec/CRF/preset/audio bitrate or materially different geometry/colour handling; bundled third-party binaries; signing setup; license changes; repository settings/secrets; default-branch merge/push; tags/releases; public website deployment. Obtain actual owner approval for the specific action, not a broad inference from “create a bundle.”

## New decision template

ID / date / task / context / options considered / chosen behaviour / compatibility impact / evidence / owner approval when required / superseded decisions. Do not invent approval timestamps, names or messages.
