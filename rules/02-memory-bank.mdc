---
description: "Define estrutura e uso prático do Memory Bank como fonte de verdade operacional."
globs: 
alwaysApply: true
---

# MEMORY BANK V2.0 - API de Estado

O diretorio `docs/memory/` e a **fonte de verdade operacional**.

## Estrutura

```
docs/memory/
  global/                    # Base estável (muda com justificativa explícita)
    project-brief.md         # Escopo, objetivos, limites do projeto
    product-context.md       # Por que o projeto existe, problemas que resolve, UX goals
    system-patterns.md       # Stack, arquitetura, padroes de design, dependencias
    tech-context.md          # Setup de dev, constraints tecnicos, infra
    decision-log.md          # Registro de decisoes arquiteturais com PORQUE
  ledger/                    # Estado corrente (atualizado a cada task)
    roadmap.md               # Backlog priorizado e milestones
    progress.md              # Status atual: o que funciona, o que falta, issues conhecidos
  active_tasks/              # Execucao das tasks
    <numero-sequencial>-<nome-descritivo>.md
```

## Regras de Acesso (pragmáticas)

| Camada | Quem escreve | Quando muda |
|---|---|---|
| `global/` | Humano ou agente com aprovacao explícita | Mudancas de escopo/arquitetura |
| `ledger/` | Agente executor | A cada ciclo de entrega |
| `active_tasks/` | Agente executor | Criado no PLAN e atualizado ate DONE |

## Regras de Leitura (SYNC)

No inicio de CADA sessao ou task, ler na seguinte ordem:

1. `global/project-brief.md` (escopo)
2. `global/product-context.md` (contexto de produto)
3. `global/system-patterns.md` (como construir)
4. `global/tech-context.md` (constraints)
5. `global/decision-log.md` (decisões anteriores)
6. `ledger/roadmap.md` (direção)
7. `ledger/progress.md` (onde estamos)
8. `active_tasks/` (o que esta em andamento)

Se algum arquivo nao existir, criar apenas se fizer parte do fluxo da task atual.

## Template: active_tasks/<numero-sequencial>-<nome-descritivo>.md

```markdown
# <numero-sequencial>-<nome-descritivo>

## Objetivo
[O que deve ser feito]

## Inputs
- [Arquivos/dados de entrada]

## Outputs Esperados
- [Arquivos/artefatos que devem ser gerados]

## Criterio de Aceite
- [ ] [Criterio 1]
- [ ] [Criterio 2]

## Status: [PLANNING | IN_PROGRESS | REVIEW | DONE]
```