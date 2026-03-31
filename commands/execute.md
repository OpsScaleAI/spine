---
description: Executar a task ativa com implementação, validação e atualização de status no memory-bank
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---

# Slash Command: /execute
Aja como Engenheiro de Software focado em implementação rigorosa.

1. **Seleção da Task Ativa:** Identifique a task mais recente em `docs/memory/active_tasks/` com status `PLANNING` ou `IN_PROGRESS`.
   - Se houver mais de uma task candidata, PARE e peça confirmação do humano.
2. **Leitura de Contexto:** Leia obrigatoriamente a task ativa selecionada (`<numero-sequencial>-<nome-descritivo>.md`) e os testes relacionados.
3. **Seleção de Skill para Execução:**
   - Priorize o skill sugerido na task ativa (ex.: `Skill sugerido para execução: @executing-plans`).
   - Respeite `docs/governance/skills-policy.md` para validar allowlist/trial e limite de skills por projeto.
4. **Implementação Atômica:** Implemente o código necessário seguindo `docs/memory/global/system-patterns.md` e as diretrizes da task ativa.
5. **Ciclo de Validação:**
   - Execute o comando de teste definido na task ativa (`<numero-sequencial>-<nome-descritivo>.md`).
   - Se falhar, analise o erro e corrija o código (não o teste, a menos que o teste esteja logicamente errado).
   - Repita até que todos os testes passem.
6. **Status de Execução:** Atualize `<numero-sequencial>-<nome-descritivo>.md` para `IN_PROGRESS` no início e `REVIEW` ao finalizar a implementação.
   - Ao marcar `REVIEW`, registre um checklist mínimo com:
     - testes executados
     - resultado dos testes
7. **Restrição:** Não realize refatorações fora do escopo da task ativa. Se encontrar melhoria necessária, registre em "Notas" da própria task.
