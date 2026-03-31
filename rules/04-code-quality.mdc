---
description: "Padroes de qualidade de codigo. Aplica-se a todos os arquivos Python do projeto."
globs: "**/*.py"
alwaysApply: false
---

# Padroes de Qualidade de Codigo

## Skills Recomendados
    - Seguir as recomendações que estão em `docs/governance/skills-policy.md`

## Estilo

- Tipagem estrita por padrao nas funcoes (parametros e retorno), com excecoes justificadas quando necessario
- Evitar `Any`, `object`, `dict` sem tipagem interna; usar apenas quando justificado
- Preferir funcoes curtas e coesas; refatorar quando a leitura ficar comprometida
- Docstrings obrigatorias em funcoes publicas (Google style)
- Imports organizados: stdlib, third-party, local (usar isort)
- Nomes descritivos: `calculate_total_price()` nao `calc()`

## Arquitetura

- Seguir rigorosamente o definido em `docs/memory/global/system-patterns.md`
- Separacao clara de camadas quando aplicavel (`models/`, `schemas/`, `services/`, `api/`)
- Logica de negocio NUNCA em rotas/endpoints. Sempre em `services/`
- Acesso a banco via ORM/layer apropriada; repository pattern e opcional, conforme complexidade

## Error Handling

- Exceptions especificas, nunca `except Exception` generico
- Mensagens de erro claras e acionaveis
- Logging estruturado em pontos criticos (entrada de API, falhas de DB, integracoes externas)

## Seguranca

- Nunca commitar secrets, tokens ou senhas
- Usar variaveis de ambiente para configuracao sensivel
- Validar TODOS os inputs externos (request bodies, query params, headers)