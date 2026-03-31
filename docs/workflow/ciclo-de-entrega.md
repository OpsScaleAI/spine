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
5. **Registro**
   - Atualizar `docs/memory/ledger/progress.md`.
   - Registrar decisões em `docs/memory/global/decision-log.md`.
   - Registrar lição aprendida (erro evitável + prevenção).
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
