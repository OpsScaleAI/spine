# Domain Glossary Format

Glossary lives at `docs/memory/global/domain-glossary.md`. Create the file lazily — only when the first term is resolved.

## Structure

```md
# Domain Glossary

{One or two sentence description of what this project context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) do not belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.
- **Language only.** Do not treat the glossary as a spec, scratch pad, or repository for implementation decisions.

## Single vs multi-context repos

**Single context (most repos):** One `domain-glossary.md` at `docs/memory/global/`.

**Multiple contexts:** Add a `## Context map` section listing each bounded context, where its language lives (if split), and how contexts relate:

```md
## Context map

- **Ordering** — receives and tracks customer orders
- **Billing** — generates invoices and processes payments
- **Fulfillment** — manages warehouse picking and shipping

### Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
```

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask.
