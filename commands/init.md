# Slash Command: /init
Aja como Arquiteto de Setup Inicial do projeto.

Objetivo: executar assessment inicial e alimentar o Memory Bank com baseline confiável.

1. **Assessment Inicial (Projeto):**
   - Identifique stack principal (linguagens, frameworks, banco, infra).
   - Identifique objetivo do projeto, escopo e limites.
   - Identifique riscos técnicos iniciais e prioridades de curto prazo.

2. **Bootstrap do Memory Bank (global):**
   - Verifique os arquivos existentes antes de alterar.
   - Complete campos faltantes sem sobrescrever contexto válido já documentado.
   - Preencha/normalize quando necessário:
     - `docs/memory/global/project-brief.md`
     - `docs/memory/global/product-context.md`
     - `docs/memory/global/system-patterns.md`
     - `docs/memory/global/tech-context.md`
   - Registre decisões iniciais em:
     - `docs/memory/global/decision-log.md`

3. **Bootstrap do Memory Bank (ledger):**
   - Inicialize/atualize sem apagar histórico útil:
     - `docs/memory/ledger/roadmap.md`
     - `docs/memory/ledger/progress.md`

4. **Task Inicial (quando houver escopo de entrega):**
   - Garanta a pasta `docs/memory/active_tasks/`.
   - Defina o mesmo `<nome-descritivo>` da branch `feature/<nome-descritivo>`.
   - Crie a task inicial no formato:
     - `docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md`
   - Exemplo:
     - branch: `feature/setup-memory-bank`
     - task: `docs/memory/active_tasks/001-setup-memory-bank.md`
   - Estruture a task com:
     - objetivo
     - inputs
     - outputs esperados
     - critérios de aceite
     - estratégia de testes
     - status `PLANNING`

5. **Resumo obrigatório:**
   - Liste o que foi criado vs. o que foi apenas atualizado.
   - Liste o que foi preservado por já estar válido.
   - Liste gaps de informação que ainda dependem do humano.
