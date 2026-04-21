# Fix `quote_item.QUOTE_ITEM_UNIQUE_ITEM_HASH` Collision (B2B + B2C)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Status:** IN_PROGRESS — execução iniciada em 2026-04-20 via `/spine-execute`.
**Branch:** `hotfix/quote-item-unique-hash-collision` (criada a partir de `origin/production`, tip `bef7c521`).
**Autor do plano:** agente Cursor (modo Agent) em 2026-04-20.
**Suggested execution skill:** `@executing-plans`

**Goal:** Eliminar colisões espúrias do índice único `quote_item.QUOTE_ITEM_UNIQUE_ITEM_HASH` que estão bloqueando clientes B2B no `AddToCart` e no `placeOrder` desde 2026-04-20, preservando a intenção original (impedir duplicação real de itens em uma mesma quote) sem introduzir falso-positivos.

**Architecture:** Remover a fonte do problema (plugin `Jn2\OrganizaTextil\Plugin\SetQuoteItemUniqueHash` + coluna/constraint `unique_item_hash` em `quote_item`) e, em paralelo, investigar a presença de uma constraint-zumbi legada (`QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID`) que está no `db_schema_whitelist.json` mas não no `db_schema.xml`. O Magento core já garante uma-linha-por-(quote_id, product_id, options) em `Quote::addProduct()` via `getItemByProduct()`, tornando o hash custom redundante. O caminho de mitigação acontece em três ondas:
1. **Hotfix imediato** (DBA/SSH, mesmo dia): dropar o índice único em produção para desbloquear clientes — sem deploy de código.
2. **Correção de código definitiva** (branch `hotfix/quote-item-unique-hash-collision`, D+1/D+2): remover plugin, constraint do `db_schema.xml` e whitelist em duas migrações (a mais recente primeiro, composta depois, com um script de confirmação).
3. **Hardening do AddToCart customizado** (`Jn2_WholesaleShoppingTable`): consolidar o WIP já existente no working tree, corrigir o bug do `dedupeProductsBySku` (descarta qty divergente silenciosamente) e trocar log genérico por mensagens úteis.

**Tech Stack:** Magento 2.4.6, PHP 8.2, MySQL/MariaDB, Magento Declarative Schema, PHPUnit 9.6, Docker `php:8.2-cli`, Git (git-flow com hotfix branch a partir de `main`).

**Hipóteses (a validar nas primeiras tasks):**
- **H1:** o hash atual (`md5(quote_id.product_id.sku.store_id.parent_item_id)`) colide em fluxos legítimos porque não inclui `qty`, `options`, `buy_request`. Evidência coletada hoje: clientes 2027, 13505, 492, 12807, 8322 falharam tentando adicionar SKUs distintos da mesma referência (tamanhos diferentes não formam parent_item_id diferente em simples; em configuráveis, o parent_item vem depois do filho e cria janela de race).
- **H2:** `Quote\Relation::processRelation` pode chamar `beforeSave` em items com `quote_id=null` ou com dados parciais, gerando hash que colide com o item já persistido quando o `quote_id` é injetado depois. Reproduzível em save que intercala create+update na mesma transação.
- **H3:** ainda existe no banco o índice legado `QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID` (confirmar via `SHOW INDEXES FROM quote_item`) que não foi removido quando `a3de5055` substituiu a abordagem. Se sim, é **outro** ponto de colisão independente do hash.
- **H4:** no `AddToCart` customizado do `Jn2_WholesaleShoppingTable`, a mesma request processa o array `$params['products']` com `addProduct + save` em loop. A iteração anterior sujava o estado em memória, fazendo `isProductAlreadyOnCart($cartItems, ...)` retornar `false` para um SKU que já foi gravado — segundo `addProduct` entrava, batia no hash. O WIP local tenta corrigir isso relendo `$freshItems` a cada iteração.

**Out of scope:**
- Corrigir a ausência de evento `quote_finalized` B2B em `var/log/quote_lifecycle.log` (follow-up separado da 002).
- Observabilidade adicional do `QuoteLifecycleLogger` (já coberto pela 002).
- Refatoração do controller `RemoveFromCart` (`Jn2_WholesaleShoppingTable`) — só tocar se houver código compartilhado.
- Testes E2E Playwright no staging (cliente explicitou em tasks anteriores que pode ir direto de `hotfix` → produção; registrar risco).

**Rollback:** a Task 1 (hotfix SQL direto em produção) é reversível via re-criação do índice com `ALTER TABLE quote_item ADD UNIQUE KEY QUOTE_ITEM_UNIQUE_ITEM_HASH (unique_item_hash)`; a Task 6 (remoção do plugin/schema) é reversível via `git revert` do PR de hotfix. Cada task tem `rollback` explícito nos steps.

**Branch e git-flow:**
- Criar `hotfix/quote-item-unique-hash-collision` **a partir de `origin/production`** (tip deployado, `bef7c521` — não de `feature/prevent-quote-id-reuse-b2b`, que é a 002 já mergeada, nem de `master` que inclui ressync posterior).
- Entregar por PR direto para `production` (com merge reverso para `master`, `develop` e `staging` conforme gitflow padrão), seguindo o precedente já registrado no `decision-log.md` para casos com rollback de 5 min.

---

## Pré-requisitos de ambiente (executar uma vez antes de qualquer task)

**Step P.1: Confirmar branch atual e mover mudanças em curso**

Contexto: hoje o working tree tem `AddToCart.php` modificado e dois arquivos de documentação (002 e decision-log) já editados nesta sessão. O branch é `feature/prevent-quote-id-reuse-b2b` (task 002). **Essas mudanças não podem vazar para um hotfix de 003.**

```bash
cd /home/juste/Workspace/php/magento/lojas/libidus/magento
git status
```

Esperado (entre outros) :
```
On branch feature/prevent-quote-id-reuse-b2b
Changes not staged for commit:
  modified:   app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php
  modified:   docs/memory/active_tasks/002-prevent-quote-id-reuse-b2b.md
  modified:   docs/memory/global/decision-log.md
```

**Step P.2: Decidir o destino das edições já feitas**

Pergunta de negócio antes de mais nada:
1. As edições em `002-prevent-quote-id-reuse-b2b.md` e `decision-log.md` (fechamento da 002 + baseline D0) são da 002 e devem ser commitadas em `feature/prevent-quote-id-reuse-b2b` e mergeadas na sequência — **não são** da 003.
2. A edição em `AddToCart.php` (dedupe + freshItems) é da 003 — precisa ser movida para a branch de hotfix antes de commitar.

Executar:

```bash
git stash push -m "wip-003-add-to-cart" -- app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php
git status
```

Esperado: `AddToCart.php` some de "not staged", documentação continua listada.

```bash
git add docs/memory/active_tasks/002-prevent-quote-id-reuse-b2b.md docs/memory/global/decision-log.md
git commit -m "docs(memory): task 002 D0 baseline + decision log entry

- Registra baseline pós-deploy 2026-04-20: 8 pedidos B2B, zero reuso de quote_id.
- Documenta separação de escopo entre 002 (quote_id reuse) e 003 (unique_item_hash).
- Anota gates D+1/D+3/D+7 para quote-reuse-monitor.sql.
- Registra lacuna de observabilidade B2B (sem evento quote_finalized) como follow-up."
```

**Step P.3: Criar branch de hotfix a partir de `production`**

```bash
git fetch origin production
git checkout -b hotfix/quote-item-unique-hash-collision origin/production
git log -1 --oneline
```

Esperado: `bef7c521 Merge branch 'feature/prevent-quote-id-reuse-b2b' into develop` (tip deployado). O repo usa `master` para "sincronizar após release" (não como fonte de hotfix) e `production` como branch do deploy atual.

**Step P.4: Re-aplicar o WIP do AddToCart na nova branch**

```bash
git stash pop
git status
```

Esperado: `modified: app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php` aparece novamente, agora sobre a base da `main`.

**Step P.5: Abrir o plano como referência viva**

O arquivo `.spine/templates/docs/memory/active_tasks/003-fix-quote-item-unique-hash-collision.md` (este arquivo) precisa ser commitado cedo na hotfix branch para que a pessoa executando possa ticar progresso.

```bash
git add .spine/templates/docs/memory/active_tasks/003-fix-quote-item-unique-hash-collision.md
git commit -m "docs(memory): task 003 plan — fix quote_item unique_item_hash collision

Plano detalhado para remover índice único QUOTE_ITEM_UNIQUE_ITEM_HASH,
neutralizar plugin SetQuoteItemUniqueHash e consolidar hardening do
AddToCart customizado do Jn2_WholesaleShoppingTable."
```

---

## Track A — Desbloqueio imediato (mesmo dia, sem deploy de código)

### Task 1: Investigar estado real dos índices em `quote_item` (produção)

**Files:** nenhum arquivo de código. Saída vai para `.spine/templates/docs/memory/active_tasks/003-evidence/` (criar ao longo do caminho).

**Step 1.1: Criar pasta de evidência**

```bash
mkdir -p .spine/templates/docs/memory/active_tasks/003-evidence
```

**Step 1.2: Rodar inspeção de índices (read-only) em produção**

Seguir `.cursor/rules/remote-production-readonly-assessment.mdc`. Usar o perfil read-only do MySQL (ex.: `--defaults-group-suffix=-assesment`) **ou** `ssh libidus.api "cd scripts; sh consulta.sh ..."`.

Query a rodar:

```sql
SHOW INDEXES FROM quote_item WHERE Non_unique = 0;
SELECT COUNT(*) AS total,
       COUNT(DISTINCT unique_item_hash) AS distinct_hash,
       SUM(unique_item_hash IS NULL) AS null_hash
FROM quote_item;
SELECT unique_item_hash, COUNT(*) AS hits
FROM quote_item
WHERE unique_item_hash IS NOT NULL
GROUP BY unique_item_hash
HAVING hits > 1
ORDER BY hits DESC LIMIT 10;
```

**Step 1.3: Salvar resultado**

Salvar saída em `.spine/templates/docs/memory/active_tasks/003-evidence/01-indexes-baseline.md` com timestamp BRT e identificação do host. Esperado que liste **ao menos** `PRIMARY` e `QUOTE_ITEM_UNIQUE_ITEM_HASH`; registrar se `QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID` ainda existe (H3).

**Step 1.4: Commit da evidência**

```bash
git add .spine/templates/docs/memory/active_tasks/003-evidence/01-indexes-baseline.md
git commit -m "docs(003): evidência baseline de índices em quote_item (prod)"
```

---

### Task 2: Hotfix SQL direto — dropar índice único em produção

**Files:** `.spine/templates/docs/memory/active_tasks/003-evidence/02-hotfix-sql.md` (registrar comando executado e resultado).

> **Ação humana requerida.** O agente **não** executa DDL em produção. O agente entrega o comando e a justificativa; o DBA/devops responsável executa. Ver `.cursor/rules/remote-production-readonly-assessment.mdc` e regra de `decision-log.md` 2026-04-17 sobre INSERT/UPDATE/DELETE/DDL proibidos ao agente.

**Step 2.1: Preparar script de hotfix e rollback**

Criar `.spine/templates/docs/memory/active_tasks/003-evidence/02-hotfix-sql.md` com:

```sql
-- Hotfix 2026-04-20 — desbloquear checkout B2B
-- Autor: <devops>  Aprovador: <cliente>

-- Pré-checagem (read-only):
SHOW INDEXES FROM quote_item WHERE Key_name IN (
  'QUOTE_ITEM_UNIQUE_ITEM_HASH',
  'QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID'
);

-- Hotfix:
ALTER TABLE quote_item DROP INDEX QUOTE_ITEM_UNIQUE_ITEM_HASH;
-- Se a Task 1 confirmou que o índice legado ainda existe:
-- ALTER TABLE quote_item DROP INDEX QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID;

-- Rollback (somente se necessário antes do deploy definitivo):
-- ALTER TABLE quote_item ADD UNIQUE KEY QUOTE_ITEM_UNIQUE_ITEM_HASH (unique_item_hash);
```

**Step 2.2: Smoke pós-hotfix (ação humana, minutos depois)**

Registrar no mesmo arquivo:
- Repetir `SHOW INDEXES` — índice some.
- Solicitar a atendimento que peça a UM cliente afetado (ex.: Joelma) para re-adicionar itens e tentar finalizar. Anexar screenshot/increment_id no log de evidência.

**Step 2.3: Commit da evidência**

```bash
git add .spine/templates/docs/memory/active_tasks/003-evidence/02-hotfix-sql.md
git commit -m "docs(003): registrar hotfix SQL DROP INDEX em produção + smoke pós"
```

---

## Track B — Correção definitiva de código

### Task 3: Preparar ambiente de teste (Docker PHP 8.2)

O mesmo setup já usado na 002. Confirmar que roda:

**Step 3.1: Smoke do container**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli php -v
```

Esperado: `PHP 8.2.x ...`.

**Step 3.2: Smoke do PHPUnit 9.6**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  /app/vendor/bin/phpunit --version
```

Esperado: `PHPUnit 9.6.x ...`. Se falhar, rodar `composer install` local antes.

---

### Task 4: Teste de regressão para a colisão (antes da correção)

Queremos gravar um teste que **comprove** a colisão antes de removê-la. Isso dá confiança de que a correção realmente resolveu o cenário real.

**Files:**
- Create: `app/code/Jn2/OrganizaTextil/Test/Unit/Plugin/SetQuoteItemUniqueHashTest.php`

**Step 4.1: Escrever o teste que expõe a colisão**

```php
<?php
declare(strict_types=1);

namespace Jn2\OrganizaTextil\Test\Unit\Plugin;

use Jn2\OrganizaTextil\Plugin\SetQuoteItemUniqueHash;
use Magento\Quote\Model\Quote;
use Magento\Quote\Model\Quote\Item;
use PHPUnit\Framework\TestCase;
use Psr\Log\LoggerInterface;

/**
 * Regressão: a implementação atual do hash não inclui qty nem options,
 * de modo que dois itens logicamente distintos (mesmo SKU configurable
 * com qty diferente ou option diferente) produzem o mesmo hash e
 * colidem no índice único do DB. Este teste serve como contrato que a
 * task 003 remove o mecanismo OU corrige a fórmula.
 */
final class SetQuoteItemUniqueHashTest extends TestCase
{
    public function testHashCollidesWhenOnlyQtyDiffers(): void
    {
        $plugin = new SetQuoteItemUniqueHash($this->createMock(LoggerInterface::class));

        $itemA = $this->buildItem(quoteId: 76228, productId: 42, sku: 'REF-01-M', qty: 1);
        $itemB = $this->buildItem(quoteId: 76228, productId: 42, sku: 'REF-01-M', qty: 5);

        $plugin->afterBeforeSave($itemA);
        $plugin->afterBeforeSave($itemB);

        $this->assertSame(
            $itemA->getData('unique_item_hash'),
            $itemB->getData('unique_item_hash'),
            'Dois items com qty diferente produzem o mesmo hash — colisão espúria.'
        );
    }

    public function testHashCollidesWhenBuyRequestDiffers(): void
    {
        $plugin = new SetQuoteItemUniqueHash($this->createMock(LoggerInterface::class));

        $itemA = $this->buildItem(quoteId: 76228, productId: 42, sku: 'REF-01-M', qty: 1);
        $itemA->setData('buy_request', ['qty' => 1, 'super_attribute' => ['93' => '167']]);

        $itemB = $this->buildItem(quoteId: 76228, productId: 42, sku: 'REF-01-M', qty: 1);
        $itemB->setData('buy_request', ['qty' => 1, 'super_attribute' => ['93' => '168']]);

        $plugin->afterBeforeSave($itemA);
        $plugin->afterBeforeSave($itemB);

        $this->assertSame(
            $itemA->getData('unique_item_hash'),
            $itemB->getData('unique_item_hash'),
            'Dois items com opções de configurable diferentes produzem o mesmo hash.'
        );
    }

    private function buildItem(int $quoteId, int $productId, string $sku, int $qty): Item
    {
        $item = $this->createPartialMock(Item::class, ['getQuote']);
        $item->setData('quote_id', $quoteId);
        $item->setData('product_id', $productId);
        $item->setData('sku', $sku);
        $item->setData('store_id', 2);
        $item->setData('parent_item_id', null);
        $item->setData('qty', $qty);

        $quote = $this->createMock(Quote::class);
        $quote->method('getId')->willReturn($quoteId);
        $item->method('getQuote')->willReturn($quote);

        return $item;
    }
}
```

**Step 4.2: Rodar teste — precisa PASSAR (porque o bug está presente)**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  /app/vendor/bin/phpunit --testdox \
  app/code/Jn2/OrganizaTextil/Test/Unit/Plugin/SetQuoteItemUniqueHashTest.php
```

Esperado: 2 testes verdes. Eles **documentam** a falha — depois que removermos o plugin, eles serão deletados junto.

**Step 4.3: Commit**

```bash
git add app/code/Jn2/OrganizaTextil/Test/Unit/Plugin/SetQuoteItemUniqueHashTest.php
git commit -m "test(organizatextil): document unique_item_hash collision scenarios

Testes de regressão que provam que a fórmula atual colide em cenários
legítimos (qty diferente, super_attribute diferente). Serão removidos
junto com o plugin na task 6."
```

---

### Task 5: Decidir entre "corrigir hash" ou "remover mecanismo"

**Step 5.1: Avaliar redundância com o core**

Fato: `Magento\Quote\Model\Quote::addProduct()` já chama `getItemByProduct()` antes de criar um novo item. Se um item equivalente (mesmo produto + mesmas options) existe, o core **incrementa a qty** em vez de criar linha nova. Logo, a invariante "nunca duas linhas iguais em `quote_item`" já é garantida pelo core.

Fato 2: o plugin foi introduzido em `a3de5055` (2024-11-07) pelo autor `romulo`. O commit anterior dele (`e906499e` — "correções integração duplicada", 2024-09-10) sugere que o problema original era **duplicação na integração ERP**, não no `quote_item` em si. A escolha de atacar no `quote_item` provavelmente foi acoplamento indevido: o sintoma aparecia lá porque a duplicação vinha do `AddToCart` customizado do `Jn2_WholesaleShoppingTable`, corrigido independentemente em `7f432196`.

**Step 5.2: Decisão (a registrar no `decision-log.md`)**

**Remover** plugin + coluna + constraint. Justificativas:
- O core já garante a invariante com base em options + product_id.
- O `AddToCart` customizado (`Jn2_WholesaleShoppingTable`) está sendo corrigido no Track C (task 7) para eliminar a duplicação em memória.
- A tentativa anterior de corrigir a fórmula (Task 4 mostra que ela não tem qty nem options) seria eternamente frágil: qualquer nova opção (ex.: regalo, brinde, gift wrap) exigiria atualizar a fórmula.
- Dívida menor: manter coluna `unique_item_hash` vazia sem constraint é aceitável como transitório; removê-la em schema exige rodar `setup:db-schema:upgrade` que já acontece no deploy normal.

**Step 5.3: Registrar decisão**

Editar `docs/memory/global/decision-log.md` com entrada nova datada 2026-04-2X (dia em que a task for efetivamente executada):

```markdown
### 2026-04-2X — Remoção do `unique_item_hash` em `quote_item` (task 003)
**Contexto:** ...
**Decisão:** Remover plugin `Jn2\OrganizaTextil\Plugin\SetQuoteItemUniqueHash`, coluna `unique_item_hash` e a unique constraint associada. Invariante preservada pelo core (`Quote::addProduct` → `getItemByProduct`). Hardening do duplicate no `AddToCart` do `Jn2_WholesaleShoppingTable` (task 7) é defesa em profundidade.
**Consequências:** ...
```

**Step 5.4: Commit**

```bash
git add docs/memory/global/decision-log.md
git commit -m "docs(memory): decisão de remover unique_item_hash em quote_item (003)"
```

---

### Task 6: Remover plugin, constraint e coluna

**Files:**
- Modify: `app/code/Jn2/OrganizaTextil/etc/di.xml` (remover `<type name="Magento\Quote\Model\Quote\Item">` com o plugin)
- Modify: `app/code/Jn2/OrganizaTextil/etc/db_schema.xml` (remover `<table name="quote_item">`)
- Modify: `app/code/Jn2/OrganizaTextil/etc/db_schema_whitelist.json` (remover entrada `quote_item` inteira — campo + 2 constraints)
- Delete: `app/code/Jn2/OrganizaTextil/Plugin/SetQuoteItemUniqueHash.php`
- Delete: `app/code/Jn2/OrganizaTextil/Test/Unit/Plugin/SetQuoteItemUniqueHashTest.php`

**Step 6.1: Remover o plugin do `di.xml`**

Em `app/code/Jn2/OrganizaTextil/etc/di.xml` linhas 51-53, remover:

```xml
    <type name="Magento\Quote\Model\Quote\Item">
        <plugin name="jn2_organizatextil_unique_item_hash" type="Jn2\OrganizaTextil\Plugin\SetQuoteItemUniqueHash"/>
    </type>
```

**Step 6.2: Remover a declaração de schema**

Em `app/code/Jn2/OrganizaTextil/etc/db_schema.xml`, remover o bloco (linhas 185-190):

```xml
    <table name="quote_item" resource="checkout" engine="innodb" comment="Sales Flat Quote Item">
        <column xsi:type="varchar" name="unique_item_hash" nullable="true" length="200" comment="Unique item hash"/>
        <constraint xsi:type="unique" referenceId="QUOTE_UNIQUE_ITEM_HASH">
            <column name="unique_item_hash" />
        </constraint>
    </table>
```

**Step 6.3: Atualizar whitelist**

Em `app/code/Jn2/OrganizaTextil/etc/db_schema_whitelist.json`, remover o bloco `"quote_item": { ... }` (linhas 154-162). A entrada legada `QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID` sai junto. **Atenção:** o `setup:db-schema:upgrade` só dropa o que está no whitelist mas não no schema; por isso removemos os dois simultaneamente — o Magento vai efetivamente dropar coluna+constraints no próximo upgrade.

**Step 6.4: Deletar os arquivos do plugin e do teste**

```bash
rm app/code/Jn2/OrganizaTextil/Plugin/SetQuoteItemUniqueHash.php
rm app/code/Jn2/OrganizaTextil/Test/Unit/Plugin/SetQuoteItemUniqueHashTest.php
```

Se `Plugin/` ficou vazio, deletar também:

```bash
rmdir app/code/Jn2/OrganizaTextil/Plugin 2>/dev/null || true
```

**Step 6.5: Rodar PHPUnit global do módulo**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  /app/vendor/bin/phpunit --testdox \
  app/code/Jn2/OrganizaTextil/Test/Unit/
```

Esperado: verde (ou 0 testes no diretório se só tinha o que acabamos de deletar).

**Step 6.6: Rodar `setup:di:compile` local para pegar referências quebradas**

```bash
docker compose exec magento bin/magento setup:di:compile 2>&1 | tee /tmp/di-compile.log
grep -i "SetQuoteItemUniqueHash\|QUOTE_UNIQUE_ITEM_HASH" /tmp/di-compile.log || echo "OK: sem referências remanescentes"
```

Esperado: nenhum hit no grep. Se tiver, algo ainda chama o plugin.

**Step 6.7: Commit**

```bash
git add app/code/Jn2/OrganizaTextil/
git commit -m "refactor(organizatextil): remove unique_item_hash de quote_item

- Remove plugin Jn2\OrganizaTextil\Plugin\SetQuoteItemUniqueHash (di.xml + arquivo).
- Remove coluna unique_item_hash e constraint QUOTE_UNIQUE_ITEM_HASH de db_schema.xml.
- Limpa whitelist (remove QUOTE_ITEM_UNIQUE_ITEM_HASH e o legado
  QUOTE_ITEM_QUOTE_ID_PRODUCT_ID_SKU_STORE_ID_PARENT_ITEM_ID).
- Invariante preservada pelo core (Quote::addProduct → getItemByProduct).
- Fechamento do incidente 2026-04-20 em B2B (Marines, Joelma, 13505, 492, 12807).

Refs: .spine/templates/docs/memory/active_tasks/003-fix-quote-item-unique-hash-collision.md"
```

---

## Track C — Hardening do `AddToCart` customizado (`Jn2_WholesaleShoppingTable`)

### Task 7: Consolidar WIP local + corrigir bug do `dedupeProductsBySku`

O working tree já tinha um WIP no `AddToCart.php` (dedupe + fresh items). Ele resolve o principal: re-leitura do estado do carrinho a cada iteração. **Mas** tem um bug: `dedupeProductsBySku` descarta silenciosamente qty divergente quando o mesmo SKU aparece duas vezes no payload (o último sobrescreve). Vamos substituir por agregação de qty.

**Files:**
- Modify: `app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php`
- Create: `app/code/Jn2/WholesaleShoppingTable/Test/Unit/Controller/Shopping/AddToCartDedupeTest.php`

**Step 7.1: Ver WIP atual (sanity check)**

```bash
git diff HEAD -- app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php
```

Esperado: o diff que existe na branch `feature/prevent-quote-id-reuse-b2b` (dedupe + freshItems) agora aparece rebaseado na `hotfix/...` (conseguimos preservar via stash pop na Step P.4).

**Step 7.2: Escrever teste do dedupe correto (TDD — falhar primeiro)**

Criar `app/code/Jn2/WholesaleShoppingTable/Test/Unit/Controller/Shopping/AddToCartDedupeTest.php`:

```php
<?php
declare(strict_types=1);

namespace Jn2\WholesaleShoppingTable\Test\Unit\Controller\Shopping;

use Jn2\WholesaleShoppingTable\Controller\Shopping\AddToCart;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

final class AddToCartDedupeTest extends TestCase
{
    public function testDedupeSumsQuantitiesForSameSku(): void
    {
        $products = [
            ['sku' => 'REF-01-M', 'quantity' => 2],
            ['sku' => 'REF-01-G', 'quantity' => 3],
            ['sku' => 'REF-01-M', 'quantity' => 5],
        ];

        $deduped = $this->callPrivateDedupe($products);

        $bySku = array_column($deduped, null, 'sku');

        self::assertSame(7, $bySku['REF-01-M']['quantity'], 'Qty do SKU repetido deve somar (2+5).');
        self::assertSame(3, $bySku['REF-01-G']['quantity']);
        self::assertCount(2, $deduped);
    }

    public function testDedupeIgnoresPayloadWithoutSku(): void
    {
        $products = [
            ['quantity' => 7],
            ['sku' => 'REF-02-M', 'quantity' => 1],
        ];

        $deduped = $this->callPrivateDedupe($products);

        self::assertCount(1, $deduped);
        self::assertSame('REF-02-M', $deduped[0]['sku']);
    }

    private function callPrivateDedupe(array $input): array
    {
        $controller = (new ReflectionClass(AddToCart::class))->newInstanceWithoutConstructor();
        $method = new \ReflectionMethod(AddToCart::class, 'dedupeProductsBySku');
        $method->setAccessible(true);

        return $method->invoke($controller, $input);
    }
}
```

**Step 7.3: Rodar — deve FALHAR**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  /app/vendor/bin/phpunit --testdox \
  app/code/Jn2/WholesaleShoppingTable/Test/Unit/Controller/Shopping/AddToCartDedupeTest.php
```

Esperado: `testDedupeSumsQuantitiesForSameSku` falha (o WIP atual devolve 5, não 7).

**Step 7.4: Corrigir `dedupeProductsBySku`**

Em `app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php`, substituir o método pelo seguinte (agrega qty numérico, mantém demais campos da última ocorrência):

```php
    /**
     * Consolida entradas do payload por SKU, somando quantidades.
     *
     * O storefront B2B pode enviar o mesmo SKU múltiplas vezes na mesma request
     * (ex.: múltiplas linhas da tabela de cores). Um simples override perde qty;
     * uma soma naive pode duplicar se o payload vier de um retry do front.
     * Hoje a regra é: MERGE por SKU, qty somada, último registro ganha nos
     * demais campos (normalmente todos iguais para o mesmo SKU).
     *
     * @param array<int, array<string, mixed>> $products
     * @return array<int, array<string, mixed>>
     */
    private function dedupeProductsBySku(array $products): array
    {
        $bySku = [];
        foreach ($products as $p) {
            if (!isset($p['sku'])) {
                continue;
            }
            $sku = (string) $p['sku'];
            $qty = isset($p['quantity']) ? (float) $p['quantity'] : 0.0;
            if (isset($bySku[$sku])) {
                $qty += (float) ($bySku[$sku]['quantity'] ?? 0);
            }
            $bySku[$sku] = $p + ($bySku[$sku] ?? []);
            $bySku[$sku]['quantity'] = $qty;
        }

        return array_values($bySku);
    }
```

**Step 7.5: Rodar teste — agora PASSA**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  /app/vendor/bin/phpunit --testdox \
  app/code/Jn2/WholesaleShoppingTable/Test/Unit/Controller/Shopping/AddToCartDedupeTest.php
```

Esperado: 2 testes verdes.

**Step 7.6: Commit**

```bash
git add app/code/Jn2/WholesaleShoppingTable/
git commit -m "fix(wholesale): agregar qty no dedupe do AddToCart + re-ler freshItems

- dedupeProductsBySku agora soma quantidades do mesmo SKU (antes perdia silenciosamente).
- Loops de addProduct relê items frescos do quote a cada iteração, evitando
  segundo addProduct para SKU já gravado na mesma request (causa de
  QUOTE_ITEM_UNIQUE_ITEM_HASH antes da task 003).
- Testes unitários (AddToCartDedupeTest) documentam contrato.

Refs: .spine/templates/docs/memory/active_tasks/003-fix-quote-item-unique-hash-collision.md"
```

---

### Task 8: Mensagens de erro úteis (catch específico)

O `catch (\Exception $e)` atual faz `$this->logger->critical($e)` + mensagem genérica. Quando voltar a aparecer `AlreadyExistsException` ou `PDOException` por outro motivo, o log fica inútil.

**Files:**
- Modify: `app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php` (bloco catch)

**Step 8.1: Substituir o catch**

Trocar:

```php
        } catch (\Exception $e) {
            $this->messageManager->addException($e, __('We can\'t add this item to your shopping cart right now.'));
            $this->logger->critical($e);
        }
```

Por:

```php
        } catch (\Magento\Framework\Exception\AlreadyExistsException $e) {
            $this->logger->error(sprintf(
                '[AddToCart] AlreadyExistsException em quote %s: %s',
                $this->checkoutSession->getQuoteId() ?? 'n/a',
                $e->getMessage()
            ));
            $this->messageManager->addErrorMessage(__(
                'Não foi possível adicionar este item porque ele já está no seu carrinho. '
                . 'Atualize a quantidade em vez de adicionar novamente.'
            ));
        } catch (\Zend_Db_Statement_Exception | \PDOException $e) {
            $this->logger->critical(sprintf(
                '[AddToCart] DB error em quote %s: %s',
                $this->checkoutSession->getQuoteId() ?? 'n/a',
                $e->getMessage()
            ), ['exception' => $e]);
            $this->messageManager->addErrorMessage(__(
                'Ocorreu um erro ao registrar seu item. Tente novamente; se persistir, '
                . 'nos contate pelo SAC informando o horário desta tentativa.'
            ));
        } catch (\Exception $e) {
            $this->messageManager->addException($e, __('We can\'t add this item to your shopping cart right now.'));
            $this->logger->critical($e);
        }
```

**Step 8.2: Smoke local rápido (sintaxe)**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  php -l app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php
```

Esperado: `No syntax errors detected`.

**Step 8.3: Commit**

```bash
git add app/code/Jn2/WholesaleShoppingTable/Controller/Shopping/AddToCart.php
git commit -m "fix(wholesale): catches específicos com mensagens úteis no AddToCart

- AlreadyExistsException: mensagem explicativa pedindo atualizar qty.
- PDO/Zend_Db_Statement_Exception: log com quote_id + mensagem neutra.
- \\Exception genérica mantida como último recurso."
```

---

## Track D — Validação em produção

### Task 9: Deploy da branch de hotfix

Lembrete: o git-flow deste repo tem `master` como branch de ressincronização pós-release (não como destino de PR). O deploy acontece no merge para `production`; `master` recebe merge back depois.

**Step 9.1: Checar CI local**

```bash
docker run --rm -v "$(pwd)":/app -w /app php:8.2-cli \
  /app/vendor/bin/phpunit --testdox app/code/Jn2/
```

Esperado: toda a suíte `Jn2/` verde, incluindo os dois novos testes.

**Step 9.2: PR**

Criar PR `hotfix/quote-item-unique-hash-collision` → `production` (seguindo `docs/workflow/gitflow-operacional.md`). Descrição deve conter:
- Link para `.spine/templates/docs/memory/active_tasks/003-fix-quote-item-unique-hash-collision.md`.
- Link para `.spine/templates/docs/memory/active_tasks/003-evidence/01-indexes-baseline.md` e `02-hotfix-sql.md`.
- Nota: **o índice já foi dropado em produção** pela Task 2; este deploy apenas garante que o `setup:upgrade` não vá recriá-lo por esquema.
- Rollback: `git revert <merge-sha>` + redeploy.

**Step 9.3: Após merge em `production`, sincronizar branches**

```bash
git checkout master && git merge production --ff-only
git checkout develop && git merge production --ff-only
git checkout staging && git merge production --ff-only
git push origin master develop staging
```

### Task 10: Evidência pós-deploy D0 da 003

**Files:** `.spine/templates/docs/memory/active_tasks/003-evidence/03-post-deploy.md`

**Step 10.1: Verificar que `unique_item_hash` não volta**

Minutos após deploy:

```sql
SHOW INDEXES FROM quote_item WHERE Non_unique = 0;
SHOW COLUMNS FROM quote_item LIKE 'unique_item_hash';
```

Esperado: o index continua ausente; a coluna pode ou não ter sido dropada dependendo de `setup:db-schema:upgrade --dry-run` vs `--convert-old-scripts`. Registrar o estado.

**Step 10.2: Smoke test nos clientes bloqueados hoje**

Atendimento entra em contato com Marines (2027), Joelma (8322), 13505, 492, 12807 (via telefone/whatsapp) e pede para refazer o carrinho. Registrar `increment_id` dos pedidos resultantes em `03-post-deploy.md`.

**Step 10.3: Grep em logs por 24h**

```bash
ssh libidus.loja 'grep -c "QUOTE_ITEM_UNIQUE_ITEM_HASH" ~/www/production/current/var/log/system.log' || true
ssh libidus.loja 'grep -c "Violação de chave unica" ~/www/production/current/var/log/system.log' || true
```

Esperado: zero novas ocorrências após o deploy.

**Step 10.4: Commit e fechamento**

```bash
git add .spine/templates/docs/memory/active_tasks/003-evidence/03-post-deploy.md
git commit -m "docs(003): evidência pós-deploy — zero novas colisões em 24h"
```

Atualizar o cabeçalho de `.spine/templates/docs/memory/active_tasks/003-fix-quote-item-unique-hash-collision.md` para `Status: DONE — <data>`.

---

## Checklist de fechamento da 003

- [ ] Task 1 — evidência `01-indexes-baseline.md` committed.
- [ ] Task 2 — hotfix SQL executado em produção por humano, registrado em `02-hotfix-sql.md`.
- [ ] Task 4 — teste de regressão verde antes da correção.
- [ ] Task 5 — decisão registrada no `decision-log.md`.
- [ ] Task 6 — plugin + schema + whitelist removidos; `setup:di:compile` verde.
- [ ] Task 7 — `dedupeProductsBySku` agrega qty, 2 testes unitários verdes.
- [ ] Task 8 — catches específicos com mensagens úteis.
- [ ] Task 9 — PR mergeado em `production`, merge reverso para `main`/`develop`/`staging`/`master`.
- [ ] Task 10 — evidência pós-deploy D0 sem novas colisões.
- [ ] `docs/memory/global/progress.md` atualizado com entrada curta: "2026-04-2X — Incidente `QUOTE_ITEM_UNIQUE_ITEM_HASH` resolvido pela task 003. Zero recorrências em D+1."
- [ ] Arquivo movido para `docs/memory/archived/` quando a janela D+7 passar sem novas ocorrências.
