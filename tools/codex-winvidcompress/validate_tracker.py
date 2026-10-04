#!/usr/bin/env python3
"""Validate task/dependency/evidence consistency, without modifying repository files."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

sys.dont_write_bytecode = True
STATUSES = {"todo", "in_progress", "blocked", "implemented", "verified", "accepted", "deferred"}
AC_STATUSES = {"not_run", "passed", "failed", "skipped", "blocked", "not_applicable"}
ID_RE = re.compile(r"^WVC-M[0-9]+-[0-9]{2}[A-Z]?$" )


def member(value: object, choices: set[str]) -> bool:
    return isinstance(value, str) and value in choices


def validate(path: Path) -> dict:
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        return {"valid": False, "errors": [f"Cannot read task JSON: {type(exc).__name__}" ]}
    if not isinstance(data, dict) or data.get("schema_version") != 1 or not isinstance(data.get("tasks"), list):
        return {"valid": False, "errors": ["Expected schema_version 1 and a tasks array."]}
    tasks = data["tasks"]
    by_id: dict[str, dict] = {}
    criteria_ids: set[str] = set()
    covered: set[int] = set()
    count = 0
    root = path.parent.resolve()
    for t in tasks:
        if not isinstance(t, dict):
            errors.append("Task is not an object.")
            continue
        tid = t.get("id")
        if not isinstance(tid, str) or not ID_RE.fullmatch(tid):
            errors.append("Task has an invalid ID.")
            continue
        if tid in by_id:
            errors.append(f"Duplicate task ID: {tid}")
        by_id[tid] = t
        if t.get("milestone") != tid.split("-")[1]:
            errors.append(f"{tid}: milestone does not match ID.")
        if not member(t.get("status"), STATUSES):
            errors.append(f"{tid}: invalid status.")
        if not (root / "tasks" / f"{tid}.md").is_file():
            errors.append(f"{tid}: task brief is missing.")
        imps = t.get("improvements", [])
        if not isinstance(imps, list) or any(type(i) is not int or not 1 <= i <= 23 for i in imps):
            errors.append(f"{tid}: invalid review mapping.")
        else:
            covered.update(imps)
        if not isinstance(t.get("depends_on"), list) or any(not isinstance(d, str) for d in t.get("depends_on", [])):
            errors.append(f"{tid}: invalid dependency list.")
        acceptance = t.get("acceptance")
        if not isinstance(acceptance, list) or not acceptance:
            errors.append(f"{tid}: no acceptance criteria.")
            continue
        for a in acceptance:
            count += 1
            if not isinstance(a, dict):
                errors.append(f"{tid}: acceptance item is not an object.")
                continue
            aid = a.get("id")
            if not isinstance(aid, str) or not re.fullmatch(re.escape(tid) + r"-A[0-9]{2}", aid):
                errors.append(f"{tid}: invalid acceptance ID.")
            elif aid in criteria_ids:
                errors.append(f"Duplicate acceptance ID: {aid}")
            else:
                criteria_ids.add(aid)
            if not member(a.get("status"), AC_STATUSES) or not member(a.get("tier"), {"quick", "targeted", "full", "manual"}):
                errors.append(f"{aid}: invalid status or tier.")
            evidence = a.get("evidence", [])
            if not isinstance(evidence, list) or any(not isinstance(e, str) for e in evidence):
                errors.append(f"{aid}: evidence must be relative-path strings.")
                evidence = []
            if a.get("status") == "passed" and not evidence:
                errors.append(f"{aid}: passed without evidence.")
            if member(a.get("status"), {"skipped", "not_applicable", "blocked", "failed"}) and not a.get("notes"):
                errors.append(f"{aid}: outcome requires explanatory notes.")
            for entry in evidence:
                file = (root / entry).resolve()
                if not file.is_relative_to(root) or not file.is_file() or "TEMPLATE" in file.name.upper():
                    errors.append(f"{aid}: missing/unsafe/template evidence path.")
            if member(t.get("status"), {"verified", "accepted"}) and not member(a.get("status"), {"passed", "not_applicable"}):
                errors.append(f"{tid}: verified/accepted with incomplete acceptance.")
        if t.get("status") == "accepted" and t.get("approval_gate") and not t.get("owner_approval"):
            errors.append(f"{tid}: accepted without owner approval record.")
        if t.get("status") == "deferred" and (not t.get("deferral_reason") or not t.get("owner_approval")):
            errors.append(f"{tid}: deferral needs reason and actual owner approval.")
    if covered != set(range(1, 24)):
        errors.append("Not all 23 review improvements are mapped.")
    for tid, t in by_id.items():
        deps = t.get("depends_on", [])
        if isinstance(deps, list):
            for dep in deps:
                if not isinstance(dep, str) or dep not in by_id or dep == tid:
                    errors.append(f"{tid}: unknown/self dependency.")
    visiting: set[str] = set()
    visited: set[str] = set()
    def visit(tid: str) -> None:
        if tid in visiting:
            errors.append(f"Dependency cycle at {tid}.")
            return
        if tid in visited:
            return
        visiting.add(tid)
        deps = by_id[tid].get("depends_on", [])
        if isinstance(deps, list):
            for dep in deps:
                if isinstance(dep, str) and dep in by_id:
                    visit(dep)
        visiting.remove(tid)
        visited.add(tid)
    for tid in by_id:
        visit(tid)
    return {"valid": not errors, "tasks": len(by_id), "acceptance_criteria": count,
            "improvements_covered": len(covered), "errors": errors}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True, help="Repository root, or repo-files in the external bundle")
    args = parser.parse_args()
    report = validate(args.repo / "docs/codex-winvidcompress/TASKS.json")
    print(json.dumps(report, indent=2))
    return 0 if report["valid"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
