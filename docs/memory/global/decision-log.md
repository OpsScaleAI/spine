# Decision Log

| Data | Decisao | Porque | Alternativas Consideradas |
|---|---|---|---|
| 2026-03-31 | Adotar `main` como branch canônica | Padrão moderno e compatível com gitflow adaptado | Manter `master` |
| 2026-03-31 | Separar `develop`, `staging` e `production` | Maior segurança de promoção de mudanças | Fluxo simplificado só com `main` + features |
| 2026-03-31 | Reduzir skills para allowlist mínima | Reduzir ruído, ambiguidade e overengineering | Manter catálogo amplo com uso livre |
| 2026-03-31 | Exigir plano de testes por tarefa | Melhor controle de qualidade e prevenção de regressões | Testar apenas no fim sem padrão |
| 2026-04-10 | Instalação per-project via URL (opt-in) | Spine como framework público exige que cada projeto opte explicitamente; URLs remotas eliminam symlinks locais, são portáteis e auto-atualizáveis | Symlink local (amarra ao filesystem), git submodule (complexo para iniciantes), path absoluto (não portátil) |
| 2026-04-10 | Remover `instructions` do config global do OpenCode | Config global é mergeado em todos os projetos, forçando regras do Spine em projetos não-Spine | Manter global com override por projeto (frágil, esquecimento) |
| 2026-04-21 | Default `--skills=core` ao invés de `all` | Instalar 34 skills por default é excessivo; core skills (5) cobrem ciclo de entrega básico | Manter `all` como default (ruído excessivo), não oferecer default (fricção) |
| 2026-04-21 | Adicionar `--update` com cleanup de dangling | `git pull` resolve conteúdo mas não cria/remove symlinks estruturais; `--update` faz install idempotente + limpa órfãos | Script separado `update.sh` (mais um arquivo para manter), exigir reinstall completo (perde estado) |
| 2026-04-21 | Adicionar `--uninstall` para remoção limpa | Projetos precisam de forma confiável de remover artefatos Spine sem rm manual | Remoção manual (erro-prone), deixar artefatos (polui projeto) |
| 2026-04-21 | Health check sempre visível após install | Detectar symlinks quebrados precocemente evita debug difícil depois | Health check apenas com flag (facilmente esquecido), sem health check |
