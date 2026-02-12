# agents.md — LCT (Local Configuration Tool) Agent Instructions

You are an AI coding agent working in the `lct` repository. This project is a Bash CLI intended to manage local configuration in a repeatable, ergonomic way.

This file defines:

- project intent + boundaries
- the repo’s working conventions
- how to plan and execute changes safely
- what “good” looks like for contributions

If anything here conflicts with reality, treat it as a bug in this file and propose an edit.

## 0) Prime directive

**Prefer small, reviewable changes that keep the CLI stable.**

- Don’t “refactor for fun.”
- Don’t introduce new dependencies unless there is clear value.
- Keep backward compatibility unless an issue explicitly allows breaking changes.
- Optimize for: clarity, predictable behavior, and safe defaults.

When in doubt: add docs, add tests (if present), and keep the change minimal.

## 1) Repo orientation (what’s where)

Top-level structure includes (non-exhaustive):

- `src/` — core CLI source (Bash). Likely includes Bashly-generated structure or source-of-truth CLI definitions.
- `scripts/` — task scripts / helpers (build/release/maintenance).
- `docs/` — user-facing documentation.
- `settings.yml` — project configuration (treat as source-of-truth config).
- `scripts/setup.sh` — installs dev dependencies / bootstraps environment.
- `justfile` — developer workflows (build, release, install, etc.). :contentReference[oaicite:2]{index=2}
- `test/` — unit tests `

From the repo README snippet:

- Run `./scripts/setup.sh` for needed libraries
- `just build` generates a local version in `target/build/lct`
- `just install` installs the local version
- `just release` creates a new release :contentReference[oaicite:3]{index=3}
- `just test` runs unit tests

## 2) How to work (agent workflow)

### 2.1 Understand before changing

Before editing code, do this:

1. Identify the user story / issue being solved.
2. Identify the CLI surface impacted (command names, flags, outputs).
3. Find the implementation entrypoint(s) and any shared utilities.
4. Determine whether behavior changes are backward compatible.

If something is ambiguous:

- pick the most conservative interpretation
- document the assumption in the PR/commit message or in `docs/`

### 2.2 Make the smallest safe change

- Prefer local edits over sweeping refactors.
- If a refactor is required, do it in two steps:
  1. mechanical refactor with no behavior change
  2. functional change with tests/docs

### 2.3 Validate locally (minimum bar)

Run the standard build/install flow for any meaningful change:

- `./scripts/setup.sh` (if dependencies changed)
- `just build`
- `just test`
- `just install`
- Smoke test the CLI locally (see section 8)

If formatting/linting tools exist, run them.
If tests exist, run them. If not, add at least a smoke-test doc snippet.

### 2.4 Produce reviewable diffs

- Keep commits focused.
- Avoid drive-by formatting changes outside touched files.
- Update docs when behavior changes.

## 3) Coding standards (Bash)

### 3.1 Portability targets

Assume macOS is a primary target environment, however this should support linux environments as well.

- Avoid GNU-only flags unless you guard them or document requirements.
- Prefer POSIX-ish utilities where possible.
- If you must use non-POSIX behavior, explain why in comments or docs.

### 3.2 Strictness and safety

Use safe bash patterns:

- `set -euo pipefail` in scripts where appropriate (or repo’s established style)
- quote variables (`"$var"`)
- prefer arrays for word-splitting-sensitive values
- avoid `eval` unless there is no alternative; document why and validate input

### 3.3 Output conventions

CLI output should be:

- stable (automation-friendly)
- predictable (same inputs → same outputs)
- quiet by default unless the command’s purpose is “show”
- errors to stderr, non-zero exit codes on failure

If there’s a “verbose” mode, keep it consistent across commands (`--verbose`).

## 4) CLI UX rules

### 4.1 Backward compatibility

- Do not rename commands/flags unless explicitly approved.
- If you must change output formatting, consider:
  - adding a `--json` / `--plain` / `--format` option
  - keeping old formatting as default for one release cycle

### 4.2 Help text

Every command should have:

- a one-line summary
- examples for non-trivial commands
- clear flag descriptions

### 4.3 Exit codes

- `0` success
- `>0` failure
- If “no results found” is not an error, still return `0` but print nothing (or a concise message if UX demands it).

## 5) Configuration rules (`settings.yml` and friends)

Treat configuration as contract:

- Validate user-provided config early.
- Provide clear errors pointing to the exact key/value that is invalid.
- Avoid silent fallbacks that surprise users.

If introducing new config keys:

- document them in `docs/`
- provide defaults
- ensure upgrades don’t break existing installs

## 6) Build / release conventions

Use the existing task runners:

- Prefer `just` targets over bespoke one-off commands. :contentReference[oaicite:4]{index=4}
- If adding a workflow, add it to `justfile` or `scripts/` rather than sprinkling ad-hoc scripts.

Release hygiene:

- Update changelog/release notes if the project has them.
- Ensure install steps remain correct.
- Keep generated artifacts out of git unless explicitly intended.

## 7) Documentation rules (`docs/`)

Any behavior visible to users must be documented:

- new commands or flags
- changed defaults
- new required dependencies
- new config keys

These are generated using bashly's documentation features, so update the source-of-truth CLI definitions accordingly, and then to update the docs run `just docs` as defined in the justfile, as well as github-pages pretty documentation with `just pages`

## 8) Smoke testing checklist (agent must do)

After changes, make sure to extend `test/approve` to smoke test the command you added/changed (this uses the approvals.bash framework). Also run a quick local check:

1. `lct --help` renders and includes your command/flag changes
2. `lct <command> --help` renders and examples make sense
3. Run the specific command(s) you changed with:
   - typical input
   - empty input / missing config
   - an error case (ensure good message + exit code)
4. Confirm output formatting is stable and not overly noisy

## 9) “When stuck” debugging playbook

If something fails:

- reproduce with the smallest possible command invocation
- add temporary debug logging guarded by a verbose flag
- confirm assumptions about environment (macOS tool variants, PATH, Homebrew, etc.)
- check for subshell / pipeline exit-code gotchas
- avoid “fixing” by weakening error handling unless justified

## 10) How to propose changes (planning format)

When asked to implement a feature/fix, respond with:

### Plan

- Summary of the change
- Files likely touched
- User-facing behavior impact
- Risks + mitigations

### Patch

- Implement minimal diff
- Update docs alongside code using `just docs`
- Update github-pages docs with `just pages` if applicable

### Verify

- List the exact commands you ran and what you observed

## 11) Avante.nvim integration note

If you’re working via avante.nvim:

- Avante will automatically include a root-level `avante.md` instruction file if present. :contentReference[oaicite:5]{index=5}
- Keep `agents.md` as the canonical long-form guide.
- Keep `avante.md` short and point to `agents.md` (or copy only the essentials).

## 12) Quick “avante.md” stub (recommended)

Create `avante.md` in repo root with:

> Use instructions from `agents.md` as the source of truth. If instructions conflict with repo reality, propose an update to `agents.md` before making sweeping changes.
