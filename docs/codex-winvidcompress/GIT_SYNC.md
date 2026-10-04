# Local and GitHub synchronization runbook

## Authority and safety

The actual checkout and live GitHub repository are the working facts. The 2026-10-04 source anchor is historical context, never a reset target. The feature branch on GitHub is the cross-machine continuity source. Only one active writer uses this checkout/branch; do not run competing local/cloud implementations against it. Windows CI may validate pushed commits but does not replace local manual testing.

Feature-branch commits/pushes and a draft PR are within this improvement workflow. Merge, default-branch pushes, force-push/history rewrite, tags/releases, repository settings/secrets, branch deletion and website deployment require separate explicit owner approval. Never stage credentials/private videos/logs. Hooks and repository instructions are code/trust boundaries: inspect existing project guidance and do not bypass runtime permissions.

## First session

Read all applicable existing AGENTS instructions. Determine the real repository root; do not guess C:\projects or clone over an existing directory. Inspect `git status --short --untracked-files=all`, `git branch --show-current`, `git rev-parse HEAD`, operation/conflict state, all effective origin fetch and push URLs, upstream, and working-tree diff. Origin must resolve only to PikkuJanne/WinVidCompress on github.com; credentials embedded in URLs, unexpected remotes, multiple push destinations or a detached head require correction with owner involvement.

Fetch origin, then compare the live main and existing feature state to the reviewed baseline. If clean and behind, a fast-forward may be used after inspection; if diverged, preserve both histories and stop for a reviewed reconciliation. Never auto-stash, reset --hard, git clean or force-push. A dirty checkout is not permission to discard another task's work.

Create or resume `codex/wvc-hardening` (or a documented `codex/wvc-*` feature name). Do not import the bundle onto main/master. A clean branch created from the inspected current base is required. Existing feature work may already implement tasks: reconcile evidence and retain it instead of replacing files.

Run the external importer in preview mode and verify its additions. Apply only to the exact inspected HEAD with `--apply --expected-head <sha>`. It does not switch, fetch, stage, commit or push. Existing different files cause refusal; keep/merge an existing AGENTS.md explicitly. Do not reimport the original template over live TASKS/STATUS files later.

## Every task

Inspect current state and fetch before edits. Read NEXT_SESSION and the task's dependency/evidence state. Implement one ready slice, add regression coverage, run quick plus relevant targeted tests and inspect diffs. Stage specific intended paths, not `git add .` over unknown files. Inspect staged content and confirm no private material.

A practical checkpoint sequence is:

1. Commit implementation + tests as a reviewable unit; run/record relevant tests against this exact commit or identify the precisely tested tree.
2. Record implementation SHA, real command/results and pending checks in task/evidence/status files. Update NEXT_SESSION with a precise next task. Commit those handoff files.
3. Push the current feature branch with an explicit refspec, for example `git push -u origin HEAD:refs/heads/codex/wvc-hardening` after confirming the branch name. Do not use --force, --mirror, --all or implicit default-branch assumptions.
4. Check the live feature ref on BOTH effective fetch and push destinations, then verify local HEAD and clean worktree. `git ls-remote --exit-code <verified-url> refs/heads/<current-branch>` is authoritative at that check; a cached origin ref alone is not.
5. Open/update a draft PR if available and inspect actual checks for the relevant commit. Pending/unavailable CI is not passed CI. Do not mark ready/merge automatically.

The included `tools/codex-winvidcompress/check_repo_sync.py --repo <root>` is read-only: it queries live refs, validates effective remote identity, branch/upstream and worktree, and prints JSON. It never fetches, checks out, stages, commits, pushes or edits files. It is a point-in-time check, not a background synchronizer. It requires Git and developer Python 3.10+; these are not new application runtime dependencies.

## Avoid the self-SHA loop

A commit cannot contain its own final SHA without changing that SHA. Store the preceding implementation/tested SHA and any previously verified checkpoint in committed evidence. Commit the final handoff with its current push verification pending. After pushing that commit, report final local/remote HEAD in the Codex response or PR comment (not another edit merely to encode the same commit's SHA). The next session independently verifies live state before relying on it. An older sync record must be labelled with the commit/time it actually describes.

## Failure states

Push rejection or divergence: do not force. Fetch and explain differing commits; preserve local changes. Network/auth unavailable: record unsynchronized/unknown, local branch/HEAD and the exact pending action; no completion or machine handoff may claim synchronization. If task work is already committed and a push fails, it remains safely local but unshared. Dirty worktree after handoff means the checkpoint is not fully synchronized, even if HEAD matches.

If an interrupted session leaves work uncommitted, the next thread inventories it first and resumes only after establishing ownership. Do not blindly reapply the bundle or rerun completed tasks. If a milestone awaits owner approval, other safe independent tasks can be prepared without crossing that gate.

## Session-end response contract

Report task and actual state, implementation/tested commit(s), changed files, test/CI results and skips, current branch, final local HEAD, live GitHub feature HEAD(s), worktree state, draft PR state, blockers/owner approvals and exact next task. Say clearly when any part could not be checked. Commit/push before switching machines; the next machine fetches and verifies before editing. main and website remain unchanged until approved.
