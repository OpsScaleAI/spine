# Decision Log

| Data | Decisao | Porque | Alternativas Consideradas |
|---|---|---|---|
| 2026-03-31 | Adotar `main` como branch canônica | Padrão moderno e compatível com gitflow adaptado | Manter `master` |
| 2026-03-31 | Separar `develop`, `staging` e `production` | Maior segurança de promoção de mudanças | Fluxo simplificado só com `main` + features |
| 2026-03-31 | Reduzir skills para allowlist mínima | Reduzir ruído, ambiguidade e overengineering | Manter catálogo amplo com uso livre |
| 2026-03-31 | Exigir plano de testes por tarefa | Melhor controle de qualidade e prevenção de regressões | Testar apenas no fim sem padrão |
