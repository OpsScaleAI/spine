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

5. **Active Task Closure:**
   - Update frontmatter: `status: DONE`, `completed_at: YYYY-MM-DD`, `updated_at: YYYY-MM-DD`.
   - Set `related_learnings:` when linked to `LEARN-NNN` entries.
   - Add final **Delivery summary** block in task body.
   - Record learning: root cause + prevention + regression test.
   - If there was UI/E2E with Playwright, also record:
     - skill used (`playwright-cli` or `playwright-skill`);
     - reason for the choice (short and objective);
     - evidence of benefit (time, rework avoided, reduced risk).
   - **`git mv`** `docs/memory/active_tasks/NNN-name.md` → `docs/memory/completed_tasks/NNN-name.md` (create dir if missing).
   - Include the move in the final commit before merge to `develop`.

6. **Git Consolidation (GitFlow required):**
   - Make the final commit with a semantic message.
   - Merge only a valid `feature/<descriptive-name>` branch into `develop`.
   - Remove the local feature branch.

7. **Summary:** Present a concise summary of what was learned and improved in the project.
