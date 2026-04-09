---
description: "Protocolo de handoff lógico para contexto de task (modo solo por padrão)."
globs: 
alwaysApply: true
---

# HANDOFF PROTOCOL (Solo / Opcional Multi-Agent)

Este projeto opera em modo solo por padrão. Quando houver multiplos agentes, o handoff continua via filesystem (`docs/memory/active_tasks/`).

## Modo Solo (padrão)
- A task ativa (`<numero-sequencial>-<nome-descritivo>.md`) funciona como contrato de execução.
- O mesmo agente pode planejar, executar e colher aprendizados.
- Atualizações obrigatórias ao final: `progress.md` e, quando necessário, `decision-log.md`.

## Modo Multi-Agente (opcional)
- Pode separar Planner/Executor se trouxer ganho real.
- Não é obrigatório usar `docs/discovery/` ou `docs/contracts/` em toda task.
- O mínimo continua sendo: task ativa clara + testes + atualização do ledger.

## Fluxo mínimo de handoff

```
Escopo -> <numero-sequencial>-<nome-descritivo>.md -> Execução -> Testes -> Harvest
```

## Regras

1. Toda execução deve ter `docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md`.
2. Mudança estrutural em `global/` deve ser explícita e justificada.
3. Conflitos de decisão são escalados ao humano.
4. Ao finalizar, marcar task como `DONE`.
5. Selecao de skills deve respeitar `docs/governance/skills-policy.md` (allowlist/trial/limites por projeto).