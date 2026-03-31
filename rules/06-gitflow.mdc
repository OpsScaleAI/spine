---
description: "Referência do GitFlow customizada para o fluxo de trabalho do projeto. Invocado para garantir conformidade com a estratégia de branching e merge."
globs: "**/*"
alwaysApply: false
---

# GitFlow - Referência Customizada

## Estrutura de Branches

| Branch | Propósito | Origem | Merge para |
|---|---|---|---|
| `production` | Código em ambiente de produção (Live) | `staging` | - |
| `main` | Branch canônica; espelho estável da `production` | `production` | - |
| `staging` | Consolidação da `develop` e ambiente de QA | `develop` | `production` |
| `develop` | Ponto de partida para toda nova implementação | `main` / `production` | `staging` |
| `feature/*` | Desenvolvimento de novas funcionalidades | `develop` | `develop` |
| `hotfix/*` | Correções urgentes | `production` (ou `main`) | `production`, `main`, `develop` |

## Regras de Ouro

1. **Início de Tarefa**: Toda alteração de código começa obrigatoriamente com:
   `git checkout develop && git pull && git checkout -b feature/<nome-descritivo>`
2. **Commits Atômicos**: Cada commit deve representar uma única mudança lógica completa e testável.
3. **Proibição de Push Direto**: Nunca realizar push diretamente para as branches `production`, `main`, `staging` ou `develop`.
4. **Integridade do Histórico**: É estritamente proibido o uso de `git push --force`.
5. **Revisão Obrigatória**: Todo merge para a branch `develop` exige a abertura de um Pull Request (PR).
6. **Estratégia de Merge**: O *Squash merge* é permitido apenas mediante autorização expressa do humano responsável.
7. **Sincronização de Memória**: Sempre que o merge da branch `develop` for realizado para a branch `staging`, a memória do projeto (documentação de estado, ledger e active tasks) deve ser obrigatoriamente atualizada para refletir o novo status do sistema.

## Nomenclatura de Branches

- **Features**: `feature/<nome-descritivo>` (ex: `feature/validacao-de-cpf`)
- **Hotfixes**: `hotfix/<nome-descritivo>` (ex: `hotfix/ajuste-login-social`)
- **Releases**: `release/vX.Y.Z` (quando aplicável para congelamento de versão em staging)

## Observações Técnicas
- A branch `main` deve ser mantida sincronizada com a `production` como referência canônica.
- O fluxo de promoção de código segue a hierarquia: `feature` -> `develop` -> `staging` -> `production` -> `main`.
