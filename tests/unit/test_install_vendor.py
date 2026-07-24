"""Smoke checks for vendor-mode install script."""

from pathlib import Path


def _read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def test_install_vendor_script_exists() -> None:
    path = Path("scripts/install-vendor.sh")
    assert path.is_file()
    text = _read("scripts/install-vendor.sh")
    assert "Vendor mode" in text or "vendor" in text.lower()


def test_install_vendor_documents_symlink_conflict_and_force() -> None:
    text = _read("scripts/install-vendor.sh")
    assert "--force" in text
    assert "Symlink-mode" in text or "symlink" in text.lower()
    assert ".spine-vendor" in text


def test_install_vendor_update_requires_spine_dir() -> None:
    text = _read("scripts/install-vendor.sh")
    assert "--update requires --spine-dir" in text
    assert "rsync" in text
    assert "--delete" in text


def test_install_vendor_excludes_nested_git() -> None:
    text = _read("scripts/install-vendor.sh")
    assert "--exclude='.git/'" in text or 'exclude=".git/"' in text or ".git/" in text
    assert "removed nested .git" in text or "never leave a nested git" in text


def test_install_vendor_preserves_docs_memory_on_seed() -> None:
    text = _read("scripts/install-vendor.sh")
    assert "already exists, not overwriting" in text
    assert "get_docs_seed_paths" in text


def test_readme_documents_vendor_install() -> None:
    text = _read("README.md")
    assert "Optional: Vendor install" in text
    assert "install-vendor.sh" in text
