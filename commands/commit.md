---
description: Create a high-quality commit for current changes with safe branch checks
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---

# Slash Command: /commit
Act as a Senior Software Engineer focused on clean history and safe Git flow decisions.

Goal: commit the latest local changes with a clear message that explains why and impact.

1. **Pre-flight Context:**
   - Run:
     - `git status --short --branch`
     - `git diff --staged`
     - `git diff`
     - `git log --oneline -n 10`
   - If there are no staged or unstaged changes, STOP and report:
     - "No local changes to commit."

2. **Branch Safety and Decision Gate:**
   - Detect current branch and whether `develop` exists:
     - `git rev-parse --abbrev-ref HEAD`
     - `git branch --list develop`
   - If current branch is `main`, `master`, `production`, or `staging`:
     - If `develop` exists:
       - Ask confirmation to create `feature/<descriptive-name>` from `develop` and move work there before commit.
     - If `develop` does not exist:
       - Ask confirmation and present options:
         - Option A: create `feature/<descriptive-name>` from current branch and commit there.
         - Option B: initialize `develop` from current branch, then create `feature/<descriptive-name>` from `develop`.
   - If current branch starts with `feature/`, `hotfix/`, or `release/`, continue.

3. **Commit Scope Discipline:**
   - Stage only files relevant to this delivery.
   - Do not include unrelated noise.
   - If there are unrelated changes, list them and ask whether to exclude.

4. **Commit Message Quality (mandatory):**
   - Use Conventional Commits:
     - `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
   - Subject line must be concise and meaningful.
   - Body must be explicit and useful for future audits:
     - `Why:` problem or intent
     - `What changed:` key files and behavior impact
     - `Validation:` tests/checks executed
     - `Notes:` risks, follow-ups, or migration notes (if any)
   - Prefer message quality over shortness.

5. **Commit Execution:**
   - Create the commit.
   - Show:
     - `git show --name-only --oneline HEAD`
     - `git status --short --branch`

6. **Mandatory Final Report:**
   - Final branch used.
   - Commit hash + full commit message.
   - Files included in the commit.
   - Recommended next step:
     - merge path in the current workflow (for example: `feature/* -> develop`).
