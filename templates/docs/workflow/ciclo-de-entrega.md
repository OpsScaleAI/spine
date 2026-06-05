# Ciclo de Entrega (Enxuto)

## Objetivo
Executar tarefas com previsibilidade e qualidade, mantendo documentação mínima e útil.

## Ciclo Padrão
1. **Intake da tarefa**
   - Definir objetivo, escopo e critério de aceite.
2. **Plano rápido**
   - Definir abordagem em poucas linhas.
   - Definir plano de testes (positivo, negativo, regressão).
3. **Execução em `feature/*`**
   - Implementar o mínimo necessário para entregar valor.
4. **Validação**
   - Executar testes definidos.
   - Validar impacto em áreas relacionadas.
5. **Registro (harvest v2.1)**
   - Atualizar `docs/memory/ledger/progress.md` (Current state + entrada no delivery log com **Tags**).
   - Registrar recorrências em `docs/memory/ledger/learnings.md` quando houver incidente ou retrabalho.
   - Registrar decisões em `docs/memory/global/decision-log.md`.
   - Mover task concluída: `git mv active_tasks/ → completed_tasks/` (frontmatter `status: DONE`).
6. **Promoção**
   - `feature/*` -> `develop` -> `staging` -> `production` -> `main`.

## Definição de Pronto
- Critério de aceite atendido.
- Testes previstos executados.
- Memory-bank atualizado.
- Sem pendência crítica não documentada.

## Guard Rail Anti-Overengineering
- Não criar abstração nova sem 2 casos reais.
- Não adicionar ferramenta nova sem substituir algo ou reduzir custo/tempo.
- Priorizar solução simples antes de solução “genérica”.
