---
description: Consolidate final delivery, update memory-bank, and close the active task with learnings
agent: build
---

# Slash Command: /spine-harvest <plan_file_path>
Act as a Tech Lead and Knowledge Manager.

1. **Plan File Selection:** Use the provided `<plan_file_path>` argument.
   - Validate if the file exists and has a `.md` extension.
   - File must be under `docs/memory/active_tasks/` (open tasks only).
2. **GitFlow Compliance Check (mandatory):**
   - GitFlow is mandatory (not optional) for harvest.
   - Read `branch` and `base` from task frontmatter (fallback: legacy `## Branch:` / `## Base:` if present).
   - The implementation branch must match `feature/<descriptive-name>`.
   - The base integration branch must be `develop`.
   - If branch naming does not comply, stop and request correction before any consolidation steps.

3. **Final Verification:** Run the full test suite to ensure there are no regressions.

3.5. **Graphify refresh (only when Graphify is in use):**
    - Proceed only if `graphify-out/graph.json` exists in the project root (Graphify is active for this consumer project).
    - If `graphify` CLI is available, run `graphify update .` from the project root to refresh the exploration graph after delivery changes.
    - If the CLI is missing or the update fails, note it in the harvest summary; do not block harvest or Git consolidation.

3.6. **MkDocs refresh (only when MkDocs is in use):**
    - Proceed only if `docs/mkdocs/mkdocs.yml` exists in the project root (MkDocs is active for this consumer project).
    - Do **not** rely on bare `mkdocs` on PATH (often missing). From the project root, run the first command that works:
      1. `uv run --extra docs mkdocs build -f docs/mkdocs/mkdocs.yml --strict` (preferred when `uv` + `docs` optional-dep / `requirements-docs.txt` exist)
      2. `.venv/bin/mkdocs build -f docs/mkdocs/mkdocs.yml --strict` (when venv already has mkdocs)
      3. `mkdocs build -f docs/mkdocs/mkdocs.yml --strict` (only if `command -v mkdocs` succeeds)
    - If none work, install docs deps (`uv sync --extra docs` or `uv pip install -r requirements-docs.txt`) and retry step 1; if still failing, report the errors.
    - If the build fails, report the errors; do not block harvest or Git consolidation.

4. **Memory Bank Update:**

   **4a. `docs/memory/ledger/progress.md`**
   - Refresh **Current state** (short bullet list).
   - **Append** one delivery log block at the top of **Delivery log (newest first)** — do not rewrite history:
     - `### YYYY-MM-DD — Title` (from frontmatter `title` or task slug)
     - `**Task:** NNN-slug | **Branch:**` from frontmatter
     - `**Tags:**` — flatten frontmatter `tags` list to comma-separated (per `docs/governance/memory-tags-policy.md`)
     - `**Description:**` — concise delivery summary

   **4b. `docs/memory/ledger/learnings.md`** (when task recorded root cause, incident, or rework)
   - Before new `LEARN-NNN`, grep existing entries by **tags** + symptoms per `memory-tags-policy.md`.
   - Add new `LEARN-NNN` or append to **Recurrences** on matching entry.
   - **Tags** required on new entries; copy from task frontmatter, refine if needed.
   - Mirror one-line pointer in task Delivery summary body.

    **4c. Unchanged when applicable:**
    - `docs/memory/global/decision-log.md` — architectural decisions only.
    - `docs/memory/global/domain-glossary.md` — canonical terms promoted during discovery or delivery.
    - `docs/memory/global/system-patterns.md` — new patterns established.
    - `## Implementation Plan` in the task body is not copied to the delivery log (summary uses frontmatter `title`, `tags`, and delivery description only).

     **4d. Roadmap feedback (optional):**
     - When task frontmatter contains `roadmap_idea`, suggest running `/spine-roadmap --review` to update confidence on the linked idea.
     - Do not auto-edit `roadmap.md`.
     - Include the suggestion in the harvest summary.

     **4e. MkDocs documentation (when `docs/mkdocs/mkdocs.yml` exists):**
    - Load the `documentation-driven-development` skill for documentation update criteria.
    - Review whether this task introduced public APIs, architectural patterns, or user-facing features.
    - If so, update the relevant `docs/mkdocs/*.md` files and include them in the final commit with the `docs:` prefix.
    - Run `uv run --extra docs mkdocs build -f docs/mkdocs/mkdocs.yml --strict` (fallback: `.venv/bin/mkdocs` or PATH `mkdocs`) to verify the documentation builds cleanly.
    - If the task does not warrant documentation updates, note the decision in the delivery summary.

 6. **Active Task Closure:**
   - Update frontmatter: `status: DONE`, `completed_at: YYYY-MM-DD`, `updated_at: YYYY-MM-DD`.
   - Set `related_learnings:` when linked to `LEARN-NNN` entries.
   - Add final **Delivery summary** block in task body.
   - Record learning: root cause + prevention + regression test.
    - If there was UI/E2E with Playwright, also record:
      - skill used (`playwright-cli` or `playwright-skill`);
      - reason for the choice (short and objective);
      - evidence of benefit (time, rework avoided, reduced risk).
    - If MkDocs is active, record in delivery summary: files updated in `docs/mkdocs/`, mkdocs build status.
   - **`git mv`** `docs/memory/active_tasks/NNN-name.md` → `docs/memory/completed_tasks/NNN-name.md` (create dir if missing).
   - Include the move in the final commit before merge to `develop`.

 7. **Git Consolidation (GitFlow required):**
   - Make the final commit with a semantic message.
   - Merge only a valid `feature/<descriptive-name>` branch into `develop`.
   - Remove the local feature branch.

 8. **Summary:** Present a concise summary of what was learned and improved in the project. When step 3.5 ran (or was skipped/failed), include Graphify refresh status and whether `graphify query` was used during delivery exploration. When step 3.6 ran (or was skipped/failed), include MkDocs build status. When step 4d applied, note whether `/spine-roadmap --review` was suggested.
