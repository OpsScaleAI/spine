# System Patterns

## Optional Complementary Tooling

- **Graphify** can be adopted at the consumer-project level as a retrieval optimization layer.
- Graphify is **optional** and **not a dependency** of Spine itself.
- Use Graphify to compress exploration context (graph queries first), while `docs/memory/` and Spine rules remain the operational source of truth.
- Recommended for medium/large consumer repositories where broad file scanning increases input-token cost.
- Setup and `graphify-out` generation: [Spine README — Optional: Graphify](https://github.com/OpsScaleAI/spine#optional-graphify).

## Architecture
[Fill in]

## Design Patterns
[Fill in]

## Dependencies
[Fill in]

## Project-Specific Alterations

Deviations from platform/framework/vendor defaults. Agents must not revert these to "standard" behavior without explicit approval.

| Area | Platform/default expectation | What this project does | Code paths | Decision ref |
|------|------------------------------|------------------------|------------|--------------|
| [area] | [default] | [custom behavior] | `path/to/code` | decision-log § YYYY-MM-DD |
