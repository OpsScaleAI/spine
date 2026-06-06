from pathlib import Path


def _read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def test_install_sh_defines_seed_docs_templates() -> None:
    text = _read("install.sh")
    assert "seed_docs_templates()" in text
    assert "get_docs_seed_paths()" in text


def test_install_seed_allowlist_covers_v21_paths() -> None:
    text = _read("install.sh")
    required = [
        "memory/ledger/learnings.md",
        "governance/memory-tags-policy.md",
        "memory/active_tasks/_task-template.md",
        "completed_tasks/.gitkeep",
        "docs/documentation",
    ]
    for path in required:
        assert path in text, f"missing seed reference: {path}"


def test_install_sh_does_not_seed_sample_task() -> None:
    text = _read("install.sh")
    assert "003-fix-quote-item" not in text


def test_install_sh_uses_merge_or_copy_opencode() -> None:
    text = _read("install.sh")
    assert "merge_or_copy_opencode" in text
    assert "merge-opencode.py" in text


def test_merge_opencode_helper_exists() -> None:
    text = _read("scripts/merge-opencode.py")
    assert "def merge_opencode" in text


def test_spine_install_command_removed() -> None:
    assert not Path("commands/spine-install.md").exists()
