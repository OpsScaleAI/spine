"""Tests for Graphify OpenCode plugin merge into consumer opencode.json."""

import json
import subprocess
import sys
from pathlib import Path


def _run_merge(*args: str) -> subprocess.CompletedProcess[str]:
    script = Path("scripts/merge-graphify-opencode.py")
    return subprocess.run(
        [sys.executable, str(script), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def test_merge_graphify_plugin_into_project_opencode(tmp_path: Path) -> None:
    project = tmp_path / "opencode.json"
    local = tmp_path / ".opencode" / "opencode.json"
    local.parent.mkdir(parents=True)

    project.write_text(
        json.dumps(
            {
                "instructions": [
                    "https://example.com/02-memory-bank.md",
                ],
                "agent": {"ask": {"prompt": "{file:.spine/agents/ask.md}"}},
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    local.write_text(
        json.dumps(
            {"plugin": [".opencode/plugins/graphify.js"]},
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    result = _run_merge("merge", str(project), str(local))
    assert result.returncode == 0
    assert "merged graphify plugin" in result.stdout

    merged = json.loads(project.read_text(encoding="utf-8"))
    assert "https://example.com/02-memory-bank.md" in merged["instructions"]
    assert merged["agent"]["ask"]["prompt"] == "{file:.spine/agents/ask.md}"
    assert ".opencode/plugins/graphify.js" in merged["plugin"]


def test_strip_graphify_plugin_from_project_opencode(tmp_path: Path) -> None:
    project = tmp_path / "opencode.json"
    project.write_text(
        json.dumps(
            {
                "plugin": [
                    ".opencode/plugins/graphify.js",
                    ".opencode/plugins/other.js",
                ],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    result = _run_merge("strip", str(project))
    assert result.returncode == 0
    assert "stripped graphify plugin" in result.stdout

    stripped = json.loads(project.read_text(encoding="utf-8"))
    assert stripped["plugin"] == [".opencode/plugins/other.js"]
