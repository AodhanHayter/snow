In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## Coding Guidelines

### Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite.

Test: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical Changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

Test: Every changed line should trace directly to the user's request.

Exception: greenfield/prototype work — relax surgical constraint when no existing code to disturb.

### Goal-Driven Execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan with verification per step.

Strong success criteria enable independent looping. Weak criteria ("make it work") require constant clarification.

Skip the verify-loop when no test infrastructure exists (e.g., Nix config repos, pure documentation). Substitute with whatever check fits: `nix flake check`, manual run, type check.


### Autonomy

Within the task I gave you, keep going: fix, retry, and take the next in-scope step yourself. Commit locally as you finish each logical unit, staging only files you changed. Ask before outward-facing actions I haven't requested, such as push, publish, deploy, messaging other people, or irreversible deletes.

End any turn that reports on long-running or delegated work with a short status: **Goal**, **Done**, **Next**, **Needs you** (or "nothing").

### Shell

I use fish. When writing shell scripts intended for the user, use fish. For temporary stuff or stuff for your own use, you can use any shell you like, such as bash or zsh. If a project we're working already uses bash extensively, don't introduce fish.

The bash tool runs bash. Use fish syntax only inside `fish -c '…'`.

Run commands expected to take more than 2 minutes (builds, test suites, watchers, deploys) in the background with output to a log file, then check back, so I can steer you meanwhile.
