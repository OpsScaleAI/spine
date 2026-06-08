#!/usr/bin/env python3
"""Merge Graphify OpenCode plugin registration into consumer project opencode.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

GRAPHIFY_PLUGIN_MARKERS = ("graphify.js", "plugins/graphify")


def _is_graphify_plugin_entry(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    lower = value.lower()
    return any(marker in lower for marker in GRAPHIFY_PLUGIN_MARKERS)


def _merge_plugin_lists(existing: Any, incoming: Any) -> list[str]:
    merged: list[str] = []
    seen: set[str] = set()

    for source in (existing, incoming):
        if not isinstance(source, list):
            continue
        for item in source:
            if isinstance(item, str) and item not in seen:
                merged.append(item)
                seen.add(item)

    return merged


def merge_graphify_into_opencode(
    project_path: Path,
    graphify_local_path: Path | None = None,
) -> str:
    """Merge Graphify plugin keys from .opencode/opencode.json into project opencode.json.

    Args:
        project_path: Consumer project root opencode.json path.
        graphify_local_path: Optional .opencode/opencode.json path.

    Returns:
        Human-readable status message.
    """
    if graphify_local_path is None:
        graphify_local_path = project_path.parent / ".opencode" / "opencode.json"

    if not project_path.exists():
        raise FileNotFoundError(f"project opencode.json not found: {project_path}")

    project = json.loads(project_path.read_text(encoding="utf-8"))
    changed = False

    if graphify_local_path.is_file():
        graphify_cfg = json.loads(graphify_local_path.read_text(encoding="utf-8"))
        for key in ("plugin", "plugins"):
            if key not in graphify_cfg:
                continue
            before = project.get(key, [])
            after = _merge_plugin_lists(before, graphify_cfg[key])
            if after != before:
                project[key] = after
                changed = True

    project_path.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
    if changed:
        return f"merged graphify plugin into: {project_path}"
    return f"no graphify plugin changes needed: {project_path}"


def strip_graphify_from_opencode(project_path: Path) -> str:
    """Remove Graphify plugin entries from project opencode.json.

    Args:
        project_path: Consumer project root opencode.json path.

    Returns:
        Human-readable status message.
    """
    if not project_path.exists():
        return f"skip (missing): {project_path}"

    project = json.loads(project_path.read_text(encoding="utf-8"))
    changed = False

    for key in ("plugin", "plugins"):
        if key not in project or not isinstance(project[key], list):
            continue
        filtered = [item for item in project[key] if not _is_graphify_plugin_entry(item)]
        if filtered != project[key]:
            if filtered:
                project[key] = filtered
            else:
                del project[key]
            changed = True

    if changed:
        project_path.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
        return f"stripped graphify plugin from: {project_path}"
    return f"no graphify plugin to strip: {project_path}"


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: merge-graphify-opencode.py merge PROJECT_OPENCODE [GRAPHIFY_LOCAL_OPENCODE]",
            file=sys.stderr,
        )
        print(
            "       merge-graphify-opencode.py strip PROJECT_OPENCODE",
            file=sys.stderr,
        )
        return 1

    action = sys.argv[1]

    if action == "merge":
        if len(sys.argv) < 3:
            print("ERROR: PROJECT_OPENCODE required for merge.", file=sys.stderr)
            return 1
        project_path = Path(sys.argv[2])
        local_path = Path(sys.argv[3]) if len(sys.argv) > 3 else None
        print(merge_graphify_into_opencode(project_path, local_path))
        return 0

    if action == "strip":
        if len(sys.argv) < 3:
            print("ERROR: PROJECT_OPENCODE required for strip.", file=sys.stderr)
            return 1
        print(strip_graphify_from_opencode(Path(sys.argv[2])))
        return 0

    print(f"ERROR: unknown action: {action}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
