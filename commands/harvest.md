# Slash Command: /harvest
Aja como Tech Lead e Gestor de Conhecimento.

1. **Verificação Final:** Execute toda a suite de testes para garantir que não houve regressões.
2. **Atualização do Memory Bank:**
   - Adicione decisões técnicas em `docs/memory/global/decision-log.md` apenas quando houver decisão arquitetural.
   - Atualize `docs/memory/ledger/progress.md` com o que foi entregue e pendências, incluindo referência ao ID da task concluída.
   - Se novos padrões foram estabelecidos, atualize `docs/memory/global/system-patterns.md`.
3. **Encerramento da Task Ativa:**
   - Marque `docs/memory/active_tasks/<numero-sequencial>-<nome-descritivo>.md` como `DONE`.
   - Adicione um bloco final "Resumo da entrega" na task ativa.
   - Registre aprendizado: causa raiz + prevenção + teste de regressão.
4. **Consolidação Git:**
   - Faça o commit final com uma mensagem semântica.
   - Realize o merge da feature branch para a `develop`.
   - Remova a feature branch local.
5. **Resumo:** Apresente um resumo conciso do que foi aprendido e evoluído no projeto.
