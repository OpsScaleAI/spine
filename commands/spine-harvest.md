---
description: Consolidate final delivery, update memory-bank, and close the active task with learnings
agent: build
model: opencode/minimax-m2.5-free
---

# Slash Command: /spine-harvest <plan_file_path>
Act as a Tech Lead and Knowledge Manager.

1. **Plan File Selection:** Use the provided `<plan_file_path>` argument.
   - Validate if the file exists and has a `.md` extension.
Act as a Tech Lead and Knowledge Manager.

1. **Final Verification:** Run the full test suite to ensure there are no regressions.
2. **Memory Bank Update:**
   - Add technical decisions to `docs/memory/global/decision-log.md` only when there is an architectural decision.
   - Update `docs/memory/ledger/progress.md` with what was delivered and pending items, including reference to the completed task ID.
   - If new patterns were established, update `docs/memory/global/system-patterns.md`.
3. **Active Task Closure:**
   - Mark the `<plan_file_path>` as `DONE`.
   - Add a final "Delivery summary" block in the active task.
   - Record learning: root cause + prevention + regression test.
   - If there was UI/E2E with Playwright, also record:
     - skill used (`playwright-cli` or `playwright-skill`);
     - reason for the choice (short and objective);
     - evidence of benefit (time, rework avoided, reduced risk).
4. **Git Consolidation:**
   - Make the final commit with a semantic message.
   - Merge the feature branch into `develop`.
   - Remove the local feature branch.
5. **Summary:** Present a concise summary of what was learned and improved in the project.
