---
name: codex-computer-use
description: Ask Codex CLI (gpt-5.6) to run local app verification that needs computer use, browser automation, simulators, screenshots, app launching, or independent runtime inspection. This is how gpt-5.6 is invoked for computer-use work.
---

# Codex Computer Use

Use Codex as a separate local verification agent when the task needs real UI interaction, screenshots, simulator/browser/device state, or an independent runtime check outside Claude's current context.

Do not use this for ordinary code reading, typechecking, linting, or tests Claude can run directly. Launching apps, simulators, or browsers to verify the requested work is fine without asking; ask first only if the run could disrupt the user's environment i.e. closing their apps, changing system settings, acting on real accounts or data.

## Workflow

Codex is a **verifier**, not a collaborator. Every run hands it a contract — the end-state to confirm — and gets back a verdict with evidence. Three steps, in order.

### 1. Write the verification contract

Draft the prompt as a block-structured contract, not a chat request. Codex will not infer the desired end-state — state it. Include:

- `<task>` — what was built/changed and what "working" means for it.
- `<environment>` — exactly how to reach the running thing: launch command, simulator target, URL, build step. Do not make Codex guess how to start the app.
- `<verification>` — exercise the real UI and read the actual runtime state. Do not accept conclusions inferred from source code.
- `<evidence>` — save screenshots to a fresh temp dir (`mktemp -d`) and list their absolute paths in the report.
- `<output_contract>` — end the reply with a single line `VERDICT: PASS` or `VERDICT: FAIL`, one-line reason, then evidence paths.

Keep it one task per run. Split unrelated checks into separate runs.

### 2. Run Codex

```bash
codex exec \
  --model gpt-5.6-luna \
  -s danger-full-access \
  -C <repo-root> \
  "<contract prompt>" </dev/null
```

- `-s danger-full-access` — **required.** Computer-use spawns GUI processes and reaches the network; the `workspace-write` sandbox blocks both. This is why the skill's guardrail above governs disruptive runs.
- `-C <repo-root>` — sets Codex's working root. Add `--skip-git-repo-check` if the target is not a git repo.
- `--model` — `gpt-5.6-luna` is the default for this skill; override only if the user names a different model.
- `</dev/null` — **required.** `codex exec` in a non-TTY hangs on "Reading additional input from stdin..." unless stdin is closed.
- Codex's final message lands on stdout — the Bash result carries the verdict back. No output file needed.
- Long runs (booting a simulator, multi-step flows) can exceed a foreground call — run the Bash command in the background and poll.

### 3. Read the verdict and relay it

Scan Codex's stdout for the `VERDICT:` line. The step is **not** done until that line is present — a run with no verdict is an incomplete run, not a pass. Relay to the user: the verdict, the one-line reason, and the evidence paths. On `FAIL`, report what Codex observed; do not re-verify by reading code.

Exception: if stdout shows tool-spawn errors (e.g. `failed to spawn code-mode host`, or every tool call erroring), the Codex install itself is broken — stop, surface the error to the user, and do not retry or fall back to verifying by reading code.
