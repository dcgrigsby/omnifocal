# OmniFocal Design

## Purpose

OmniFocal bridges NanoClaw agents to OmniFocus on macOS, enabling read-only access to tasks, projects, folders, tags, and perspectives. It consists of a thin execution proxy on the Mac host and a NanoClaw skill that teaches agents how to compose and execute OmniFocus JavaScript queries.

## Architecture

```
NanoClaw Agent (Apple Container, 192.168.64.0/24 vmnet)
    |
    |  HTTP POST /eval  (body: JS string)
    |
    v
omnifocal-server (Go, launchd daemon on Mac host, port 7890)
    |
    |  osascript -l JavaScript -e 'Application("OmniFocus").evaluate({ ... })'
    |
    v
OmniFocus.app (Omni Automation / JavaScript)
    |
    |  JSON string result
    |
    v
(back up the chain)
```

## Component 1: omnifocal-server (Go)

### Responsibilities

- Listen on a configurable address/port (default `0.0.0.0:7890`)
- Accept POST requests to `/eval` with a JS string body
- Execute the JS via `osascript` against OmniFocus
- Return the result (stdout) as the response body
- Return errors (stderr, non-zero exit) as non-200 responses

### Design Decisions

- **Go**: single binary, no runtime dependencies, trivial cross-compile, fast startup
- **osascript invocation**: `osascript -l JavaScript -e '<script>'` where the script calls OmniFocus's `evaluate` function
- **No routing, no middleware, no auth**: this is a local-only proxy. Security comes from binding to the host and network isolation.
- **launchd**: plist for auto-start on login, restart on crash

### Interface

```
POST /eval
Content-Type: text/plain

<JavaScript string>

---

200 OK
Content-Type: text/plain

<result from osascript stdout>

---

500 Internal Server Error
Content-Type: text/plain

<error message from osascript stderr>
```

### Health Check

```
GET /health

200 OK
```

## Component 2: omnifocal-skill (NanoClaw Skill)

### Responsibilities

- Teach the NanoClaw agent the OmniFocus Omni Automation API surface
- Provide query composition patterns for common operations (list inbox, search tasks, get project hierarchy, etc.)
- Enforce read-only constraint via instructions (no `save()`, no property assignments, no `Task()` constructor calls)
- Handle HTTP communication with the omnifocal-server

### Skill Structure

Following NanoClaw's skill format:

```
skills/omnifocal/
  SKILL.md          # Skill definition with YAML frontmatter
```

The skill markdown contains:
- OmniFocus API reference (key classes, properties, methods relevant to reading)
- Query composition patterns with examples
- Read-only guardrails
- Server communication instructions (POST to configured URL)

### Read-Only Constraint

Enforced at the skill level via instructions. The skill tells the agent:
- Use only read accessors (`.name`, `.tasks`, `.flattenedTasks`, etc.)
- Never assign properties, call constructors, or invoke mutating methods
- Always return results via `JSON.stringify()`

This is a deliberate choice: the server stays generic and reusable, and when we later want write access, we update the skill instructions without touching the server.

## Network: Apple Containers to Host

NanoClaw runs agents in Apple Containers on the `192.168.64.0/24` vmnet subnet. The omnifocal-server binds to `0.0.0.0:7890` on the host, making it reachable from the container at the host's IP on that subnet (or via configured routing).

The skill is configured with the server URL via environment variable or NanoClaw configuration, pointing to the host IP and port.

## Testing Strategy

### Server Testing (real OmniFocus)

Standard integration tests: start the server, send JS payloads, verify OmniFocus responds correctly. Tested by Kilroy's verification nodes via API calls.

### Skill Testing (Claude Code CLI)

The skill's verification node in the Kilroy pipeline launches Claude Code CLI in a prepared directory with the skill installed in `.claude/` config. The node gives Claude Code test prompts ("list my inbox", "show projects", "find overdue tasks"), and Claude Code — with the skill active — composes JS and calls the running server. The node verifies valid responses came back.

This is the only place in the pipeline where Claude Code CLI is used. All other nodes use LLM API calls.

## Kilroy Pipeline Structure

Two Attractor pipelines in one repo:

### Pipeline 1: omnifocal-server
- Bootstrap: check Go toolchain
- Implementation: build Go server + launchd plist
- Verification: start server, send test queries, verify results
- Review: code quality, error handling

### Pipeline 2: omnifocal-skill
- Prerequisite: server from Pipeline 1 must be built and running
- Implementation: compose skill markdown with API reference and patterns
- Verification: launch Claude Code CLI with skill installed, run test prompts against live server
- Review: skill clarity, query coverage, read-only enforcement

### Model Assignments

| Role | Model | Provider |
|---|---|---|
| Implementation (default) | gpt-5.3-codex | OpenAI |
| QA / DevOps | claude-opus-4.6 | Anthropic |
| Architectural critique | gpt-5.4 | OpenAI |

## Reference Specs

- `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md` — Complete OmniFocus JavaScript API surface
- `docs/specs/NANOCLAW-REFERENCE.md` — NanoClaw architecture, skill format, container networking

## Out of Scope (v1)

- Write/update/delete operations (future — skill update only, no server changes)
- Authentication or TLS on the server (local-only proxy)
- Server-side query validation or blocking
- Multiple OmniFocus databases
