---
name: zera-cleanup
license: MIT
description: >-
  Repository restructuring under Zero Entropy Architecture (ZERA). Scans workspace root and scripts/,
  classifies loose scripts into canonical folders (tests/, tools/, archive/), rewires configs and adds
  an automated script hygiene test. Changes only file layout; documentation and process standards are
  out of scope (see project-standardization).
---

# ZERA Cleanup & Repository Restructuring Skill

This skill brings repository **structure** to the Zero Entropy Architecture standard: no loose
scripts in the root, no dead `scripts/` folder, hygiene enforced by a test.

## Scope

- In scope: file layout, moves, path rewiring in build/test/CI configs, hygiene test.
- Out of scope: documentation, journals, `AGENTS.md` content, process standards.
  Navigation and documentation order are handled by `project-standardization`.
- If a request is about documents rather than files, stop and hand it to `project-standardization`.

## Primary Invariants

1. **Safety First:** Never perform blind file deletion (`rm -rf`). Always inspect Git status,
   classify files systematically, and verify with automated hygiene tests.
2. **Timeless & Clean AGENTS.md (CRITICAL RULE):**
   `AGENTS.md` is a permanent architectural constitution, NOT an ephemeral status report or file counter.
   - **STRICTLY PROHIBITED:** Never write ephemeral quantities (e.g. "32 scripts in scripts/"),
     timestamps, or temporary file listings into `AGENTS.md`.
   - **MANDATORY AUDIT:** Before finishing, audit the target `AGENTS.md`. If any prior agent wrote file
     counters or temporary workarounds into it, remove them and keep invariant principles.
     Concrete file tracking belongs to automated tests, never to markdown instructions.

## Autonomous 6-Step Execution Protocol

Use when instructed to "clean up repository structure", "разложить скрипты", or "run zera-cleanup".

### Step 1: Git Status & Safety Checkpoint

1. Run `git status --short` and read the result.
2. If uncommitted work exists, do **not** commit on your own. List the changed files, propose a
   checkpoint commit with an explicit path list and message, and wait for confirmation.
3. Never use `git add .` or `git add -A`: stage only the paths you name.

### Step 2: Script Inventory & Semantic Classification

Inspect loose files in the workspace root and `scripts/` (`.py`, `.sh`, `.ts`, `.tsx`, `.mjs`, `.cjs`).
Categorize each file into one of four canonical destinations:

1. **Tests (`tests/browser/`, `tests/regression/`, `tests/unit/`):** files containing `test`, `smoke`,
   `regression`, `check`, `spec`, `review`, or browser test runners.
2. **Tools & Infrastructure (`tools/`):** maintenance runners, CI helpers, doc validators, sync daemons.
3. **Core Package Modules (`<package_dir>/`):** domain logic that belongs inside the application package.
4. **Obsolete / Dead Spikes (`archive/legacy_scripts/`):** throwaway scripts and historical benchmarks
   that are no longer referenced.

### Step 3: Migration & Restructuring

1. Create canonical target directories as needed: `mkdir -p tests/browser tests/regression tools`.
2. Move files with `mv` or `git mv`.
3. If `scripts/` becomes completely empty, remove it with `rmdir`.

### Step 4: Configuration & Reference Rewiring

1. Check `package.json`, `Makefile`, `Dockerfile`, crontab and CI configs for references to old paths.
2. Update the paths to the new canonical locations.
3. Run the updated commands to verify they work.

### Step 5: Generate Automated Hygiene Gate

Add a test that permanently locks the layout:
- **Python / Generic:** create `tests/test_script_hygiene.py` asserting:
  - the `scripts/` directory does not exist (or matches a strict allowed set);
  - no loose `.py`, `.sh`, `.js` files in the repository root.
- Run the hygiene test and confirm it passes.

### Step 6: Report and Scoped Commit

1. Show `git status --short` and the list of moves.
2. Stage only the moved files and updated configs, with an explicit path list.
3. Propose an atomic commit message such as
   `refactor(zera): move loose scripts to tests/ and tools/, add hygiene test`.
4. Commit only after confirmation from the user; then report the verified test result and exit code.
