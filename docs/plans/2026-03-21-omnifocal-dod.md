# OmniFocal -- Definition of Done

## Scope

### In Scope

- Go HTTP server (`omnifocal-server`) that proxies OmniFocus JavaScript evaluation via `osascript`
- launchd plist for auto-start and crash recovery
- NanoClaw container skill teaching agents to compose read-only OmniFocus queries and call the server

### Out of Scope

- Write/update/delete operations against OmniFocus
- Authentication or TLS on the server
- Server-side query validation or blocking
- Multiple OmniFocus databases
- Kilroy pipeline definitions (separate concern)

### Assumptions

- macOS host with OmniFocus installed and Omni Automation enabled
- Go toolchain available (`go build`)
- `osascript` available at `/usr/bin/osascript`
- OmniFocus contains at least one task or project (for integration tests)
- Claude Code CLI installed and on PATH (for IT-7)
- Port 7890 is available on the host

## Deliverables

| Artifact | Location | Description |
|----------|----------|-------------|
| `omnifocal-server` binary | `cmd/omnifocal-server/` (source); built binary in working directory | Go HTTP server accepting POST /eval and GET /health |
| launchd plist | `launchd/com.omnifocal.server.plist` | launchd service definition for auto-start and KeepAlive |
| OmniFocal skill | `skills/omnifocal/SKILL.md` | NanoClaw container skill for read-only OmniFocus queries |

## Acceptance Criteria

### AC-1: Server Build

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-1.1 | `go build ./cmd/omnifocal-server/` exits 0 and produces a binary | IT-1 |
| AC-1.2 | Binary starts and listens on port 7890 (default) | IT-1 |
| AC-1.3 | Binary responds to GET /health with HTTP 200 | IT-1, IT-4 |

### AC-2: Server /eval Endpoint

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-2.1 | POST /eval with valid OmniFocus JS returns HTTP 200 | IT-2 |
| AC-2.2 | Response Content-Type is text/plain | IT-2 |
| AC-2.3 | Response body contains the osascript stdout result | IT-2 |
| AC-2.4 | POST /eval with invalid JS returns HTTP 500 | IT-3 |
| AC-2.5 | 500 response body contains osascript stderr error text | IT-3 |
| AC-2.6 | POST /eval with empty body returns HTTP 400 | IT-3 |

### AC-3: Server /health Endpoint

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-3.1 | GET /health returns HTTP 200 | IT-1, IT-4 |

### AC-4: launchd Plist

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-4.1 | Plist file is valid XML per `plutil -lint` | IT-5 |
| AC-4.2 | ProgramArguments references the omnifocal-server binary | IT-5 |
| AC-4.3 | KeepAlive is set to true | IT-5 |

### AC-5: Skill Structure

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-5.1 | `skills/omnifocal/SKILL.md` exists | IT-6 |
| AC-5.2 | SKILL.md has valid YAML frontmatter with `name` and `description` | IT-6 |
| AC-5.3 | SKILL.md is under 500 lines | IT-6 |

### AC-6: Skill Read-Only Enforcement

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-6.1 | SKILL.md does not contain mutating patterns: `save()`, `.name =`, `new Task`, `new Project`, `new Folder`, `new Tag` | IT-6 |
| AC-6.2 | SKILL.md contains explicit read-only instruction text (the word "read-only" or "never assign" or "never mutate") | IT-6 |

### AC-7: Skill Query Composition

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-7.1 | SKILL.md contains at least one OmniFocus query example pattern (e.g., `flattenedTasks`, `flattenedProjects`) | IT-6 |
| AC-7.2 | SKILL.md references `JSON.stringify` for result serialization | IT-6 |
| AC-7.3 | SKILL.md contains POST instruction for calling the server | IT-6 |

### AC-8: Integration (Agent Round Trip)

| ID | Criterion | Covered by |
|----|-----------|------------|
| AC-8.1 | Claude Code CLI with the skill installed can compose a valid OmniFocus query | IT-7 |
| AC-8.2 | The query executes against the running server and returns real OmniFocus data | IT-7 |

## User-Facing Message Inventory

| ID | Message surface | Trigger condition | Covered by |
|----|----------------|-------------------|------------|
| MSG-1 | HTTP 200 response with osascript stdout | Valid JS POST to /eval | IT-2 |
| MSG-2 | HTTP 500 response with osascript stderr error text | Invalid JS POST to /eval | IT-3 |
| MSG-3 | HTTP 400 response | Empty body POST to /eval | IT-3 |
| MSG-4 | HTTP 200 response (health check) | GET /health | IT-1, IT-4 |

## Test Evidence Contract

| Item | Requirement |
|------|-------------|
| Evidence root | `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/` |
| Scenario folder pattern | `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/IT-<id>/` |
| Manifest | `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/manifest.json` |
| All scenarios | `surface=non_ui`; include text/structured evidence (log, stdout, JSON) |
| Failure behavior | Emit best-effort artifacts and manifest entry; record missing artifacts explicitly |

### Self-Verification Requirement

Every test script MUST include a self-verification block before exiting 0. The block verifies:

1. `manifest.json` exists at the evidence root
2. `manifest.json` contains entries for every IT-* scenario that was executed
3. Every evidence artifact file listed in the manifest exists and is non-empty
4. Evidence content assertions pass (see per-scenario requirements below)

A script that exits 0 without producing real evidence is a false positive. The self-verification block MUST fail the script (exit non-zero) if any of these checks fail.

### Evidence Content Assertions (Per Scenario)

| Scenario | Artifact | Content Assertion |
|----------|----------|-------------------|
| IT-1 | `health_response.txt` | Contains HTTP status 200 (e.g., the string `200` or `OK`) |
| IT-2 | `response.txt` | Contains parseable JSON with at least one recognizable OmniFocus field (e.g., a key like `name`, `id`, `taskStatus`, or an array of objects with `name` properties). Must NOT be empty, `"null"`, `"undefined"`, or placeholder text. |
| IT-3 | `error_500_response.txt` | Contains osascript error text (e.g., the string `Error` or `execution error` or stderr output from osascript). Must NOT be empty or generic. |
| IT-3 | `error_400_response.txt` | Contains a non-empty error/rejection message (HTTP 400 status confirmed separately via curl exit code or status capture). |
| IT-4 | `health_response.txt` | Contains HTTP status 200 |
| IT-5 | `plutil_output.txt` | Contains `OK` from `plutil -lint` |
| IT-5 | `plist_contents.txt` | Contains both `ProgramArguments` and `KeepAlive` |
| IT-6 | `skill_validation.txt` | Contains PASS results for: frontmatter check, line count check, no-mutating-patterns check, read-only text check, query pattern check, JSON.stringify check, POST instruction check |
| IT-7 | `claude_output.txt` | Contains parseable JSON with real OmniFocus data (task names, project names, or structured results). Must NOT be empty, placeholder, or error-only output. |

## Integration Test Scenarios

### IT-1: Server Build and Start

| Field | Value |
|-------|-------|
| **Scenario** | Build the server binary, start it, verify it listens on port 7890 |
| **Surface** | `surface=non_ui` |
| **Starting state** | Go source in `cmd/omnifocal-server/`, port 7890 free, no server running |
| **Steps** | 1. `go build -o omnifocal-server ./cmd/omnifocal-server/` -- exits 0, binary exists. 2. `./omnifocal-server &` -- process starts. 3. Wait up to 3 seconds for port 7890. 4. `curl -s -o /dev/null -w '%{http_code}' http://localhost:7890/health` -- prints `200`. |
| **Verification** | Script exits 0 after all checks pass |
| **Evidence** | `IT-1/build.log` (build stdout/stderr), `IT-1/health_response.txt` (curl output showing 200) |
| **Proves** | AC-1.1, AC-1.2, AC-1.3, AC-3.1 |

### IT-2: Server /eval Happy Path

| Field | Value |
|-------|-------|
| **Scenario** | POST valid OmniFocus JS to /eval, verify 200 with real OmniFocus data in response body |
| **Surface** | `surface=non_ui` |
| **Starting state** | Server running on port 7890, OmniFocus running with at least one task or project |
| **Steps** | 1. `curl -s -w '\n%{http_code}' -X POST -d 'var app = Application("OmniFocus"); var doc = app.defaultDocument; var tasks = doc.flattenedTasks(); JSON.stringify(tasks.slice(0, 5).map(function(t) { return {name: t.name(), id: t.id()}; }))' http://localhost:7890/eval` -- last line prints `200`, body is JSON array. 2. Parse the response body as JSON. 3. Verify the JSON contains at least one object with a `name` key. |
| **Verification** | Script exits 0 after confirming HTTP 200 and JSON body with OmniFocus data |
| **Evidence** | `IT-2/response.txt` (full curl response body), `IT-2/http_status.txt` (HTTP status code) |
| **Content assertion** | `response.txt` must be valid JSON, must contain at least one object with a `name` field, must not be `"null"`, empty, or placeholder |
| **Proves** | AC-2.1, AC-2.2, AC-2.3, MSG-1 |

### IT-3: Server /eval Error Handling

| Field | Value |
|-------|-------|
| **Scenario** | POST invalid JS to /eval (verify 500 + error text), POST empty body (verify 400) |
| **Surface** | `surface=non_ui` |
| **Starting state** | Server running on port 7890 |
| **Steps** | 1. `curl -s -w '\n%{http_code}' -X POST -d 'this is not valid javascript syntax %%%' http://localhost:7890/eval` -- last line prints `500`, body contains osascript error text. 2. Verify response body contains error-related text (e.g., `error`, `Error`, `execution error`). 3. `curl -s -w '\n%{http_code}' -X POST -d '' http://localhost:7890/eval` -- last line prints `400`. 4. Verify response body is non-empty. |
| **Verification** | Script exits 0 after confirming both error cases |
| **Evidence** | `IT-3/error_500_response.txt` (500 response body), `IT-3/error_500_status.txt` (status code), `IT-3/error_400_response.txt` (400 response body), `IT-3/error_400_status.txt` (status code) |
| **Content assertion** | `error_500_response.txt` must contain error text from osascript (case-insensitive match for `error` or `execution`). `error_400_response.txt` must be non-empty. |
| **Proves** | AC-2.4, AC-2.5, AC-2.6, MSG-2, MSG-3 |

### IT-4: Server Health Check

| Field | Value |
|-------|-------|
| **Scenario** | GET /health returns 200 |
| **Surface** | `surface=non_ui` |
| **Starting state** | Server running on port 7890 |
| **Steps** | 1. `curl -s -w '\n%{http_code}' http://localhost:7890/health` -- last line prints `200`. |
| **Verification** | Script exits 0 after confirming HTTP 200 |
| **Evidence** | `IT-4/health_response.txt` (response body + status code) |
| **Content assertion** | File contains `200` |
| **Proves** | AC-3.1, MSG-4 |

### IT-5: launchd Plist Validation

| Field | Value |
|-------|-------|
| **Scenario** | Validate plist is well-formed XML with correct keys |
| **Surface** | `surface=non_ui` |
| **Starting state** | Plist file at `launchd/com.omnifocal.server.plist` |
| **Steps** | 1. `plutil -lint launchd/com.omnifocal.server.plist` -- prints `OK`. 2. `grep ProgramArguments launchd/com.omnifocal.server.plist` -- matches. 3. `grep KeepAlive launchd/com.omnifocal.server.plist` -- matches. |
| **Verification** | Script exits 0 after all three checks pass |
| **Evidence** | `IT-5/plutil_output.txt` (plutil result), `IT-5/plist_contents.txt` (grep results for ProgramArguments and KeepAlive) |
| **Content assertion** | `plutil_output.txt` contains `OK`. `plist_contents.txt` contains both `ProgramArguments` and `KeepAlive`. |
| **Proves** | AC-4.1, AC-4.2, AC-4.3 |

### IT-6: Skill Structure Validation

| Field | Value |
|-------|-------|
| **Scenario** | Validate SKILL.md exists, has correct structure, enforces read-only, includes query patterns |
| **Surface** | `surface=non_ui` |
| **Starting state** | Skill file at `skills/omnifocal/SKILL.md` |
| **Steps** | 1. Verify file exists. 2. Extract YAML frontmatter -- must contain `name:` and `description:`. 3. Count lines -- must be under 500. 4. Grep for mutating patterns (`save()`, `.name =`, `new Task`, `new Project`, `new Folder`, `new Tag`) -- must find ZERO matches. 5. Grep for read-only enforcement text (`read-only` or `never assign` or `never mutate`, case-insensitive) -- must find at least one match. 6. Grep for query example patterns (`flattenedTasks` or `flattenedProjects`) -- must find at least one match. 7. Grep for `JSON.stringify` -- must find at least one match. 8. Grep for POST instruction (`POST` and `/eval` or `curl`) -- must find at least one match. |
| **Verification** | Script exits 0 after all checks pass |
| **Evidence** | `IT-6/skill_validation.txt` (pass/fail result for each check with details) |
| **Content assertion** | File contains `PASS` for every check (frontmatter, line count, no-mutating, read-only text, query patterns, JSON.stringify, POST instruction). No `FAIL` entries. |
| **Proves** | AC-5.1, AC-5.2, AC-5.3, AC-6.1, AC-6.2, AC-7.1, AC-7.2, AC-7.3 |

### IT-7: Skill End-to-End via Claude Code CLI

| Field | Value |
|-------|-------|
| **Scenario** | Full agent-to-OmniFocus round trip: build server, start it, install skill, invoke Claude Code CLI with OmniFocus query prompt, verify output contains real data |
| **Surface** | `surface=non_ui` |
| **Starting state** | Go source available, OmniFocus running, Claude Code CLI installed, port 7890 free |
| **Steps** | 1. Build server: `go build -o omnifocal-server ./cmd/omnifocal-server/`. 2. Start server: `./omnifocal-server &`. 3. Wait for port 7890. 4. Create temp directory with skill installed: `mkdir -p /tmp/omnifocal-test/.claude/skills/omnifocal/` and copy `skills/omnifocal/SKILL.md` into it. 5. Run Claude Code CLI: `cd /tmp/omnifocal-test && claude -p "Use the omnifocal skill to list my OmniFocus inbox tasks. Return the raw JSON result." --allowedTools 'Bash(curl:*)' --max-turns 5 2>&1` -- capture stdout. 6. Verify stdout contains JSON with real OmniFocus data (task names, project names, or structured results). 7. Stop server. |
| **Verification** | Script exits 0 after confirming Claude Code output contains real OmniFocus data |
| **Evidence** | `IT-7/claude_output.txt` (full Claude Code CLI stdout), `IT-7/server.log` (server stdout/stderr during test) |
| **Content assertion** | `claude_output.txt` must contain parseable JSON with OmniFocus data (at least one recognizable field like `name` in a JSON structure). Must NOT be empty, contain only error messages, or contain placeholder text. |
| **Proves** | AC-8.1, AC-8.2 |

## Crosscheck

### Per Scenario

| Check | IT-1 | IT-2 | IT-3 | IT-4 | IT-5 | IT-6 | IT-7 |
|-------|------|------|------|------|------|------|------|
| Exercises delivered artifact | Yes (binary) | Yes (server) | Yes (server) | Yes (server) | Yes (plist) | Yes (skill) | Yes (all three) |
| Automatable | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Bounded | Yes (4 steps) | Yes (3 steps) | Yes (4 steps) | Yes (1 step) | Yes (3 steps) | Yes (8 steps) | Yes (7 steps) |
| Proportional | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Independent | Yes | Yes (needs server) | Yes (needs server) | Yes (needs server) | Yes | Yes | Yes (self-contained setup) |
| Crosses AC groups | AC-1, AC-3 | AC-2 | AC-2 | AC-3 | AC-4 | AC-5, AC-6, AC-7 | AC-8 (AC-1..AC-7 implicit) |
| Evidence artifacts declared | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

### Per AC

| AC | Covered by | Gap? |
|----|-----------|------|
| AC-1.1 | IT-1 | No |
| AC-1.2 | IT-1 | No |
| AC-1.3 | IT-1, IT-4 | No |
| AC-2.1 | IT-2 | No |
| AC-2.2 | IT-2 | No |
| AC-2.3 | IT-2 | No |
| AC-2.4 | IT-3 | No |
| AC-2.5 | IT-3 | No |
| AC-2.6 | IT-3 | No |
| AC-3.1 | IT-1, IT-4 | No |
| AC-4.1 | IT-5 | No |
| AC-4.2 | IT-5 | No |
| AC-4.3 | IT-5 | No |
| AC-5.1 | IT-6 | No |
| AC-5.2 | IT-6 | No |
| AC-5.3 | IT-6 | No |
| AC-6.1 | IT-6 | No |
| AC-6.2 | IT-6 | No |
| AC-7.1 | IT-6 | No |
| AC-7.2 | IT-6 | No |
| AC-7.3 | IT-6 | No |
| AC-8.1 | IT-7 | No |
| AC-8.2 | IT-7 | No |

### Per Message

| MSG | Covered by | Gap? |
|-----|-----------|------|
| MSG-1 | IT-2 | No |
| MSG-2 | IT-3 | No |
| MSG-3 | IT-3 | No |
| MSG-4 | IT-1, IT-4 | No |

### Overall

- At least one scenario tests each deliverable in its delivery form: IT-1 (binary), IT-5 (plist), IT-6 (skill), IT-7 (full round trip)
- Every user-facing message is triggered and validated
- Every AC group is covered
- Manifest covers all scenario IDs IT-1 through IT-7
- All scenarios declare evidence artifacts with content assertions
- Self-verification requirement specified for all test scripts
