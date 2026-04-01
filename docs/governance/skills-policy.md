# Skills Policy (Allowlist Mínima)

## Objetivo
Reduzir complexidade operacional e manter somente skills com valor recorrente no seu workflow.

## Modelo de Curadoria
- **Allowlist ativa**: skills liberadas para uso padrão.
- **Trial**: skills novas testadas por 2 ciclos.
- **Bloqueadas por padrão**: todas as demais skills fora da allowlist.
- **Limite por projeto**: manter entre 5 e 8 skills ativas para reduzir ruído.

## Critérios de Entrada na Allowlist
- Uso recorrente no trabalho real (mínimo de 2 usos úteis em 30 dias).
- Redução mensurável de retrabalho, risco ou tempo.
- Alinhamento com stack principal do projeto.

## Critérios de Remoção
- Sem uso recorrente nos últimos 30 dias.
- Gera ruído, ambiguidade ou sobreposição com skill já ativa.
- Induz overengineering para tarefas simples.

## Níveis de Ativação

### Core obrigatório
- `writing-plans`
- `executing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`

### Trial (entrada)
- Skill nova entra como `Trial` por 2 ciclos.
- Promoção para allowlist exige:
  - 2 ou mais usos úteis em 30 dias
  - ganho claro em tempo/qualidade
  - ausência de conflito com skills já ativas

## Perfis por Stack

### Perfil cloudflare-api
- Core obrigatório
- `cloudflare-workers-expert`
- `bash-defensive-patterns` (quando houver scripts de deploy/ops)

### Perfil cloudflare-astro
- Core obrigatório
- `cloudflare-workers-expert`
- `astro`
- `playwright-skill` (quando houver fluxo UI/E2E)

### Perfil backend-py-php
- Core obrigatório
- `python-patterns` e/ou `php-pro`
- `postgresql`, `postgres-best-practices`, `sql-pro` (quando houver banco)
- `linux-troubleshooting` (quando houver operação local/servidor)

## Allowlist Base Recomendada

### Backend Python/PHP
- `python-patterns`
- `fastapi-pro`
- `django-pro`
- `php-pro`

### Banco e Dados
- `postgresql`
- `postgres-best-practices`
- `sql-pro`

### Infra e Operação
- `terraform-infrastructure`
- `bash-defensive-patterns`
- `linux-troubleshooting`

### Frontend Assistido (principal)
- `frontend-dev-guidelines`
- `astro` (quando Astro no projeto)
- `playwright-skill` (quando UI/E2E)

### Frontend (opcional, quando React/Next)
- `react-best-practices`

### Cloudflare
- `cloudflare-workers-expert`

## Diretriz Operacional: Playwright

Use esta regra curta para evitar ambiguidade e overengineering:

- **Default simples:** comece com `playwright-cli`.
- **Escalar apenas quando necessário:** use `playwright-skill` somente quando a tarefa exigir script custom, fluxo multi-etapas (E2E), validações múltiplas ou reexecução frequente.

### Quando usar `playwright-cli`
- Exploração rápida de UI.
- Debug pontual de interação/estado.
- Ações curtas e iterativas (abrir, clicar, snapshot, validar elemento).

### Quando usar `playwright-skill`
- Fluxo E2E completo (ex.: login -> navegação -> validações).
- Cenários repetíveis que se beneficiam de script em `/tmp`.
- Casos com controle mais robusto (tratamento de erro, múltiplas etapas e artefatos).

### Regra de desempate (anti-overengineering)
- Se a tarefa puder ser resolvida em poucos comandos interativos, mantenha `playwright-cli`.
- Migre para `playwright-skill` apenas ao encontrar complexidade real durante a execução.

## Processo Mensal de Revisão
1. Listar skills efetivamente usadas no mês (frequência e contexto).
   - Para Playwright, usar os registros do `/harvest` (skill escolhida, motivo e evidência de ganho).
2. Confirmar quais skills reduziram tempo/retrabalho.
3. Remover as não recorrentes ou redundantes.
4. Promover/demover Trial conforme critérios objetivos.
5. Atualizar este documento.
