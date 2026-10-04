#!/usr/bin/env python3
"""Read-only point-in-time sync check. Exit 0 synced; 1 not synced; 2 blocked; 3 unknown."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True  # importing helpers must not dirty the repository
from repo_guard import GuardError, RemoteUnavailable, inspect_repository, public_state, query_live_ref


def check(repo: Path, no_network: bool = False) -> tuple[dict, int]:
    report = {"schema_version": 1, "checked_at": datetime.now(timezone.utc).isoformat(),
              "read_only": True, "point_in_time_only": True}
    try:
        state = inspect_repository(repo)
        report.update(public_state(state))
        reasons = list(state["issues"])
        report["reasons"] = reasons
        if not state["branch"] or state["operations"] or "unmerged_index" in reasons:
            report["status"] = "BLOCKED"
            return report, 2
        if state["upstream"] != "origin/" + state["branch"]:
            reasons.append("upstream_not_matching_origin_branch")
        if no_network:
            report.update(status="UNKNOWN", note="Live refs were not queried; cached refs are not proof of synchronization.")
            return report, 3
        root = Path(state["root"])
        fetch_head = query_live_ref(root, state["fetch_url"], state["branch"])
        # Check both effective destinations even when their URL text is equal.
        push_head = query_live_ref(root, state["push_url"], state["branch"])
        report.update(live_fetch_head=fetch_head, live_push_head=push_head)
        if fetch_head is None or push_head is None:
            reasons.append("feature_ref_missing_on_remote")
        if fetch_head != state["head"] or push_head != state["head"]:
            reasons.append("local_head_differs_from_live_remote")
        # Detect changes during the check without claiming an ongoing guarantee.
        end_state = inspect_repository(root)
        if any(end_state[k] != state[k] for k in ("head", "branch", "upstream", "dirty", "operations", "fetch_url", "push_url")):
            reasons.append("repository_changed_during_check")
        report["status"] = "SYNCHRONIZED" if not reasons else "UNSYNCHRONIZED"
        return report, 0 if not reasons else 1
    except RemoteUnavailable as exc:
        report.update(status="UNKNOWN", error=str(exc))
        return report, 3
    except GuardError as exc:
        report.update(status="BLOCKED", error=str(exc))
        return report, 2


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True, help="Actual existing repository root")
    parser.add_argument("--no-network", action="store_true", help="Inspect locally only; never reports synchronized")
    args = parser.parse_args()
    report, code = check(args.repo, args.no_network)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
