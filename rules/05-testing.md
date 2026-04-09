---
description: "Padroes de testes. TDD obrigatorio. Aplica-se a todos os arquivos de teste."
globs: "tests/**/*.py"
alwaysApply: false
---

# Padroes de Testes (TDD)

## Filosofia

- **Red, Green, Refactor**: preferencialmente escrever o teste ANTES da implementacao
- Testes sao documentacao executavel do comportamento esperado
- Se nao tem teste, nao esta pronto

## Estrutura

```
tests/
  unit/           # Testes isolados, sem I/O externo
  integration/    # Testes com banco, APIs externas (mockadas ou reais)
  conftest.py     # Fixtures compartilhadas
```

## Regras

- Cada funcao publica deve ter pelo menos 1 teste de sucesso e 1 teste de falha
- Nomes descritivos: `test_create_task_returns_201_with_valid_data()`
- Usar fixtures do pytest para setup/teardown
- Mocks apenas quando necessario (preferir testes de integracao com banco de teste)
- Assertions claras: 1 assert por teste quando possivel
- Testes devem buscar execucao rapida (unitarios preferencialmente em segundos; integracao sob controle)
- Excecao pragmatica: em hotfix critico, pode implementar primeiro e criar teste de regressao imediatamente apos estabilizar