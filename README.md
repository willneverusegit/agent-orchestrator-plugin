# agent-orchestrator

Autonomous meta-agent orchestrator plugin for Claude Code.

Coordinates a team of specialized agents to solve complex tasks end-to-end:

1. **Research** — 5 Haiku brainstormers explore the problem space in parallel
2. **Planning** — NotebookLM RAG builds a knowledge base, strategic plan with quality criteria
3. **Execution** — Codex instances implement subtasks via codex-swarm
4. **Quality Gate** — Each result evaluated against criteria (9.0/10 threshold, up to 3 re-dispatches)
5. **Synthesis** — Results merged, 3-round self-critique (9.5/10 minimum)

## Install

```bash
claude plugin install https://github.com/willneverusegit/agent-orchestrator-plugin.git
```

## Usage

```
/agent-orchestrator
```

Then describe your complex task. The orchestrator handles the rest autonomously.

## Dependencies

- `multi-model-orchestrator` plugin (for codex-swarm)
- `notebooklm` user skill (Python API)
- `research-pipeline` skill
