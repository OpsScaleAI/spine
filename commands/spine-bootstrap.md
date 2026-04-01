---
description: Assessment inicial e bootstrap do memory-bank; $ARGUMENTS opcional para briefing do projeto
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---

# Slash Command: /spine-bootstrap
Aja como Arquiteto de Setup Inicial do projeto.

Objetivo: executar assessment inicial e alimentar o Memory Bank com baseline confiável.

**Contexto opcional (`$ARGUMENTS`):** O usuário pode passar texto livre após o comando (o Cursor injeta em `$ARGUMENTS`). Se **houver** conteúdo não vazio, trate como briefing do projeto: domínio, stack, restrições, stakeholders, links, dúvidas. Incorpore isso no assessment (etapa 1) e ao preencher `project-brief.md`, `product-context.md`, `system-patterns.md` e `tech-context.md`, sem contradizer fatos já presentes nos arquivos. Se **`$ARGUMENTS` estiver ausente ou vazio**, ignore esta linha e baseie-se só no que for inferido do repositório e no seed da etapa 0.

**Regra geral:** Ausência de `docs/` ou de `docs/memory` no projeto invocado **não é erro** — é a condição esperada deste comando. Não pare com “bloqueio por contexto ausente”; execute primeiro a etapa 0.

---

## 0. Seed automático (template + cópia recursiva)

Antes de qualquer leitura do Memory Bank no projeto alvo, resolva a origem do template e, se necessário, materialize `docs/` na raiz do projeto onde o comando foi invocado.

### 0.1 Resolver o caminho do template (symlink-aware)

- O arquivo deste comando vive em `.../<repo-spine>/commands/spine-bootstrap.md` (ou um **link simbólico** que aponta para ele).
- Resolva o caminho **absoluto e canônico** deste arquivo, **seguindo symlinks** (ex.: `realpath`, `readlink -f`, ou equivalente no ambiente).
- O repositório fonte do Spine é o diretório **pai** de `commands/`:  
  `SPINE_REPO_ROOT = dirname(dirname(<caminho-resolvido-de-spine-bootstrap.md>))`
- O diretório template de documentação é:  
  `TEMPLATE_DOCS = SPINE_REPO_ROOT/docs`  
  (ou seja, `docs/` na raiz do repositório Spine, **não** assuma que esse conteúdo já exista no projeto alvo.)

### 0.2 Projeto alvo

- Considere a **raiz do workspace / repositório** onde o usuário executou o comando como `PROJECT_ROOT`.
- O destino do seed é: `PROJECT_ROOT/docs`.

### 0.3 Quando copiar

- Se **`PROJECT_ROOT/docs` não existir** (ou estiver vazio de propósito de primeiro bootstrap — trate “não existe” como ausência do diretório ou diretório inexistente):
  - Copie **recursivamente todo** o conteúdo do template: todo arquivo e subdiretório sob `TEMPLATE_DOCS` deve existir espelhado em `PROJECT_ROOT/docs`.
  - Use cópia recursiva no shell, por exemplo:  
    `cp -R "$TEMPLATE_DOCS/." "$PROJECT_ROOT/docs/"`  
    (crie `PROJECT_ROOT/docs` antes se necessário; preserve estrutura e arquivos como `.gitkeep`.)
- Se **`PROJECT_ROOT/docs` já existir** com conteúdo:
  - **Não** apague nem sobrescreva o tree inteiro por padrão.
  - Passe direto para o assessment e enriquecimento incremental (etapas seguintes): complete o que faltar sem destruir contexto válido já documentado.

### 0.4 Idempotência

- Primeira execução sem `docs/`: seed completo via cópia recursiva.
- Execuções seguintes com `docs/` presente: apenas atualização incremental e preenchimento de lacunas.

---

## 1. Assessment inicial (Projeto)

- Se `$ARGUMENTS` tiver conteúdo, integre-o aqui como fonte prioritária junto ao código e configs do repo.
- Identifique stack principal (linguagens, frameworks, banco, infra).
- Identifique objetivo do projeto, escopo e limites.
- Identifique riscos técnicos iniciais e prioridades de curto prazo.

---

## 2. Bootstrap do Memory Bank (global)

- Verifique os arquivos existentes antes de alterar.
- Complete campos faltantes sem sobrescrever contexto válido já documentado.
- Preencha/normalize quando necessário:
  - `docs/memory/global/project-brief.md`
  - `docs/memory/global/product-context.md`
  - `docs/memory/global/system-patterns.md`
  - `docs/memory/global/tech-context.md`
- Registre decisões iniciais em:
  - `docs/memory/global/decision-log.md`

---

## 3. Bootstrap do Memory Bank (ledger)

- Inicialize/atualize sem apagar histórico útil:
  - `docs/memory/ledger/roadmap.md`
  - `docs/memory/ledger/progress.md`

---

## 4. Task inicial (quando houver escopo de entrega)

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
- Se a task inicial envolver UI/E2E, já registrar diretriz Playwright baseada em simplicidade:
  - default `playwright-cli` para exploração/validação rápida;
  - escalar para `playwright-skill` apenas com complexidade real (fluxo multi-etapas, validações múltiplas, reexecução frequente).

---

## 5. Resumo obrigatório

Inclua sempre:

- **Seed:** O que foi copiado na etapa 0 (árvore `docs/` vinda do template), se aplicável.
- **Criado vs. atualizado:** O que foi criado nesta execução vs. o que foi apenas atualizado no assessment.
- **Preservado:** O que permaneceu intocado por já estar válido.
- **Gaps:** Informações que ainda dependem do humano.

---

## Critérios de aceite (comportamento do comando)

- [ ] Com `PROJECT_ROOT/docs` ausente, o fluxo não bloqueia: executa seed recursivo a partir de `SPINE_REPO_ROOT/docs` resolvido via caminho real de `commands/spine-bootstrap.md`.
- [ ] Com `commands/` como link simbólico, o template ainda é encontrado (resolução symlink-aware do arquivo do comando).
- [ ] Com `docs/` já presente no projeto alvo, não há cópia destrutiva em massa; apenas enriquecimento incremental nas etapas 2–3.
- [ ] Após o bootstrap, existem os caminhos necessários para os comandos `plan`, `execute` e `harvest` (estrutura sob `docs/memory/` conforme baseline copiado ou já existente).
- [ ] O resumo final distingue claramente seed inicial de enriquecimento.
