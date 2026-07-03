# AGENTS.md — LCT Agent Instructions

You are an AI coding agent working in the `lct` repository. This project is a Bash CLI intended to manage local configuration in a repeatable, ergonomic way.

This file defines:

- project intent and boundaries
- repo working conventions
- branching, worktree, and setup expectations
- how to plan and execute changes safely
- what “good” looks like for contributions

If anything here conflicts with reality, treat it as a bug in this file and propose an edit.

## 0) Prime directive

**Prefer small, reviewable changes that keep the CLI stable.**

- Do not refactor for fun.
- Do not introduce new dependencies unless there is clear value.
- Keep backward compatibility unless an issue explicitly allows breaking changes.
- Optimize for clarity, predictable behavior, and safe defaults.

When in doubt: add docs, add tests if present, and keep the change minimal.

## 1) Repo orientation

Top-level structure includes:

- `src/` — core CLI source and Bashly source-of-truth definitions.
- `scripts/` — task scripts and helpers.
- `scripts/setup.sh` — canonical one-command bootstrap for humans and coding agents.
- `docs/` — generated user-facing documentation.
- `settings.yml` — project configuration.
- `.mise/config.toml` — pinned tools and task runner definitions.
- `test/` — approval/smoke tests for CLI behavior.
- `target/` — generated build output; do not commit generated artifacts from here.

Standard commands:

- `./scripts/setup.sh` bootstraps the environment, installs tools, validates, builds, and runs tests.
- `mise run build` generates the local CLI in `target/build/lct`.
- `mise run test` runs unit/approval tests.
- `mise run dev` builds and installs the local CLI for manual development.
- `mise run docs` regenerates Markdown docs.
- `mise run pages` regenerates GitHub Pages output.

## 2) Branching and worktree strategy

### 2.1 Branch naming

Use short, descriptive branches from `main`:

- `feature/<short-name>` for user-facing features
- `fix/<short-name>` for bug fixes
- `docs/<short-name>` for documentation-only work
- `chore/<short-name>` for maintenance/setup changes

Avoid committing directly to `main` unless the user explicitly asks for it.

### 2.2 Worktree-safe development

This repo should support multiple concurrent agent worktrees. Keep all generated and temporary state inside the current checkout unless the tool explicitly requires a global path.

Recommended local pattern:

```bash
git fetch origin main
git worktree add ../lct-<task-name> -b <branch-name> origin/main
cd ../lct-<task-name>
./scripts/setup.sh
```

Worktree rules:

- Run setup inside each worktree before editing.
- Do not assume another worktree has installed dependencies or generated build output.
- Do not share `target/` output between worktrees.
- Do not write ad-hoc state into the repo root unless it is intentionally versioned.
- Use branch-specific names for external scratch paths if a tool requires them.
- Before finishing, run verification from the same worktree that contains the diff.

### 2.3 Agent concurrency

Multiple agents may work in parallel. To avoid collisions:

- Keep changes scoped to the requested issue/task.
- Avoid broad formatting-only diffs.
- Rebase or merge from `main` before opening a PR if the branch has drifted.
- Never overwrite another branch or worktree unless explicitly instructed.
- Do not remove files you did not investigate.

## 3) Setup and environment expectations

`scripts/setup.sh` is the canonical setup entrypoint. It should be safe to run repeatedly.

The setup script is responsible for:

1. ensuring `mise` is available
2. trusting `.mise/config.toml`
3. installing pinned tools
4. validating the Bashly configuration
5. building the CLI
6. running tests unless `LCT_SETUP_SKIP_TESTS=1` is set

For automated environments such as Codex, use:

```bash
./scripts/setup.sh
```

If setup time needs to be reduced while iterating, tests may be skipped explicitly:

```bash
LCT_SETUP_SKIP_TESTS=1 ./scripts/setup.sh
```

Do not replace the setup flow with one-off install commands unless you are debugging the setup script itself.

## 4) How to work

### 4.1 Understand before changing

Before editing code:

1. Identify the user story or issue being solved.
2. Identify the CLI surface impacted: command names, flags, config, and output.
3. Find the implementation entrypoints and shared utilities.
4. Determine whether behavior changes are backward compatible.

If something is ambiguous:

- choose the most conservative interpretation
- document the assumption in the PR, commit message, or docs

### 4.2 Make the smallest safe change

- Prefer local edits over sweeping refactors.
- If a refactor is required, do it in two steps:
  1. mechanical refactor with no behavior change
  2. functional change with tests and docs

### 4.3 Validate locally

Run the standard flow for any meaningful change:

```bash
mise run build
mise run test
```

If setup or pinned tools changed, run:

```bash
./scripts/setup.sh
```

For user-visible CLI behavior changes, also run manual smoke tests for the affected command.

### 4.4 Produce reviewable diffs

- Keep commits focused.
- Avoid drive-by formatting changes outside touched files.
- Update docs when behavior changes.
- Keep generated artifacts out of git unless explicitly intended.

### 4.5 Complete the work

When the requested work is complete:

1. Ensure the working tree only contains intentional changes.
2. Run the appropriate verification commands and record what passed, failed, or could not be run.
3. Commit the completed work to the task branch with a concise, descriptive message.
4. Push the branch to `origin`.
5. Open a pull request against `main` unless the user explicitly asked for a different base branch.

The pull request should include:

- a summary of the change
- the verification commands and results
- any assumptions, risks, or follow-up work

Do not leave completed work only as an uncommitted local diff unless the user explicitly asks for that workflow.

## 5) Coding standards: Bash

### 5.1 Portability targets

Assume macOS is a primary target environment, but Linux should also work.

- Avoid GNU-only flags unless guarded or documented.
- Prefer POSIX-ish utilities where possible.
- If non-POSIX behavior is necessary, explain why in comments or docs.

### 5.2 Strictness and safety

Use safe Bash patterns:

- `set -euo pipefail` in scripts where appropriate, following repo style
- quote variables: `"$var"`
- prefer arrays for word-splitting-sensitive values
- avoid `eval` unless there is no alternative; document why and validate input

### 5.3 Output conventions

CLI output should be:

- stable and automation-friendly
- predictable for the same inputs
- quiet by default unless the command is intended to display information
- errors to stderr with non-zero exit codes on failure

If there is a verbose mode, keep it consistent across commands as `--verbose`.

## 6) CLI UX rules

### 6.1 Backward compatibility

- Do not rename commands or flags unless explicitly approved.
- If output formatting must change, consider adding `--json`, `--plain`, or `--format` and preserving the old default for one release cycle.

### 6.2 Help text

Every command should have:

- a one-line summary
- examples for non-trivial commands
- clear flag descriptions

### 6.3 Exit codes

- `0` means success.
- Non-zero means failure.
- If “no results found” is not an error, return `0` and print nothing or a concise non-error message.

## 7) Configuration rules

Treat `settings.yml` and related configuration as contracts:

- Validate user-provided config early.
- Provide clear errors pointing to the exact invalid key/value.
- Avoid silent fallbacks that surprise users.

If introducing new config keys:

- document them in `docs/`
- provide defaults
- ensure upgrades do not break existing installs

## 8) Build and release conventions

Use existing task runners:

- Prefer `mise` tasks over bespoke one-off commands.
- Add reusable workflows to `.mise/config.toml` or `scripts/`.
- Keep generated artifacts out of git unless explicitly intended.

Release hygiene:

- Update changelog/release notes if the project has them.
- Ensure install steps remain correct.
- Keep generated artifacts out of version control unless expected.

## 9) Documentation rules

Any user-visible behavior must be documented:

- new commands or flags
- changed defaults
- new required dependencies
- new config keys

Docs are generated using Bashly documentation features. Update the source-of-truth CLI definitions, then run:

```bash
mise run docs
mise run pages
```

## 10) Smoke testing checklist

After changes, extend `test/approve` to smoke test commands you added or changed when applicable.

Manual checks:

1. `target/build/lct --help` renders and includes command/flag changes.
2. `target/build/lct <command> --help` renders and examples make sense.
3. Run changed commands with:
   - typical input
   - empty input or missing config
   - an error case with clear message and exit code
4. Confirm output formatting is stable and not overly noisy.

## 11) Debugging playbook

If something fails:

- reproduce with the smallest possible command invocation
- add temporary debug logging guarded by a verbose flag
- confirm assumptions about environment, PATH, Homebrew, and macOS/Linux tool variants
- check for subshell and pipeline exit-code gotchas
- avoid fixing by weakening error handling unless justified

## 12) Planning format

When asked to implement a feature or fix, respond with:

### Plan

- Summary of the change
- Files likely touched
- User-facing behavior impact
- Risks and mitigations

### Patch

- Implement minimal diff
- Update docs alongside code using `mise run docs`
- Update GitHub Pages docs with `mise run pages` if applicable

### Verify

- List the exact commands run
- Summarize what passed, failed, or could not be run
