# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

Claude Code Plugin: **agent-orchestrator** — ein autonomer Meta-Agent-Orchestrator. Ein Opus-Agent der Haiku-Brainstormer, NotebookLM-RAG und Codex-Instanzen orchestriert um komplexe Aufgaben autonom zu loesen.

## Struktur (Variante-2 Layout, seit v1.1)

```
agent-orchestrator-plugin/
├── .claude-plugin/
│   ├── plugin.json         # Plugin-Manifest (name, version, description)
│   └── marketplace.json    # Marketplace-Metadaten fuer Distribution
├── skills/
│   └── agent-orchestrator/
│       └── SKILL.md        # Kern-Skill: 5-Phasen-Orchestrierung
├── .gitignore              # settings.local.json, .agent-memory/, stackdumps
├── CLAUDE.md               # diese Datei
├── README.md               # Install + Usage
└── tests/                  # (optional, Tranche C)
```

## Architektur

Der Skill orchestriert ein Multi-Agent-System in 5 Phasen:

1. **Research**: 5 Haiku-Brainstormer parallel (Agent tool, model: haiku), Ergebnisse in NotebookLM
2. **Planung**: RAG-Abfragen an NotebookLM, Subtask-Zerlegung mit MUSS/SOLLTE/DARF-NICHT Akzeptanzkriterien
3. **Execution**: Codex-Instanzen via `/multi-model-orchestrator:codex-swarm` (bis zu 5 parallel, Modelle: gpt-5-4 / gpt-5.4-mini / gpt-5.3-codex-spark)
4. **Quality Gate**: Binary Acceptance Check (nicht Score-basiert), Re-Dispatch bis 3x, dann Opus-Fallback
5. **Synthese**: Merge, finale Self-Critique (3 Runden Plateau-Check)

Skill-Abhaengigkeiten: `research-pipeline`, `notebooklm` (Python API, NICHT Chrome-MCP), `codex-swarm`, Agent tool.

## Konventionen

- **Sprache:** Deutsch fuer User-Kommunikation, Englisch fuer Trigger-Phrases in SKILL.md Frontmatter (Claude-Code-weite Konvention, vermeidet Diskriminierung deutscher Installs durch Tests anderer Plugins)
- **NotebookLM:** IMMER den Python-basierten User-Skill nutzen, nie die Chrome-MCP Plugin-Varianten (Plugin wurde 2026-04-24 archiviert)
- **Self-Critique:** Plateau-basiert statt Score-basiert. Entweder du kannst 3 konkrete Verbesserungen nennen (noch nicht fertig) oder nicht (fertig). "9.5/10" ohne konkrete Begruendung ist Schoenbewertung.
- **Codex-Modelle (Stand 2026-04):** gpt-5-4 (default/komplex), gpt-5.4-mini (standard), gpt-5.3-codex-spark (einfach). Alte 5.3/5.2/5.1 Nomenklatur ist ueberholt.
- **Version-Bump-Regel:** Jede Aenderung am Skill oder Manifest benoetigt Version-Bump in `.claude-plugin/plugin.json`, sonst sieht `claude plugin update` die Aenderung nicht.

## Install (fuer Entwicklung)

```bash
# Ein-Mal: Marketplace registrieren
claude plugin marketplace add willneverusegit/agent-orchestrator-plugin

# Plugin installieren (user scope typisch)
claude plugin install agent-orchestrator@agent-orchestrator-marketplace --scope user

# Nach Aenderungen + Version-Bump + Push:
claude plugin update agent-orchestrator@agent-orchestrator-marketplace
```
