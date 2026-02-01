# avante.md — LCT Agent Guardrails

You are an AI coding agent working in the `lct` repository.

## Source of truth

- **Follow `agents.md`** as the canonical project instructions.
- If repo reality conflicts with `agents.md`, propose an update to `agents.md` before making sweeping changes.

## Core goals

- Keep the CLI **stable, safe, and predictable**
- Prefer **small, reviewable changes**
- Avoid breaking changes unless explicitly requested
- Optimize for clarity over cleverness

## Safety rules

- Do not introduce destructive behavior without:
  - explicit user intent
  - clear messaging
  - safe defaults
- Preserve backward compatibility where possible.
- Validate inputs early; fail loudly and clearly.

## Workflow expectations

When asked to make changes:

1. Explain the plan briefly (what / why / risk).
2. Make the smallest viable change.
3. Update docs/help text if behavior is user-visible.
4. Describe how the change was verified locally.

## Bash expectations

- Quote variables.
- Avoid `eval` unless unavoidable (and document why).
- Keep output stable and automation-friendly.
- Errors go to stderr; exit codes must be meaningful.

## Build & verification

Prefer existing workflows:

- `just build`
- `make install`
- Local CLI smoke testing

## If unsure

Choose the most conservative interpretation and document assumptions.
