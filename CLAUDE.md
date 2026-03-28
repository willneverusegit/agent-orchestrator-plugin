# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

Claude Code Plugin: **agent-orchestrator** — ein autonomer Meta-Agent-Orchestrator. Ein Opus 4.6 Agent der Haiku-Brainstormer, NotebookLM-RAG und Codex-Instanzen orchestriert um komplexe Aufgaben autonom zu loesen.

## Struktur

- `plugin.json` — Plugin-Manifest, registriert den einzigen Skill
- `skills/agent-orchestrator/SKILL.md` — Kern-Skill: 5-Phasen-Orchestrierung (Research → Planung → Execution → Quality Gate → Synthese)
- `marketplace.json` — Marketplace-Metadaten fuer Plugin-Distribution

## Architektur

Der Skill orchestriert ein Multi-Agent-System in 5 Phasen:

1. **Research**: 5 Haiku-Brainstormer parallel (Agent tool, model: haiku), Ergebnisse in NotebookLM
2. **Planung**: RAG-Abfragen an NotebookLM, Subtask-Zerlegung mit Qualitaetskriterien
3. **Execution**: Codex-Instanzen via `/multi-model-orchestrator:codex-swarm` (bis zu 5 parallel)
4. **Quality Gate**: Bewertung >= 9.0/10, Re-Dispatch bis 3x, dann Opus-Fallback
5. **Synthese**: Merge, finale Self-Critique (3 Runden, >= 9.5/10)

Skill-Abhaengigkeiten: `research-pipeline`, `notebooklm` (Python API, NICHT Chrome-MCP), `codex-swarm`, Agent tool.

## Konventionen

- Sprache: Deutsch fuer Kommunikation, Englisch fuer Code/Dateinamen
- NotebookLM: IMMER den Python-basierten User-Skill nutzen, nie die Chrome-MCP Plugin-Varianten
- Self-Critique: Minimum 3 Runden pro Phase, Schwelle 9.5/10
- CLAUDE.md bei jedem relevanten Learning sofort aktualisieren
