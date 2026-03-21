# OmniFocal Kilroy Configuration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Configure Kilroy Attractor artifacts (DoD, DOT graph, run.yaml) so the factory can build OmniFocal's two components: the Go server and the NanoClaw skill.

**Architecture:** Two Attractor pipelines in one DOT graph, sequenced so the server is built and verified before the skill pipeline tests against it. The factory uses API-based LLM calls for all implementation, with one exception: the skill verification node launches Claude Code CLI.

**Tech Stack:** Kilroy Attractor, Go (server), TypeScript/Node (skill context), osascript (OmniFocus bridge)

---

### Task 1: Build Definition of Done

**Skill:** `@build-dod`

**Files:**
- Read: `docs/plans/2026-03-21-omnifocal-design.md`
- Read: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`
- Read: `docs/specs/NANOCLAW-REFERENCE.md`
- Create: `docs/plans/2026-03-21-omnifocal-dod.md`

**Step 1: Invoke build-dod skill**

Follow the `skills/build-dod/SKILL.md` process against the design doc:

1. Read the full design doc
2. List deliverables:
   - `omnifocal-server` Go binary
   - `com.omnifocal.server.plist` launchd plist
   - `omnifocal-skill/SKILL.md` NanoClaw skill file
3. Write acceptance criteria covering:
   - AC-1: Server build (Go compiles, single binary produced)
   - AC-2: Server `/eval` endpoint (accepts JS, returns OmniFocus results, error handling)
   - AC-3: Server `/health` endpoint (returns 200)
   - AC-4: launchd plist (valid XML, correct binary path, restart on crash)
   - AC-5: Skill structure (valid NanoClaw SKILL.md with YAML frontmatter)
   - AC-6: Skill read-only (no mutating API patterns in skill instructions)
   - AC-7: Skill query composition (agent can compose valid OmniFocus JS from skill instructions)
   - AC-8: Integration (skill + server: agent composes query via skill, sends to server, gets valid OmniFocus data back)
4. Inventory user-facing message surfaces (server error responses, health check response)
5. Write integration test scenarios:
   - IT-1: Server build and start (`surface=non_ui`) — compile Go, start binary, verify listening
   - IT-2: Server eval happy path (`surface=non_ui`) — POST JS to `/eval`, verify JSON result from OmniFocus
   - IT-3: Server eval error handling (`surface=non_ui`) — POST invalid JS, verify 500 + error message
   - IT-4: Server health check (`surface=non_ui`) — GET `/health`, verify 200
   - IT-5: launchd plist validation (`surface=non_ui`) — plutil validates plist XML
   - IT-6: Skill structure validation (`surface=non_ui`) — verify SKILL.md has correct frontmatter and content
   - IT-7: Skill end-to-end via Claude Code (`surface=non_ui`) — launch Claude Code with skill installed, give it an OmniFocus query prompt, verify it composes valid JS and gets results from the running server
6. Crosscheck all ACs against scenarios
7. Define test evidence contract under `.ai/runs/$KILROY_RUN_ID/test-evidence/latest/`

**Step 2: Review the DoD**

Verify:
- Every AC maps to at least one IT scenario
- Every IT scenario is automatable, bounded, proportional, independent
- Test evidence paths are explicit
- IT-7 (skill test) correctly describes the Claude Code CLI approach

**Step 3: Commit**

```bash
git add docs/plans/2026-03-21-omnifocal-dod.md
git commit -m "Add OmniFocal Definition of Done with acceptance criteria and integration tests"
```

---

### Task 2: Create DOT Pipeline Graph

**Skill:** `@create-dotfile`

**Files:**
- Read: `docs/plans/2026-03-21-omnifocal-design.md`
- Read: `docs/plans/2026-03-21-omnifocal-dod.md`
- Read: `skills/create-dotfile/reference_template.dot`
- Read: `skills/create-dotfile/preferences.yaml`
- Create: `omnifocal.dot`

**Step 1: Fetch current model list**

Run: `kilroy attractor modeldb suggest`

If unavailable, use these per the weather report and AGENTS.md:
- Default implementation: `gpt-5.3-codex` (openai)
- QA / DevOps: `claude-opus-4.6` (anthropic)
- Architectural critique: `gpt-5.4` (openai)

**Step 2: Design topology from reference template**

Start from `reference_template.dot`. The graph needs these clusters:

1. **Bootstrap** (`cluster_bootstrap`):
   - `check_toolchain`: verify `go`, `osascript`, `curl`, `plutil` are available
   - `expand_spec`: read design doc + specs, write to `.ai/runs/$KILROY_RUN_ID/spec.md`
   - `check_dod`: check if DoD exists; route to DoD fanout if missing

2. **DoD Fanout** (`cluster_dod`): standard 3-way debate → consolidate (only if DoD missing)

3. **Planning Fanout** (`cluster_planning`): 3-way plan → debate_consolidate

4. **State Detection** (`cluster_detect`): if Go source exists, skip to verify

5. **Server Implementation** (`cluster_implement_server`):
   - `implement_server`: Go HTTP server + osascript bridge (class="hard", `gpt-5.3-codex`)
   - `implement_launchd`: launchd plist + validate scripts
   - `merge_server`: merge branches

6. **Server Verification** (`cluster_verify_server`):
   - `verify_fmt`: `sh scripts/validate-fmt.sh`
   - `verify_build`: `sh scripts/validate-build.sh`
   - `verify_test_server`: `sh scripts/validate-test-server.sh` (IT-1 through IT-5)
   - `verify_artifacts_server`: check test evidence manifest
   - `verify_fidelity_server`: semantic AC-by-AC review against DoD (AC-1 through AC-4)

7. **Skill Implementation** (`cluster_implement_skill`):
   - `implement_skill`: compose NanoClaw skill markdown with OmniFocus API reference and query patterns (`gpt-5.3-codex`)
   - Node prompt must reference `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md` and `docs/specs/NANOCLAW-REFERENCE.md`

8. **Skill Verification** (`cluster_verify_skill`):
   - `verify_skill_structure`: validate SKILL.md format (IT-6)
   - `verify_skill_e2e`: **Tool node** that launches Claude Code CLI with skill installed, runs test prompts against running server (IT-7). This is the only node using `tool_command` with Claude Code.
   - `verify_fidelity_skill`: semantic AC-by-AC review (AC-5 through AC-8)

9. **Review** (`cluster_review`): 3-way review → consensus (goal_gate=true)

10. **Repair** (`cluster_repair`): targeted fixes

11. **Postmortem** (`cluster_postmortem`): analyze failures, route to repair/replan

**Step 3: Set model_stylesheet**

```dot
model_stylesheet = "
  * { llm_model: gpt-5.3-codex; llm_provider: openai; }
  .verify { llm_model: claude-opus-4.6; llm_provider: anthropic; }
  .review { llm_model: gpt-5.4; llm_provider: openai; }
  .hard { llm_model: gpt-5.3-codex; llm_provider: openai; }
"
```

**Step 4: Compose node prompts**

Every `shape=box` node must include:
- `$KILROY_STAGE_STATUS_PATH` and `$KILROY_STAGE_STATUS_FALLBACK_PATH`
- Explicit success/fail behavior with `failure_reason` and `failure_class`
- Stable `failure_signature` on verify nodes
- References to spec files in `docs/specs/` and `docs/plans/`

Key prompt details:
- `implement_server` prompt must reference `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md` for the osascript invocation pattern
- `implement_skill` prompt must reference both spec files and the design doc's skill section
- `verify_skill_e2e` must describe the Claude Code CLI test setup (create temp directory with `.claude/` config, install skill, run prompts)
- All verify nodes use `tool_command="sh scripts/validate-*.sh || { echo 'KILROY_VALIDATE_FAILURE: ...'; exit 1; }"`

**Step 5: Set graph-level attributes**

```dot
graph [
  goal = "Build OmniFocal: Go proxy server + NanoClaw skill for read-only OmniFocus access"
  rankdir = TB
  retry_target = debate_consolidate
  loop_restart_signature_limit = 5
  loop_restart_persist_keys = "last_failing_acs"
]
```

**Step 6: Validate**

The PostToolUse hook `skills/create-dotfile/hooks/validate-dot.sh` will run automatically after writing the `.dot` file. Fix any issues it reports.

Run: `kilroy attractor validate --graph omnifocal.dot`

Expected: no errors.

**Step 7: Commit**

```bash
git add omnifocal.dot
git commit -m "Add OmniFocal Attractor pipeline graph"
```

---

### Task 3: Create Run Config

**Skill:** `@create-runfile`

**Files:**
- Read: `omnifocal.dot`
- Read: `skills/create-runfile/reference_run_template.yaml`
- Read: `skills/shared/profile_default_env.yaml`
- Create: `run.yaml`

**Step 1: Start from reference template**

Set required fields:
```yaml
version: 1
graph: omnifocal.dot
task: "Build OmniFocal: Go proxy server for OmniFocus JS evaluation + NanoClaw skill for read-only OmniFocus queries"

repo:
  path: /Users/dan/omnifocal
```

**Step 2: Configure providers**

Both OpenAI and Anthropic are used by the graph. Both use API backend:
```yaml
llm:
  cli_profile: real
  providers:
    openai:
      backend: api
    anthropic:
      backend: api
```

**Step 3: Configure CXDB**

Use the standard autostart pattern. Paths need to resolve to the local Kilroy installation:
```yaml
cxdb:
  binary_addr: 127.0.0.1:9009
  http_base_url: http://127.0.0.1:9010
  autostart:
    enabled: true
    command: ["<kilroy-path>/scripts/start-cxdb.sh"]
    wait_timeout_ms: 20000
    poll_interval_ms: 250
    ui:
      enabled: true
      command: ["<kilroy-path>/scripts/start-cxdb-ui.sh"]
      url: "http://127.0.0.1:9020"
```

Resolve `<kilroy-path>` to the actual Kilroy installation path on this machine.

**Step 4: Configure artifact policy**

This project uses Go and Node profiles:
```yaml
artifact_policy:
  profiles: ["go", "node"]
  env:
    managed_roots:
      tool_cache_root: "managed"
    overrides:
      go:
        GOPATH: "{managed_roots.tool_cache_root}/go-path"
        GOMODCACHE: "{managed_roots.tool_cache_root}/go-path/pkg/mod"
      node: {}
      generic: {}
  checkpoint:
    exclude_globs:
      - "**/node_modules/**"
      - "**/.go-path/**"
```

**Step 5: Configure inputs materialization**

```yaml
inputs:
  materialize:
    enabled: true
    imports:
      - pattern: "docs/**/*.md"
        required: false
    fan_in:
      promote_run_scoped: []
    follow_references: true
    infer_with_llm: false
```

**Step 6: Set runtime policy**

```yaml
runtime_policy:
  stage_timeout_ms: 0
  stall_timeout_ms: 600000
  stall_check_interval_ms: 5000
  max_llm_retries: 6

git:
  require_clean: false
  run_branch_prefix: attractor/run
  commit_per_node: true

preflight:
  prompt_probes:
    enabled: true
    transports: [complete, stream]
    timeout_ms: 15000
    retries: 1
    base_delay_ms: 500
    max_delay_ms: 5000
```

**Step 7: Validate alignment**

Confirm:
- Every DOT provider (`openai`, `anthropic`) has a run-config backend entry
- `repo.path` is correct
- No unresolved placeholders
- CXDB autostart paths resolve

**Step 8: Commit**

```bash
git add run.yaml
git commit -m "Add OmniFocal Kilroy run config"
```

---

### Task 4: Validate Pipeline Readiness

**Skill:** `@using-kilroy`

**Step 1: Validate graph**

Run: `kilroy attractor validate --graph omnifocal.dot`

Expected: no errors, no warnings.

**Step 2: Preflight run**

Run: `kilroy attractor run --preflight --graph omnifocal.dot --config run.yaml`

Expected: all provider probes succeed, graph validates, inputs materialize.

**Step 3: Fix any issues**

If validation or preflight fails:
- Graph issues → re-invoke `@create-dotfile` to repair
- Run config issues → re-invoke `@create-runfile` to repair
- Provider issues → check `.env.local` has correct API keys

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "Fix pipeline validation issues"
```

---

### Task 5: Launch Pipeline

**Skill:** `@using-kilroy`

**Step 1: Run the pipeline**

Run: `kilroy attractor run --detach --graph omnifocal.dot --config run.yaml`

Capture the run ID and logs root from the output.

**Step 2: Set up monitoring**

Use `anthropic-skills:schedule` to create a monitoring task per the AGENTS.md template:
- Frequency: every 5 minutes
- Prompt includes: run ID, logs root, repo path, expected stage sequence
- Auto-disable on final state

**Step 3: Create handoff block**

Write a handoff prompt per AGENTS.md format so the next session can resume if needed.
