from pathlib import Path


def _read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def test_ask_agent_exists_with_opencode_frontmatter() -> None:
    text = _read("agents/ask.md")
    assert "description:" in text
    assert "Read-only thinking partner" in text
    assert "write: false" in text
    assert "edit: false" in text
    assert "patch: false" in text
    assert "todowrite: false" in text
    assert "task: false" in text
    assert "bash: true" in text


def test_ask_agent_has_spine_read_only_context() -> None:
    text = _read("agents/ask.md").lower()
    assert "read-only context (spine)" in text
    assert ".cursor/rules/02-memory-bank.md" in text
    assert "domain-glossary.md" in text
    assert "graphify-out/graph.json" in text
    assert "do not" in text and "create or update memory bank" in text


def test_ask_agent_references_cursor_rules_paths() -> None:
    import re

    text = _read("agents/ask.md")
    assert ".cursor/rules/02-memory-bank.md" in text
    assert ".cursor/rules/03-code-quality.md" in text
    assert ".cursor/rules/01-core-protocol.md" in text
    assert not re.search(r"(?<!\.cursor/)rules/0[123]-", text)
    assert "04-code-quality" not in text


def test_ask_agent_has_spine_handoff() -> None:
    text = _read("agents/ask.md").lower()
    assert "spine handoff" in text
    assert "/spine-plan" in text
    assert "/spine-plan-bridge" in text
    assert "grill me" in text or "grill with docs" in text
    assert "build" in text
    assert "do not" in text and "task" in text


def test_ask_agent_allows_read_only_diagnostics() -> None:
    text = _read("agents/ask.md").lower()
    assert "read-only diagnostics" in text
    assert "pytest --collect-only" in text
    assert "git status" in text
    assert "docker ps" in text
    assert "kubectl get" in text


def test_install_sh_deploys_opencode_agents() -> None:
    text = _read("install.sh")
    assert "get_agent_files" in text
    assert ".opencode/agents" in text
    assert "agents/$agent_file" in text
    assert "opencode/agents" in text
    assert "warn_if_global_opencode_agents" in text
    assert "get_mode_files" not in text
    assert ".opencode/modes" not in text
    assert ".config/opencode/agents" in text


def test_readme_documents_project_only_opencode_agents() -> None:
    text = _read("README.md").lower()
    assert "per project only" in text or "project-only" in text
    assert "~/.config/opencode/agents" in text


def test_readme_documents_agents_not_modes() -> None:
    text = _read("README.md")
    assert "agents/" in text
    assert ".opencode/agents/" in text
    assert "modes/ask.md" not in text
    assert "## OpenCode Agents" in text
