"""OpenCode consumer template contract tests."""

import json
from pathlib import Path


def _load_template() -> dict:
    return json.loads(Path("templates/opencode.json").read_text(encoding="utf-8"))


def test_opencode_template_has_model_and_default_agent() -> None:
    cfg = _load_template()
    assert cfg["$schema"] == "https://opencode.ai/config.json"
    assert cfg["model"]
    assert cfg["default_agent"] == "ask"
    assert cfg["model"] == "opencode-go/deepseek-v4-pro"
    assert cfg["small_model"] == "nvidia/deepseek-ai/deepseek-v4-pro"
    assert cfg["small_model"]


def test_opencode_template_registers_ask_agent() -> None:
    cfg = _load_template()
    ask = cfg["agent"]["ask"]
    assert ask["mode"] == "primary"
    assert ask["model"] == "opencode-go/deepseek-v4-pro"
    assert ask["prompt"] == "{file:.spine/agents/ask.md}"
    assert ask["permission"]["edit"] == "deny"
    assert ask["permission"]["bash"] == "allow"
    assert "variant" not in ask


def test_opencode_template_build_agent_configured() -> None:
    cfg = _load_template()
    build = cfg["agent"]["build"]
    assert build["mode"] == "primary"
    assert build["model"] == "opencode-go/deepseek-v4-pro"
    assert build["variant"] == "medium"


def test_opencode_template_plan_agent_medium_variant() -> None:
    cfg = _load_template()
    plan = cfg["agent"]["plan"]
    assert plan["mode"] == "primary"
    assert plan["variant"] == "medium"


def test_opencode_template_has_spine_instructions_and_compaction() -> None:
    cfg = _load_template()
    assert len(cfg["instructions"]) == 3
    assert "02-memory-bank.md" in cfg["instructions"][1]
    assert cfg["compaction"]["enabled"] is True
