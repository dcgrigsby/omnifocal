# AGENTS

## Project Overview

This repository builds **OmniFocal** — a bridge that allows NanoClaw agents to read from OmniFocus on macOS. It is orchestrated via **Kilroy** and the **Attractor** pattern as a software factory.

Authoritative references:

- Kilroy implementation: `https://github.com/danshapiro/kilroy`
- Attractor NL spec: `https://github.com/strongdm/attractor`
- NanoClaw: `https://github.com/qwibitai/nanoclaw`

**Intent:** This repo uses Attractor **as a software factory**. Pipelines are engineering pipelines that design, build, and verify the product components.

## Product Architecture

OmniFocal has two components:

1. **omnifocal-server** (Go) — A lightweight HTTP daemon running on the Mac host via launchd. Single POST `/eval` endpoint accepts arbitrary OmniFocus JavaScript (Omni Automation), executes it via `osascript`, and returns the result. The server is intentionally minimal — it is an execution proxy, not an API.

2. **omnifocal-skill** (NanoClaw skill, markdown) — Teaches the NanoClaw agent how to compose OmniFocus JavaScript queries and call the server. Contains the OmniFocus API reference, query composition patterns, and read-only constraint. All intelligence about what to query lives here, not in the server.

**Transport:** Plain HTTP. JS string in the request body, result string (typically JSON via `JSON.stringify()`) in the response body.

**Network:** NanoClaw runs in Apple Containers. The server listens on the Mac host and is reached from the container via the container networking mechanism.

**Read-only constraint:** Enforced at the skill level (instructions tell the agent to compose only read queries). No server-side blocking.

## How Agents Should Think About This Repo

- **Attractor-first, product-factory mindset**
  - Think of Attractor graphs as **product-building assembly lines**.
  - Prefer designing and evolving **Attractor pipelines that create and refine the components** instead of one-off edits.

- **Multi-language, stage-based design**
  - Go for the server (simple, fast, single binary).
  - TypeScript/Node for the NanoClaw skill (consistency with NanoClaw's own stack).
  - Do not force a single-language solution.

- **Two pipelines, one repo**
  - The server and the skill are independent components with separate Attractor pipelines.
  - Pipeline ordering matters: the server must be built and running before the skill can be tested.

## How To Use Skills In This Repo

This repo includes local skills (under `skills/`) that are **meta-workflow helpers around Attractor/Kilroy**:

- **Before/around pipelines (design & ops)**
  - Use `skills/starting-a-project` to structure the target repo for Attractor.
  - Use `skills/build-dod` to turn specs/requirements into a Definition of Done.
  - Use `skills/create-dotfile` to convert requirements + DoD into a DOT pipeline graph.
  - Use `skills/create-runfile` to author `run.yaml` for Kilroy.
  - Use `skills/using-kilroy` to run, validate, and resume pipelines.
  - Use `skills/investigating-kilroy-runs` to inspect CXDB artifacts and debug runs.

- **Inside Attractor nodes (execution phase)**
  - Attractor nodes are executed by the **coding-agent loop implemented by Kilroy**, not by Claude Code.
  - Node prompts may reference skill files so the coding agent follows them during execution.

## Operating Model

Work flows through three phases. **The product is always built by Kilroy.** Never use superpowers execution skills to implement product features directly.

### Phase 1 — Requirements (Claude Code, superpowers)

Understand what to build and make product decisions.

- Use `brainstorming` (superpowers) to explore product intent with the human -> produces spec / requirements doc

### Phase 2 — Factory Design (Claude Code, Kilroy design skills)

Translate requirements into a runnable pipeline.

- `skills/build-dod` -> spec -> acceptance criteria + integration test scenarios
- `skills/create-dotfile` -> requirements + DoD -> pipeline DOT graph
- `skills/create-runfile` -> DOT graph -> `run.yaml` config
- `skills/starting-a-project` -> initialize target repo if needed

### Phase 3 — Factory Execution (Kilroy runner)

Run the pipeline. Failures feed back to Phase 2.

- `skills/using-kilroy` -> validate + run pipeline
- `skills/investigating-kilroy-runs` -> diagnose failures; repair DOT/runfile and re-run

### Superpowers Skill Boundaries

| Skill | Use in this repo | Never use for |
|---|---|---|
| `brainstorming` | Phase 1 — product intent and decisions | — |
| `writing-plans` | Phases 1-2 — planning DOT/runfile/skill changes | Planning product features for direct Claude Code execution |
| `executing-plans` | Phases 1-2 — factory meta-work only (repo setup, repairing DOT) | Product implementation |
| `subagent-driven-development` | Phases 1-2 — factory meta-work only | Product implementation |
| `dispatching-parallel-agents` | Phases 1-2 — parallel factory ops | Product feature work |
| `test-driven-development` | Phases 1-2 — factory/infra code only | Product code (Kilroy's DoD handles this) |
| `systematic-debugging` | Any phase — debugging pipeline setup | — |
| `verification-before-completion` | Phase 2->3 — verifying pipeline setup before a run | — |
| `using-git-worktrees` | Any phase — isolating factory changes | — |

## Skill Testing Strategy

The omnifocal-skill (NanoClaw skill) has a unique testing requirement: it must be tested by running it inside Claude Code, not by API calls. The skill pipeline's verification node launches Claude Code CLI in a prepared project directory with the skill installed, gives it test prompts against a running omnifocal-server, and verifies the results.

## Model Assignments

Following the weather report and NEXRAD precedent:

| Role | Model | Provider |
|---|---|---|
| Implementation (default) | gpt-5.3-codex | OpenAI |
| QA / DevOps | claude-opus-4.6 | Anthropic |
| Architectural critique | gpt-5.4 | OpenAI |

## Session Handoff and Run Monitoring

Long-running Kilroy pipelines span multiple Claude Code sessions. Use this pattern to hand off cleanly and stay informed without manual polling.

### Handoff prompt (end of session)

```
**Handoff: <one-line intent>**
**What to do:**
  <exact shell command to resume or launch>
**Existing implementation (already merged):**
  <key files and what they do>
**How the graph works:**
  <routing logic — especially any detect/skip shortcuts>
**Key config details:**
  <env loading, model choices, any known gotchas>
**Reference docs:**
  <paths to spec, DoD, design docs>
```

### Scheduled run monitoring

Create a scheduled task (via `anthropic-skills:schedule`) immediately after launching a detached run:

- **Frequency:** 5 minutes default; 10 minutes for low-risk runs.
- **Prompt must include:** run ID, logs root, repo path, expected graph stage sequence.
- **Auto-disable:** task prompt should instruct the agent to note when the run reaches a final state.
- **Failure action:** surface `failure_reason` from `status.json` and suggest whether to resume or investigate.

Output appears in the **Scheduled** section of the Claude Code sidebar, not in the active chat session.

## Agent Behavior and Safety

- **Bias for clarity over cleverness** — explain trade-offs briefly when making non-obvious decisions.
- **Respect existing configuration & skills** — treat `AGENTS.md`, `skills/**`, and `CLAUDE.md` as authoritative guidance.
- **Testing and verification** — be explicit about inputs/outputs, expected artifacts, and how success/failure is detected.

## Expectations for AI Assistants

Both Claude Code and GPT-based agents should:
- Read and follow this `AGENTS.md` at the start of any substantial task.
- Honor the Attractor-first, multi-language, stage-based, product-factory design.
- Avoid hard-coding assumptions about single-language solutions.

If behavior needs to change, update this file rather than scattering instructions across many places.
