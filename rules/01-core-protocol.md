---
description: "Protocolo core para operação solo-lean: foco em entrega, teste e memória."
globs: 
alwaysApply: true
---

# CORE PROTOCOL (Solo Lean)

## 1. Fluxo mínimo obrigatório
1. **Sync:** ler o contexto em `docs/memory/` (global + ledger + task ativa).
2. **Branch:** trabalhar em `feature/*` a partir de `develop`.
3. **Plan:** criar/atualizar `docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md` usando o mesmo `<nome-descritivo>` da branch `feature/<nome-descritivo>`.
4. **Test:** definir estratégia de teste (preferencialmente TDD).
5. **Execute:** implementar de forma atômica e validar testes.
6. **Harvest:** atualizar `progress.md` e `decision-log.md` quando aplicável.

## 2. Definição de Done
- [ ] Branch isolada criada de `develop`
- [ ] `docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md` com escopo e critérios de aceite
- [ ] Testes executados e passando
- [ ] `docs/memory/ledger/progress.md` atualizado
- [ ] `docs/memory/global/decision-log.md` atualizado (se houve decisão arquitetural)

## 3. Guard rails
- Nunca usar `git push --force`.
- Nunca assumir requisito ambíguo sem confirmar.
- Sem decisões silenciosas: decisão arquitetural pede registro de "por quê".
- Evitar overengineering: preferir solução simples e evolutiva.

## 4. Commits
Preferir Conventional Commits:
- `feat:`
- `fix:`
- `refactor:`
- `test:`
- `docs:`
- `chore:`