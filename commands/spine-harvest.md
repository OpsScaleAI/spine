---
description: Consolidate final delivery, update memory-bank, and close the active task with learnings
agent: build
---

# Slash Command: /spine-harvest <plan_file_path>
Act as a Tech Lead and Knowledge Manager.

1. **Plan File Selection:** Use the provided `<plan_file_path>` argument.
   - Validate if the file exists and has a `.md` extension.
2. **GitFlow Compliance Check (mandatory):**
   - GitFlow is mandatory (not optional) for harvest.
   - The implementation branch must match `feature/<descriptive-name>`.
   - The base integration branch must be `develop`.
   - If branch naming does not comply, stop and request correction before any consolidation steps.

3. **Final Verification:** Run the full test suite to ensure there are no regressions.
4. **Memory Bank Update:**
   - Add technical decisions to `docs/memory/global/decision-log.md` only when there is an architectural decision.
   - Update `docs/memory/global/domain-glossary.md` when canonical domain terms were promoted during discovery or delivery.
   - Update `docs/memory/ledger/progress.md` with what was delivered and pending items, including reference to the completed task ID.
   - If new patterns were established, update `docs/memory/global/system-patterns.md`.
5. **Active Task Closure:**
   - Mark the `<plan_file_path>` as `DONE`.
   - Add a final "Delivery summary" block in the active task.
   - Record learning: root cause + prevention + regression test.
   - If there was UI/E2E with Playwright, also record:
     - skill used (`playwright-cli` or `playwright-skill`);
     - reason for the choice (short and objective);
     - evidence of benefit (time, rework avoided, reduced risk).
6. **Git Consolidation (GitFlow required):**
   - Make the final commit with a semantic message.
   - Merge only a valid `feature/<descriptive-name>` branch into `develop`.
   - Remove the local feature branch.
7. **Summary:** Present a concise summary of what was learned and improved in the project.
