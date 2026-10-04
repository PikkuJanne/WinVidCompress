"""Read-only Git identity/state utilities for the WinVidCompress handoff.

Developer tooling only. Python 3.10+, standard library, Git. No fetch or writes.
All subprocesses use argument arrays, a timeout, and no shell evaluation.
"""
from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
from urllib.parse import urlsplit

EXPECTED_REPOSITORY = "PikkuJanne/WinVidCompress"
FEATURE_PREFIX = "codex/wvc-"
SHA_RE = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")


class GuardError(RuntimeError):
    """The requested repository operation is not safe/valid."""


class RemoteUnavailable(GuardError):
    """Live remote state could not be verified."""


def git(repo: Path, *args: str, timeout: int = 30) -> subprocess.CompletedProcess[str]:
    executable = shutil.which("git")
    if not executable:
        raise GuardError("Git is not available on PATH; no software was installed.")
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    env["GIT_OPTIONAL_LOCKS"] = "0"
    # Do not replace an explicitly configured SSH transport. Default SSH must
    # not hang prompting for a passphrase/password in this read-only checker.
    env.setdefault("GIT_SSH_COMMAND", "ssh -oBatchMode=yes -oConnectTimeout=10")
    try:
        return subprocess.run(
            [executable, "-c", "core.fsmonitor=false", "-C", str(repo), *args],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=timeout, env=env, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        # Raw command/stderr can contain private URLs/credentials; do not echo.
        if args and args[0] == "ls-remote":
            raise RemoteUnavailable("Live remote query failed or timed out; state is unverified.") from exc
        raise GuardError("A local Git check failed or timed out; no repair was attempted.") from exc


def required(repo: Path, *args: str) -> str:
    result = git(repo, *args)
    if result.returncode != 0:
        raise GuardError(f"Required Git check failed ({args[0]}); no repair was attempted.")
    return result.stdout.strip()


def canonical_repository(url: str) -> str:
    """Accept only standard credential-free GitHub SSH/HTTPS origin forms."""
    value = url.strip()
    if not value or any(c.isspace() for c in value) or "\\" in value:
        raise GuardError("Invalid or unsupported origin URL; no URL is printed or rewritten.")
    scp = re.fullmatch(r"git@github\.com:([^?#]+)", value, flags=re.I)
    if scp:
        path = scp.group(1)
    else:
        try:
            parsed = urlsplit(value)
            port = parsed.port
        except ValueError as exc:
            raise GuardError("Malformed origin URL.") from exc
        if parsed.hostname is None or parsed.hostname.casefold() != "github.com":
            raise GuardError("Origin is not the expected github.com repository.")
        if parsed.query or parsed.fragment:
            raise GuardError("Origin URL query/fragment is not permitted.")
        if parsed.scheme == "https":
            if parsed.username is not None or parsed.password is not None or port not in (None, 443):
                raise GuardError("Credential-bearing or nonstandard HTTPS origin is not permitted.")
        elif parsed.scheme == "ssh":
            if parsed.username != "git" or parsed.password is not None or port not in (None, 22):
                raise GuardError("Only ordinary git@github.com SSH origin is supported.")
        else:
            raise GuardError("Only HTTPS and SSH GitHub origins are supported.")
        path = parsed.path.lstrip("/")
    path = path.rstrip("/")
    if path.lower().endswith(".git"):
        path = path[:-4]
    if path.casefold() != EXPECTED_REPOSITORY.casefold():
        raise GuardError("Origin points to a different repository; no repair was attempted.")
    return EXPECTED_REPOSITORY


def inspect_repository(repo: Path) -> dict:
    root = repo.expanduser().resolve()
    if not root.is_dir():
        raise GuardError("Repository root is not an existing directory.")
    observed_root = Path(required(root, "rev-parse", "--show-toplevel")).resolve()
    if observed_root != root:
        raise GuardError("Supply the actual repository root, not a nested directory.")
    head = required(root, "rev-parse", "HEAD")
    if not SHA_RE.fullmatch(head):
        raise GuardError("Cannot resolve a full existing HEAD commit.")
    branch_result = git(root, "symbolic-ref", "--quiet", "--short", "HEAD")
    branch = branch_result.stdout.strip() if branch_result.returncode == 0 else None
    issues: list[str] = []
    if not branch:
        issues.append("detached_head")
    elif not branch.startswith(FEATURE_PREFIX):
        issues.append("not_a_codex_wvc_feature_branch")
    status = required(root, "status", "--porcelain=v1", "--untracked-files=all", "-z")
    dirty = bool(status)
    if dirty:
        issues.append("dirty_worktree")
    if required(root, "ls-files", "--unmerged"):
        issues.append("unmerged_index")
    operations = []
    for marker in ("MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply", "sequencer", "BISECT_START"):
        marker_path = Path(required(root, "rev-parse", "--git-path", marker))
        if not marker_path.is_absolute():
            marker_path = root / marker_path
        if marker_path.exists():
            operations.append(marker)
    if operations:
        issues.append("git_operation_in_progress")
    fetch_urls = required(root, "remote", "get-url", "--all", "origin").splitlines()
    push_urls = required(root, "remote", "get-url", "--push", "--all", "origin").splitlines()
    if len(fetch_urls) != 1 or len(push_urls) != 1:
        raise GuardError("Exactly one effective origin fetch and one push URL are required.")
    for url in fetch_urls + push_urls:
        canonical_repository(url)
    upstream = None
    if branch:
        upstream = required(root, "for-each-ref", "--format=%(upstream:short)", f"refs/heads/{branch}") or None
    return {
        "repository": EXPECTED_REPOSITORY, "root": str(root), "head": head,
        "branch": branch, "upstream": upstream, "dirty": dirty,
        "operations": operations, "issues": issues,
        "fetch_url": fetch_urls[0], "push_url": push_urls[0],
    }


def query_live_ref(root: Path, url: str, branch: str) -> str | None:
    canonical_repository(url)
    ref = "refs/heads/" + branch
    result = git(root, "ls-remote", "--exit-code", url, ref)
    if result.returncode == 2:  # no matching ref, not an authentication success claim
        return None
    if result.returncode != 0:
        raise RemoteUnavailable("Live remote query failed; network/authentication/ref state is unverified.")
    matches = []
    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[1] == ref and SHA_RE.fullmatch(fields[0]):
            matches.append(fields[0])
    if len(matches) != 1:
        raise RemoteUnavailable("Remote response did not contain exactly one expected valid branch ref.")
    return matches[0]


def public_state(state: dict) -> dict:
    """Do not emit even a validated URL; the repository identity suffices."""
    return {k: v for k, v in state.items() if k not in ("fetch_url", "push_url")}
