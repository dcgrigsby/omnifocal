# OmniFocal — Definition of Done

## Scope

### In Scope

- Go HTTP server (`omnifocal-server`) that proxies OmniFocus JavaScript evaluation via `osascript`
- `launchd` plist for auto-start and crash recovery
- NanoClaw container skill (`omnifocal-skill/SKILL.md`) teaching agents to compose read-only OmniFocus queries and call the server

### Out of Scope

- Write/update/delete operations against OmniFocus (future — skill update only)
- Authentication or TLS on the server (local-only proxy)
- Server-side query validation or blocking of mutating JS
- Multiple OmniFocus database support
- Container image changes or NanoClaw core modifications

### Assumptions

- macOS host with OmniFocus 4 installed and running
- Go toolchain available (`go` in PATH)
- `osascript` available at `/usr/bin/osascript`
- OmniFocus grants Omni Automation access when invoked via `osascript`
- NanoClaw agents reach the host on `192.168.64.0/24` vmnet subnet (Apple Container networking)
- Claude Code CLI available for skill end-to-end testing

## Deliverables

| Artifact | Location | Description |
|----------|----------|-------------|
| `omnifocal-server` | `cmd/omnifocal-server/` (source); compiled binary | Go HTTP server: POST `/eval` executes JS via osascript, GET `/health` returns 200 |
| `com.omnifocal.server.plist` | `launchd/com.omnifocal.server.plist` | launchd plist for auto-start on login, restart on crash |
| `omnifocal-skill/SKILL.md` | `skills/omnifocal/SKILL.md` | NanoClaw container skill teaching agents OmniFocus query composition and server communication |

## Acceptance Criteria

### Build

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-1.1 | `go build ./cmd/omnifocal-server` exits 0 and produces a single executable binary | IT-1 |
| AC-1.2 | The binary starts and listens on the configured address/port (default `0.0.0.0:7890`) | IT-1 |

### Server /eval Endpoint

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-2.1 | POST `/eval` with a valid OmniFocus JS string returns 200 with the `osascript` stdout as the response body | IT-2 |
| AC-2.2 | POST `/eval` with a valid OmniFocus JS string returns Content-Type `text/plain` | IT-2 |
| AC-2.3 | POST `/eval` with invalid JS returns 500 with the `osascript` stderr as the response body | IT-3 |
| AC-2.4 | POST `/eval` with an empty body returns a non-200 status with an error message | IT-3 |

### Server /health Endpoint

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-3.1 | GET `/health` returns HTTP 200 | IT-4 |

### launchd Plist

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-4.1 | The plist file is valid XML per `plutil -lint` | IT-5 |
| AC-4.2 | The plist `ProgramArguments` key contains the correct binary path | IT-5 |
| AC-4.3 | The plist `KeepAlive` key is set to `true` (restart on crash) | IT-5 |

### Skill Structure

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-5.1 | `skills/omnifocal/SKILL.md` exists and contains valid YAML frontmatter with `name` and `description` fields | IT-6 |
| AC-5.2 | The `name` field is lowercase, alphanumeric + hyphens, max 64 chars | IT-6 |
| AC-5.3 | The SKILL.md is under 500 lines | IT-6 |

### Skill Read-Only Enforcement

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-6.1 | The skill instructions do not contain mutating API patterns: `new Task(`, `new Project(`, `.save()`, `markComplete(`, `remove`, property assignment to OmniFocus objects | IT-6 |
| AC-6.2 | The skill explicitly instructs agents to use only read accessors and to never assign properties, call constructors, or invoke mutating methods | IT-6 |

### Skill Query Composition

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-7.1 | The skill contains query composition patterns with examples for at least: listing inbox tasks, searching tasks, getting project hierarchy, and listing tags | IT-6, IT-7 |
| AC-7.2 | The skill instructs agents to wrap results in `JSON.stringify()` | IT-6 |
| AC-7.3 | The skill instructs agents to POST composed JS to the server `/eval` endpoint | IT-6 |

### Integration

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-8.1 | An agent with the skill installed can compose valid OmniFocus JS from a natural language query, send it to the running server via POST `/eval`, and receive valid OmniFocus data back as JSON | IT-7 |

## User-Facing Message Inventory

| ID | Message surface | Trigger condition | Covered by |
|----|----------------|-------------------|------------|
| MSG-1 | Server 200 response body on `/eval` success | Valid JS submitted, osascript succeeds | IT-2 |
| MSG-2 | Server 500 response body on `/eval` error | Invalid JS or osascript failure | IT-3 |
| MSG-3 | Server 200 empty response on `/health` | GET `/health` requested | IT-4 |
| MSG-4 | Server startup log (listening address/port) | Server binary starts | IT-1 |

## Test Evidence Contract

| Item | Requirement |
|------|-------------|
| Evidence root | `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/` |
| Scenario folder pattern | `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/IT-<id>/` |
| Manifest | `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/manifest.json` |
| UI scenarios (`surface=ui` or `surface=mixed`) | Include screenshot evidence proving key states |
| Non-UI scenarios (`surface=non_ui`) | Include text/structured evidence (log/stdout/json) |
| Failure behavior | Emit best-effort artifacts and manifest entry; record missing artifacts explicitly |

## Integration Test Scenarios

| ID | Scenario | Steps | Verification | Evidence Artifacts |
|----|----------|-------|--------------|--------------------|
| IT-1 | Server build and start | 1. Run `go build ./cmd/omnifocal-server` → exits 0, binary exists 2. Start binary → process listens on port 7890 3. Capture stdout → contains listening address/port message | `go build` exits 0; `lsof -i :7890` shows process; stdout contains listening message | `surface=non_ui`; `log:IT-1/build.log`, `log:IT-1/startup.log` |
| IT-2 | Server eval happy path | 1. Start omnifocal-server 2. POST `/eval` with body `JSON.stringify(inbox.length)` → 200 response 3. Response body is a valid number string 4. POST `/eval` with body `JSON.stringify(flattenedProjects.map(p => p.name))` → 200 response 5. Response body is a valid JSON array of strings | HTTP 200 on both requests; response bodies parse as valid JSON; Content-Type is `text/plain` | `surface=non_ui`; `log:IT-2/curl-inbox.log`, `log:IT-2/curl-projects.log` |
| IT-3 | Server eval error handling | 1. Start omnifocal-server 2. POST `/eval` with body `this is not valid javascript !!!` → 500 response 3. Response body contains error message text 4. POST `/eval` with empty body → non-200 response 5. Response body contains error message text | HTTP 500 on invalid JS; non-200 on empty body; response bodies are non-empty error strings | `surface=non_ui`; `log:IT-3/curl-invalid-js.log`, `log:IT-3/curl-empty-body.log` |
| IT-4 | Server health check | 1. Start omnifocal-server 2. GET `/health` → 200 response | HTTP 200 status code | `surface=non_ui`; `log:IT-4/curl-health.log` |
| IT-5 | launchd plist validation | 1. Run `plutil -lint launchd/com.omnifocal.server.plist` → exits 0, output contains "OK" 2. Parse plist XML: `ProgramArguments` array contains expected binary path 3. Parse plist XML: `KeepAlive` is `true` | `plutil` exits 0; ProgramArguments and KeepAlive values are correct | `surface=non_ui`; `log:IT-5/plutil.log`, `json:IT-5/plist-parsed.json` |
| IT-6 | Skill structure validation | 1. Verify `skills/omnifocal/SKILL.md` exists 2. Parse YAML frontmatter: `name` is present, lowercase alphanumeric+hyphens, max 64 chars 3. Parse YAML frontmatter: `description` is present and non-empty 4. Count lines: file is under 500 lines 5. Grep for mutating patterns (`new Task(`, `new Project(`, `.save()`, `markComplete(`, `remove`): zero matches in example code blocks 6. Grep for read-only enforcement instruction text: present 7. Grep for query patterns: inbox, tasks search, project hierarchy, tags examples present 8. Grep for `JSON.stringify` in examples: present 9. Grep for POST `/eval` instruction: present | All checks pass; no mutating patterns in code examples; required instruction sections present | `surface=non_ui`; `log:IT-6/frontmatter.json`, `log:IT-6/structure-checks.log` |
| IT-7 | Skill end-to-end via Claude Code | 1. Start omnifocal-server, verify listening on port 7890 2. Set up a temp directory with `.claude/skills/omnifocal/SKILL.md` installed 3. Launch Claude Code CLI in that directory with the prompt "List my OmniFocus inbox tasks as JSON" 4. Claude Code composes JS query using skill instructions and POSTs to server `/eval` 5. Verify Claude Code received a valid JSON response containing OmniFocus task data | Claude Code exits 0; output contains valid JSON with OmniFocus data; server access log shows POST `/eval` was called | `surface=non_ui`; `log:IT-7/claude-code-output.log`, `log:IT-7/server-access.log` |

## Crosscheck

### Per Scenario

| ID | Exercises delivered artifact? | Automatable? | Bounded? | Proportional? | Independent? | Crosses AC groups? | Evidence defined? |
|----|-------------------------------|-------------|----------|---------------|-------------|-------------------|------------------|
| IT-1 | Yes (binary) | Yes | Yes (3 steps) | Yes | Yes | Build | Yes |
| IT-2 | Yes (running server) | Yes | Yes (5 steps) | Yes | Yes | Build, /eval | Yes |
| IT-3 | Yes (running server) | Yes | Yes (5 steps) | Yes | Yes | /eval | Yes |
| IT-4 | Yes (running server) | Yes | Yes (2 steps) | Yes | Yes | /health | Yes |
| IT-5 | Yes (plist file) | Yes | Yes (3 steps) | Yes | Yes | launchd | Yes |
| IT-6 | Yes (SKILL.md file) | Yes | Yes (9 steps) | Yes | Yes | Skill structure, read-only, query composition | Yes |
| IT-7 | Yes (skill + server together) | Yes | Yes (5 steps) | Yes | Yes | Build, /eval, integration, skill query composition | Yes |

### Per AC

| AC | Covered by scenario? |
|----|---------------------|
| AC-1.1 | IT-1 |
| AC-1.2 | IT-1 |
| AC-2.1 | IT-2 |
| AC-2.2 | IT-2 |
| AC-2.3 | IT-3 |
| AC-2.4 | IT-3 |
| AC-3.1 | IT-4 |
| AC-4.1 | IT-5 |
| AC-4.2 | IT-5 |
| AC-4.3 | IT-5 |
| AC-5.1 | IT-6 |
| AC-5.2 | IT-6 |
| AC-5.3 | IT-6 |
| AC-6.1 | IT-6 |
| AC-6.2 | IT-6 |
| AC-7.1 | IT-6, IT-7 |
| AC-7.2 | IT-6 |
| AC-7.3 | IT-6 |
| AC-8.1 | IT-7 |

### Per Message

| MSG | Covered by scenario? |
|-----|---------------------|
| MSG-1 | IT-2 |
| MSG-2 | IT-3 |
| MSG-3 | IT-4 |
| MSG-4 | IT-1 |

### Overall

- At least one scenario tests each deliverable in its delivery form: IT-1/IT-2 (server binary), IT-5 (plist), IT-6 (SKILL.md), IT-7 (full integration)
- Every user-facing message is triggered and validated by at least one scenario
- All AC groups (Build, /eval, /health, launchd, Skill structure, Skill read-only, Skill query composition, Integration) are covered
- All scenarios define evidence artifact paths under `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/IT-<id>/`
- No digraph was provided; flow coverage is derived from the architecture diagram in the design doc
