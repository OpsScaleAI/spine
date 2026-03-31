---
description: Planejar task, criar artefato em memory-bank e preparar estratégia de testes
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---
Aja como Arquiteto de Software Senior. Siga as instruções passadas em $ARGUMENTS.

1. **Sync do Contexto:** Leia obrigatoriamente:
   - `docs/memory/global/project-brief.md`
   - `docs/memory/global/product-context.md`
   - `docs/memory/global/system-patterns.md`
   - `docs/memory/global/tech-context.md`
   - `docs/memory/global/decision-log.md`
   - `docs/memory/ledger/roadmap.md`
   - `docs/memory/ledger/progress.md`
2. **Git Flow:** Crie branch `feature/<nome-descritivo>` a partir de `develop`.
3. **Skill Recomendado (obrigatório para qualidade do plano):**
   - Use o skill `@writing-plans` para estruturar o plano em tarefas pequenas, testáveis e executáveis.
   - Selecione skills adicionais respeitando `docs/governance/skills-policy.md` (allowlist/trial/limite por projeto).
   - Se houver conflito entre skill e comando, **este comando prevalece** para manter o workflow do projeto.
4. **Plano da Task no Memory Bank:**
   - Garanta a pasta `docs/memory/active_tasks/`.
   - Use o mesmo `<nome-descritivo>` da branch e crie:
     - `docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md`
   - Exemplo:
     - branch: `feature/ajuste-login-social`
     - task: `docs/memory/active_tasks/007-ajuste-login-social.md`
   - Crie o arquivo da task com:
     - Status inicial: `PLANNING`
     - Objetivo
     - Inputs
     - Outputs esperados (artefatos e diretórios de destino)
     - Critérios de aceite (checklist)
     - Estratégia de teste (positivo, negativo, regressão)
   - Inclua no topo da task a linha:
     - `Skill sugerido para execução: @executing-plans`
5. **Estratégia de Testes:** Defina quais testes serão criados/atualizados em `tests/` e o comando de execução.
6. **Portão de Aprovação:** Pare e peça confirmação:
   - "Plano criado em docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md. Posso executar?"
