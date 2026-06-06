#!/usr/bin/env python3
"""Merge Spine rule instructions into a consumer project opencode.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def merge_opencode(template_path: Path, project_path: Path) -> str:
    """Merge template instructions into project opencode.json.

    Args:
        template_path: Path to Spine templates/opencode.json.
        project_path: Path to consumer project opencode.json.

    Returns:
        Human-readable status message for the caller.
    """
    template = json.loads(template_path.read_text(encoding="utf-8"))
    required = template.get("instructions", [])

    if project_path.exists():
        project = json.loads(project_path.read_text(encoding="utf-8"))
        action = "merged"
    else:
        project = dict(template)
        action = "created"

    if action == "merged":
        instructions = project.get("instructions", [])
        if not isinstance(instructions, list):
            instructions = []

        seen: set[str] = set()
        merged: list[str] = []
        for item in instructions + required:
            if isinstance(item, str) and item not in seen:
                merged.append(item)
                seen.add(item)

        project["instructions"] = merged
        if "$schema" not in project and "$schema" in template:
            project["$schema"] = template["$schema"]

    project_path.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
    return f"{action}: {project_path}"


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: merge-opencode.py TEMPLATE_OPENCODE PROJECT_OPENCODE",
            file=sys.stderr,
        )
        return 1

    template_path = Path(sys.argv[1])
    project_path = Path(sys.argv[2])

    if not template_path.is_file():
        print(f"ERROR: template not found: {template_path}", file=sys.stderr)
        return 1

    message = merge_opencode(template_path, project_path)
    print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
