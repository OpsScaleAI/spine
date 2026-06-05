from pathlib import Path


def _read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def test_graphify_policy_is_optional_and_consumer_scoped() -> None:
    text = _read("templates/docs/memory/global/system-patterns.md").lower()
    assert "graphify" in text
    assert "optional" in text
    assert "not a dependency" in text or "nao e dependencia" in text
    assert "consumer" in text or "projeto consumidor" in text


def test_spine_install_has_optional_graphify_onboarding() -> None:
    text = _read("commands/spine-install.md").lower()
    assert "graphify" in text
    assert "optional" in text
    assert ".graphifyignore" in text
    assert "no changes to core instruction loading" in text or "3 core" in text


def test_spine_bootstrap_detects_graphify_artifacts() -> None:
    text = _read("commands/spine-bootstrap.md").lower()
    assert "graphify-out/" in text
    assert ".graphifyignore" in text
    assert "mandatory summary" in text and "graphify" in text


def test_spine_plan_has_conditional_graph_first_guidance() -> None:
    text = _read("commands/spine-plan.md").lower()
    assert "graphify-out/graph.json" in text
    assert "query graph first" in text
    assert "fallback" in text


def test_core_rules_keep_memory_bank_mandatory_and_graph_conditional() -> None:
    core = _read("rules/01-core-protocol.md").lower()
    memory = _read("rules/02-memory-bank.md").lower()
    assert "follow `02-memory-bank.md`" in core
    assert "graphify" in core
    assert "docs/memory/" in memory
    assert "graphify-out/graph.json" in memory
    assert "memory bank remains mandatory" in memory


def test_graphifyignore_template_exists() -> None:
    p = Path("templates/dot.graphifyignore")
    assert p.exists()
    text = p.read_text(encoding="utf-8")
    assert ".spine" in text
    assert ".agents/" in text
    assert ".cursor/" in text
    assert ".opencode/" in text


def test_readme_documents_graphify_setup_for_existing_projects() -> None:
    text = _read("README.md").lower()
    assert "## optional: graphify" in text
    assert "uv tool install graphifyy" in text or "graphifyy" in text
    assert "existing project" in text
    assert "--graphify-init" in text
    assert "install.sh --with-graphify" in text
    assert "graphify update ." in text
    assert "graphify-out/graph.json" in text


def test_system_patterns_links_to_readme_graphify_section() -> None:
    text = _read("templates/docs/memory/global/system-patterns.md")
    assert "github.com/opsscaleai/spine#optional-graphify" in text.lower()


def test_spine_update_documents_existing_project_graphify_adoption() -> None:
    text = _read("commands/spine-update.md").lower()
    assert "adopt graphify on an existing project" in text
    assert "--graphify-init" in text
    assert "graphify-out/graph.json" in text
