---
name: zera-cleanup
license: MIT
description: >-
  Autonomous repository restructuring and decluttering skill under Zero Entropy Architecture (ZERA).
  Scans workspace root and scripts/, safely commits active work, classifies loose scripts into
  canonical folders (tests/, tools/, archive/), updates package configs, eliminates obsolete scripts/
  folders, and establishes an automated script hygiene gate test.
---

# ZERA Cleanup & Repository Restructuring Skill

This skill automates the complete sanitization of any repository cluttered with ad-hoc scripts, bringing it to the unified Zero Entropy Architecture (ZERA) standard.

## Primary Invariants
1. **Safety First:** Never perform blind file deletion (`rm -rf`). Always inspect Git status, checkpoint active work into a safe commit if requested, classify files systematically, and verify with automated hygiene tests.
2. **Timeless & Clean AGENTS.md (CRITICAL RULE):**
   `AGENTS.md` is a permanent architectural constitution, NOT an ephemeral status report or file counter.
   - **STRICTLY PROHIBITED:** Never write ephemeral quantities (e.g. "32 scripts in scripts/", "130 scripts in root"), timestamps, or temporary file listings into `AGENTS.md`.
   - **MANDATORY AUDIT:** Before finishing, audit `AGENTS.md` in the target project. If any prior agent wrote file counters, numbers of scripts, or temporary workarounds into `AGENTS.md`, immediately sanitize and clean them up, replacing them with timeless, invariant architectural principles. All concrete file tracking must be delegated to automated code tests (`test_script_hygiene.py`), never hardcoded in markdown instructions.

---

## ZERA for documentation

Apply the project’s own conventions and safety rules; do not assume a particular
directory layout or create a parallel set of documents for LLMs.

1. Start at the existing documentation entry point. Make the current operational
   route and tool index easy to find, with concise task-oriented links.
2. For each operation, identify one canonical current instruction. The index
   should say when to use it, required inputs, where the exact command is,
   expected output and verification limits; link to details instead of copying
   a second recipe. If recipes conflict, check code and tests before choosing.
3. Separate roles: current instructions describe how to work now; experiment
   journals record findings, limitations and decisions; individual run reports
   and artifacts hold inputs, commands and evidence. Link these together rather
   than repeating detailed reports. A repeat with no new finding needs no new
   journal entry.
4. Label historical recipes as historical, not as current entry points. Preserve
   evidence, rollback material, links and dependencies: age or missing local
   references alone does not prove a file is safe to remove or archive.
5. Do not rewrite journals or delete/move documents in bulk by default. Identify
   specific confusing duplication, propose a small reversible change and respect
   the user's scope and project approval rules. Preserve existing work.
6. Verify local links and the project's documentation checks. Also test navigation
   from the entry point with representative tasks, preferably using a fresh
   independent reader: find the current command, its inputs and limits, and a
   historical finding without mistaking it for a current instruction. Report
   actual results and what was not tested.

---

## Autonomous 6-Step Execution Protocol

When instructed to "clean up repository according to ZERA", "bring project to standard", or "run zera-cleanup":

### Step 1: Git Status & Safety Checkpoint
1. Run `git status` to see whether the worktree is clean or contains dirty/uncommitted modifications.
2. If uncommitted work exists:
   - Stage and create a safety checkpoint commit:
     `git add . && git commit -m "chore: checkpoint active work before zera restructuring"`
   - Ensure the commit succeeds so no work can be lost.

### Step 2: Script Inventory & Semantic Classification
Inspect all loose files in the workspace root and `scripts/` (e.g. `.py`, `.sh`, `.ts`, `.tsx`, `.mjs`, `.cjs`):
Categorize each file into one of four canonical destinations:
1. **Tests (`tests/browser/` or `tests/regression/` or `tests/unit/`):**
   - Files containing `test`, `smoke`, `regression`, `check`, `spec`, `review`, or browser test runners.
2. **Tools & Infrastructure (`tools/`):**
   - Maintenance runners, CI helpers, doc validators, sync daemon scripts.
3. **Core Package Modules (`<package_dir>/`):**
   - Domain logic that belongs inside the application package rather than standalone scripts.
4. **Obsolete / Dead Spikes (`archive/legacy_scripts/`):**
   - One-off throwaway test scripts or historical benchmarks that are no longer referenced.

### Step 3: Migration & Restructuring
1. Create canonical target directories as needed:
   - `mkdir -p tests/browser tests/regression tools`
2. Move files using Git or filesystem move (`mv` / `git mv`).
3. If `scripts/` becomes completely empty, remove it (`rmdir scripts`).

### Step 4: Configuration & Reference Rewiring
1. Check `package.json`, `Makefile`, `Dockerfile`, `crontab`, or CI configs for references to the old paths (e.g., `scripts/check-docs.mjs` $\rightarrow$ `tools/check-docs.mjs`).
2. Update the paths to the new canonical locations.
3. Test the updated commands to verify they run cleanly.

### Step 5: Generate Automated Hygiene Gate
Add an automated script hygiene test that permanently locks down the repository:
- **Python / Generic:** Create `tests/test_script_hygiene.py` asserting:
  - `scripts/` directory does not exist (or matches a strict allowed set).
  - No loose `.py`, `.sh`, `.js` files in the repository root.
- Run the hygiene test to verify it passes with 100% OK.

### Step 6: Atomic Git Commit & Report
1. Stage all restructuring changes:
   `git add . && git commit -m "refactor(zera): eliminate loose scripts, organize tests and tools, add hygiene test"`
2. Verify `git status` is clean.
3. Report a clear summary of moved files and verified tests to the user.
