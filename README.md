# agent-orchestrator

Autonomous meta-agent orchestrator plugin for Claude Code.

Coordinates a team of specialized agents to solve complex tasks end-to-end:

1. **Research** — 5 Haiku brainstormers explore the problem space in parallel
2. **Planning** — NotebookLM RAG builds a knowledge base; strategic plan with quality criteria
3. **Execution** — Codex instances implement subtasks via `codex-swarm`
4. **Quality Gate** — each result evaluated against criteria (accept / re-dispatch up to 3x / Opus fallback)
5. **Synthesis** — results merged, 3-round self-critique produces the deliverable

## Install

```bash
# One-time: register the marketplace
claude plugin marketplace add willneverusegit/agent-orchestrator-plugin

# Install the plugin (user scope is typical for personal tooling)
claude plugin install agent-orchestrator@agent-orchestrator-marketplace --scope user
```

Verify:

```bash
claude plugin marketplace list
# → should list "agent-orchestrator-marketplace"
```

## Usage

Invoke the skill by name or via trigger phrases. In Claude Code:

```
Nutze den agent-orchestrator Skill für folgende Aufgabe: …
```

Or drop any of the trigger phrases in a message — the skill will activate:

> "orchestriere das", "grosses Projekt", "full auto", "lass die Agents los",
> "ich brauch ein Team dafuer", "recherchiere und baue", "mach das komplett autonom"

Then describe your goal. The orchestrator runs all 5 phases autonomously.

## When This Is (And Isn't) The Right Tool

**Use it when:**

- A task needs real research + planning + implementation (not just one of these)
- You want multiple perspectives (analytic, creative, critical) on a problem
- The task is too large for a single agent pass
- You want a polished deliverable, not a quick answer

**Skip it when:**

- Quick fix / one-line answer / single file edit — overkill
- You already know the solution and just need it typed
- The research phase would not add value (e.g. "format this JSON")

## Dependencies

The orchestrator invokes these at runtime and degrades gracefully if they are missing:

| Dep | Purpose | Fallback |
|-----|---------|----------|
| `multi-model-orchestrator` plugin (`codex-swarm` skill) | Codex execution swarm in Phase 3 | Agent tool with model: sonnet |
| `notebooklm` user-skill (Python API) | Knowledge base + RAG in Phase 1+2 | Inline context kept locally |
| `research-pipeline` skill | Web research in Phase 1 | WebSearch direct |
| Agent tool (built-in) | Haiku brainstormers in Phase 1 | — (required) |

> **Important:** use the `notebooklm` *user-skill* (notebooklm-py, Python API), **not** the
> deprecated notebooklm Chrome-MCP plugin. The plugin was archived 2026-04-24.

## Quality Standards

- Research phase: iterate until blind spots closed (min 3 refinement rounds)
- Planning phase: each subtask must have measurable acceptance criteria
- Quality gate: configurable threshold, default 9.0/10 with 3 re-dispatches, then Opus fallback
- Synthesis: 3-round self-critique before presenting to user

## License

MIT — see `LICENSE` if present.
