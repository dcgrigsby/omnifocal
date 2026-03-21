# NanoClaw Architecture Reference

A comprehensive reference for building new NanoClaw skills and understanding the system internals. Based on the NanoClaw project at https://github.com/qwibitai/nanoclaw.

---

## Table of Contents

1. [Overview](#overview)
2. [Overall Architecture](#overall-architecture)
3. [Skill System](#skill-system)
4. [Channel System](#channel-system)
5. [Container Execution](#container-execution)
6. [Container Networking](#container-networking)
7. [IPC and MCP Tools](#ipc-and-mcp-tools)
8. [Memory and Sessions](#memory-and-sessions)
9. [Scheduled Tasks](#scheduled-tasks)
10. [Credential Proxy](#credential-proxy)
11. [Building a New Skill: Checklist](#building-a-new-skill-checklist)

---

## Overview

NanoClaw is a personal AI assistant framework built on the Claude Agent SDK. It connects to messaging platforms (WhatsApp, Telegram, Slack, Discord, Gmail), routes messages through a single Node.js orchestrator process, and executes Claude agents inside isolated Linux containers. The codebase is deliberately small (under 35k tokens) so that Claude Code can understand and modify it directly.

Key design principles:

- **Single process.** One Node.js process handles all channels, routing, and scheduling.
- **Container isolation.** Every agent invocation runs inside a Linux VM (Docker or Apple Container). Bash commands run inside the container, not on the host.
- **Skills over features.** New capabilities are added as Claude Code skills that transform the user's fork, rather than being merged into a monolithic core.
- **No configuration files.** Users modify source code directly (the codebase is small enough that this is safe).

---

## Overall Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        HOST (macOS / Linux)                          │
│                     (Main Node.js Process)                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐                  ┌────────────────────┐        │
│  │ Channels         │────────────────> │   SQLite Database  │        │
│  │ (self-register   │<────────────────-│   (messages.db)    │        │
│  │  at startup)     │  store/send      └─────────┬──────────┘        │
│  └──────────────────┘                            │                   │
│                                                  │                   │
│         ┌────────────────────────────────────────┘                   │
│         │                                                            │
│         v                                                            │
│  ┌──────────────────┐    ┌──────────────────┐    ┌───────────────┐  │
│  │  Message Loop    │    │  Scheduler Loop  │    │  IPC Watcher  │  │
│  │  (polls SQLite)  │    │  (checks tasks)  │    │  (file-based) │  │
│  └────────┬─────────┘    └────────┬─────────┘    └───────────────┘  │
│           │                       │                                  │
│           └───────────┬───────────┘                                  │
│                       │ spawns container                             │
│                       v                                              │
├──────────────────────────────────────────────────────────────────────┤
│                     CONTAINER (Linux VM)                              │
├──────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    AGENT RUNNER                               │    │
│  │                                                               │    │
│  │  Working directory: /workspace/group (mounted from host)      │    │
│  │  Volume mounts:                                               │    │
│  │    - groups/{name}/ -> /workspace/group                       │    │
│  │    - groups/global/ -> /workspace/global/ (non-main only)     │    │
│  │    - data/sessions/{group}/.claude/ -> /home/node/.claude/    │    │
│  │    - Additional dirs -> /workspace/extra/*                    │    │
│  │                                                               │    │
│  │  Tools (all groups):                                          │    │
│  │    - Bash (safe - sandboxed in container)                     │    │
│  │    - Read, Write, Edit, Glob, Grep                            │    │
│  │    - WebSearch, WebFetch                                      │    │
│  │    - agent-browser (Chromium automation)                      │    │
│  │    - mcp__nanoclaw__* (scheduler/messaging via IPC)           │    │
│  │                                                               │    │
│  └──────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

### Message Flow

1. User sends a message via a connected channel (Slack, Telegram, etc.)
2. Channel stores the message in SQLite
3. Message loop polls SQLite every 2 seconds
4. Router checks: is the chat registered? Does the message match the trigger pattern (`@Andy`)?
5. Router catches up all messages since last agent interaction, formats them with timestamps and sender names
6. Container runner spawns a container with the group's mounts, pipes the prompt via stdin JSON
7. Agent runner inside the container calls the Claude Agent SDK (`query()`)
8. Agent processes the message, can use tools (Bash, WebSearch, file ops, MCP tools)
9. Agent's response is written to stdout using sentinel markers (`---NANOCLAW_OUTPUT_START---` / `---NANOCLAW_OUTPUT_END---`)
10. Host parses the response and sends it back through the owning channel

### Key Source Files

| File | Purpose |
|------|---------|
| `src/index.ts` | Orchestrator: state, message loop, agent invocation |
| `src/channels/registry.ts` | Channel factory registry (self-registration) |
| `src/channels/index.ts` | Barrel imports that trigger channel registration |
| `src/router.ts` | Message formatting and outbound routing |
| `src/config.ts` | Trigger pattern, paths, intervals |
| `src/types.ts` | TypeScript interfaces (Channel, NewMessage, etc.) |
| `src/container-runner.ts` | Spawns agent containers with volume mounts |
| `src/container-runtime.ts` | Runtime abstraction (Docker vs Apple Container) |
| `src/credential-proxy.ts` | HTTP proxy that injects API credentials for containers |
| `src/ipc.ts` | IPC watcher and task processing |
| `src/task-scheduler.ts` | Runs scheduled tasks |
| `src/db.ts` | SQLite operations |
| `container/agent-runner/src/index.ts` | Entry point inside the container |
| `container/agent-runner/src/ipc-mcp-stdio.ts` | MCP server for host communication (runs inside container) |
| `container/Dockerfile` | Container image definition |

---

## Skill System

NanoClaw has four types of skills. This is the most important concept for contributing.

### 1. Feature Skills (branch-based)

Add capabilities by merging a git branch. The SKILL.md on `main` contains setup instructions; the actual code lives on a `skill/*` branch in the upstream repo.

**Location:** `.claude/skills/add-<name>/SKILL.md` on `main` (instructions only); code on `skill/<name>` branch

**Examples:** `/add-telegram`, `/add-slack`, `/add-discord`, `/add-gmail`, `/add-whatsapp`

**How they work:**
1. User runs `/add-telegram` in Claude Code
2. Claude follows the SKILL.md instructions
3. Step 1 is always: fetch and merge the skill branch (`git fetch upstream skill/telegram && git merge upstream/skill/telegram`)
4. Remaining steps: interactive setup (create bot, get token, configure .env, register groups, verify)

**SKILL.md structure for feature skills:**

```markdown
---
name: add-<channel>
description: Add <Channel> as a channel. Can replace other channels or run alongside them.
---

# Add <Channel> Channel

## Phase 1: Pre-flight
- Check if already applied (does `src/channels/<name>.ts` exist?)
- Ask user for credentials if they have them

## Phase 2: Apply Code Changes
- Add git remote, fetch, merge the skill branch
- `npm install && npm run build`
- Run tests

## Phase 3: Setup
- Walk user through creating bot/app and getting tokens
- Write credentials to `.env`
- Sync to container: `mkdir -p data/env && cp .env data/env/env`
- Build and restart service

## Phase 4: Registration
- Get chat/channel ID from user
- Register using `npx tsx setup/index.ts --step register`

## Phase 5: Verify
- Test the connection
- Troubleshooting section
```

### 2. Utility Skills (with code files)

Standalone tools that ship code files alongside the SKILL.md. No branch merge needed -- the code is self-contained in the skill directory.

**Location:** `.claude/skills/<name>/` with supporting files (e.g., `scripts/` subfolder)

**Example:** `/claw` -- a Python CLI in `scripts/claw`

**Key details:**
- Put code in separate files, not inline in the SKILL.md
- Use `${CLAUDE_SKILL_DIR}` to reference files in the skill directory
- SKILL.md contains installation instructions, usage docs, and troubleshooting

### 3. Operational Skills (instruction-only)

Workflows and guides with no code changes. The SKILL.md IS the entire skill.

**Location:** `.claude/skills/` on `main`

**Examples:** `/setup`, `/debug`, `/customize`, `/update-nanoclaw`, `/update-skills`

**Guidelines:**
- Pure instructions, no code files, no branch merges
- Use `AskUserQuestion` for interactive prompts
- Always available on `main` for every user

### 4. Container Skills (agent runtime)

Skills loaded inside the agent container at runtime. They teach the container agent how to use tools, format output, or perform tasks. They are NOT invoked by the user on the host.

**Location:** `container/skills/<name>/SKILL.md`

**Examples:** `agent-browser` (web browsing), `capabilities` (/capabilities command), `status` (/status command), `slack-formatting` (Slack mrkdwn syntax)

**How they get into the container:**
The `container-runner.ts` on the host copies all directories from `container/skills/` into each group's `.claude/skills/` directory (`data/sessions/{group}/.claude/skills/`) before spawning the container. The container mounts this at `/home/node/.claude/`, so Claude Code inside the container discovers them via `settingSources: ['project', 'user']`.

**Guidelines:**
- Follow the same SKILL.md + frontmatter format
- Use `allowed-tools` frontmatter to scope tool permissions (e.g., `allowed-tools: Bash(agent-browser:*)`)
- Keep them focused -- the agent's context window is shared across all container skills

### SKILL.md Format (all types)

All skills use the Claude Code skills standard:

```markdown
---
name: my-skill
description: What this skill does and when to use it.
---

Instructions here...
```

**Rules:**
- Keep SKILL.md under 500 lines; move detail to separate reference files
- `name`: lowercase, alphanumeric + hyphens, max 64 chars
- `description`: required -- Claude uses this to decide when to invoke the skill
- Put code in separate files, not inline in the markdown

---

## Channel System

The core ships with no channels built in. Each channel is installed as a feature skill that adds source code to the user's fork.

### Channel Interface

Every channel implements this interface (from `src/types.ts`):

```typescript
interface Channel {
  name: string;
  connect(): Promise<void>;
  sendMessage(jid: string, text: string): Promise<void>;
  isConnected(): boolean;
  ownsJid(jid: string): boolean;
  disconnect(): Promise<void>;
  setTyping?(jid: string, isTyping: boolean): Promise<void>;
  syncGroups?(force: boolean): Promise<void>;
}
```

### Self-Registration Pattern

Channels use a factory registry in `src/channels/registry.ts`:

```typescript
export type ChannelFactory = (opts: ChannelOpts) => Channel | null;

const registry = new Map<string, ChannelFactory>();

export function registerChannel(name: string, factory: ChannelFactory): void {
  registry.set(name, factory);
}
```

Each channel module calls `registerChannel()` at import time. The barrel file `src/channels/index.ts` imports all channel modules, triggering registration. At startup, the orchestrator loops through registered channels, calling each factory. Factories return `null` if their credentials are missing (graceful degradation).

### Adding a New Channel

A feature skill that adds a channel must:

1. Add `src/channels/<name>.ts` implementing the `Channel` interface
2. Call `registerChannel(name, factory)` at module load time
3. Return `null` from the factory if credentials are missing
4. Add an import line to `src/channels/index.ts`
5. Add the npm dependency to `package.json`
6. Add credential env vars to `.env.example`

### JID Conventions

Each channel uses a prefixed JID format so the router can identify which channel owns a given chat:

| Channel | JID Format | Example |
|---------|-----------|---------|
| WhatsApp | Raw WhatsApp JID | `120363336345536173@g.us` |
| Telegram | `tg:<chat-id>` | `tg:-1001234567890` |
| Slack | `slack:<channel-id>` | `slack:C0123456789` |
| Discord | `dc:<channel-id>` | `dc:1234567890123456` |

### Group Registration

Groups are registered in SQLite (`registered_groups` table). Each registration includes:

```typescript
interface RegisteredGroup {
  name: string;
  folder: string;          // e.g., "slack_engineering"
  trigger: string;         // e.g., "@Andy"
  added_at: string;
  containerConfig?: ContainerConfig;
  requiresTrigger?: boolean;  // false for main channels
  isMain?: boolean;
}
```

Folder names follow the convention `{channel}_{group-name}` (e.g., `whatsapp_family-chat`, `telegram_dev-team`).

Registration is done via CLI:
```bash
npx tsx setup/index.ts --step register -- \
  --jid "slack:C0123456789" \
  --name "engineering" \
  --folder "slack_engineering" \
  --trigger "@Andy" \
  --channel slack
```

---

## Container Execution

### Container Image

The container image (`container/Dockerfile`) is based on `node:22-slim` and includes:

- Chromium (for `agent-browser` web automation)
- `agent-browser` and `@anthropic-ai/claude-code` installed globally
- The `agent-runner` TypeScript project (compiled on container startup)
- Workspace directories: `/workspace/group`, `/workspace/global`, `/workspace/extra`, `/workspace/ipc`
- Runs as non-root user `node` (uid 1000)

### Volume Mounts

The host (`container-runner.ts`) builds volume mounts per group:

| Mount | Container Path | Writable | Notes |
|-------|---------------|----------|-------|
| `groups/{name}/` | `/workspace/group` | Yes | Agent's working directory |
| `groups/global/` | `/workspace/global` | No | Global memory (non-main only) |
| `data/sessions/{group}/.claude/` | `/home/node/.claude/` | Yes | Session data, settings, skills |
| `data/ipc/{group}/` | `/workspace/ipc` | Yes | IPC files (messages, tasks, input) |
| Additional mounts | `/workspace/extra/*` | Configurable | Per-group extra directories |

For main groups, the project root is also mounted read-only at `/workspace/project` (with `.env` shadowed by `/dev/null` for security).

### Agent Runner (inside container)

The entry point (`container/agent-runner/src/index.ts`) does the following:

1. Reads JSON config from stdin (`ContainerInput`: prompt, sessionId, groupFolder, chatJid, isMain)
2. Calls the Claude Agent SDK's `query()` function with:
   - `cwd: '/workspace/group'`
   - `allowedTools`: Bash, file ops, WebSearch, WebFetch, Task/Team tools, `mcp__nanoclaw__*`
   - `permissionMode: 'bypassPermissions'` (all permissions pre-approved)
   - `settingSources: ['project', 'user']` (loads CLAUDE.md from cwd and parent)
   - `mcpServers: { nanoclaw: ... }` (the IPC-based MCP server)
3. Runs a query loop: after each query completes, waits for new IPC input messages or a `_close` sentinel
4. Writes results to stdout wrapped in `---NANOCLAW_OUTPUT_START---` / `---NANOCLAW_OUTPUT_END---` markers

The agent runner also:
- Archives conversation transcripts to `/workspace/group/conversations/` before compaction
- Loads global CLAUDE.md as additional system context for non-main groups
- Discovers extra directories at `/workspace/extra/*` and passes them to the SDK

### Tools Available to Container Agents

```
Bash, Read, Write, Edit, Glob, Grep,
WebSearch, WebFetch,
Task, TaskOutput, TaskStop,
TeamCreate, TeamDelete, SendMessage,
TodoWrite, ToolSearch, Skill,
NotebookEdit,
mcp__nanoclaw__*
```

---

## Container Networking

### Docker (macOS and Linux)

Docker Desktop on macOS provides `host.docker.internal` out of the box -- containers can reach the host at that hostname. On Linux, NanoClaw adds `--add-host=host.docker.internal:host-gateway` to the container args.

### Apple Container (macOS 26+)

Apple Container uses vmnet networking. Containers get IPs on the `192.168.64.0/24` subnet. The host creates a `bridge100` interface as the gateway (`192.168.64.1`).

**By default, containers can reach the host but NOT the internet.** Internet access requires manual setup:

1. **Enable IP forwarding:**
   ```bash
   sudo sysctl -w net.inet.ip.forwarding=1
   ```

2. **Enable NAT:**
   ```bash
   echo "nat on en0 from 192.168.64.0/24 to any -> (en0)" | sudo pfctl -ef -
   ```
   (Replace `en0` with your active internet interface; check with `route get 8.8.8.8 | grep interface`)

3. **IPv6 DNS workaround:** Because the NAT only handles IPv4, Node.js applications inside containers must prefer IPv4 DNS resolution:
   ```
   NODE_OPTIONS=--dns-result-order=ipv4first
   ```
   This is set in both the Dockerfile and passed via `-e` in `container-runner.ts`.

**Network path:**
```
Container VM (192.168.64.x)
    |
    +-- eth0 -> gateway 192.168.64.1
    |
bridge100 (192.168.64.1) <- host bridge, created by vmnet
    |
    +-- IP forwarding routes packets from bridge100 -> en0
    +-- NAT (pfctl) masquerades 192.168.64.0/24 -> en0's IP
    |
en0 (WiFi/Ethernet) -> Internet
```

### How Containers Reach the Anthropic API

Containers never see real API credentials. Instead:

1. The host runs a credential proxy (HTTP server) on a known port
2. Containers are told `ANTHROPIC_BASE_URL=http://host.docker.internal:<port>`
3. All API traffic goes through the proxy, which injects real credentials
4. Containers only have a placeholder `ANTHROPIC_API_KEY=placeholder` or `CLAUDE_CODE_OAUTH_TOKEN=placeholder`

The host gateway hostname resolves differently per runtime:
- **Docker (macOS):** `host.docker.internal` -> host loopback (127.0.0.1)
- **Docker (Linux):** `host.docker.internal` -> docker0 bridge IP (added via `--add-host`)
- **Apple Container:** `host.docker.internal` is set similarly; the proxy binds to 127.0.0.1

---

## IPC and MCP Tools

The agent inside the container communicates with the host via filesystem-based IPC and an in-process MCP server.

### IPC Directory Structure

Each group gets its own IPC namespace at `data/ipc/{group}/`:

```
data/ipc/{group}/
  messages/       # Outbound messages (agent -> host -> channel)
  tasks/          # Task operations (schedule, pause, resume, cancel)
  input/          # Inbound messages (host -> agent, follow-up messages)
  current_tasks.json    # Snapshot of scheduled tasks (written by host)
  available_groups.json # Snapshot of available groups (main only)
```

### MCP Server (ipc-mcp-stdio.ts)

The MCP server runs inside the container as a stdio-based server, spawned by the agent runner. It provides these tools to the Claude agent:

| Tool | Description |
|------|-------------|
| `send_message` | Send a message to the user/group immediately. Args: `text`, optional `sender` (role name for multi-bot display) |
| `schedule_task` | Schedule a recurring or one-time task. Args: `prompt`, `schedule_type` (cron/interval/once), `schedule_value`, `context_mode` (group/isolated), optional `target_group_jid` (main only) |
| `list_tasks` | List scheduled tasks. Main sees all; others see their own |
| `pause_task` | Pause a task by ID |
| `resume_task` | Resume a paused task by ID |
| `cancel_task` | Cancel and delete a task by ID |
| `update_task` | Update an existing task (prompt, schedule_type, schedule_value) |
| `register_group` | Register a new chat/group (main only). Args: `jid`, `name`, `folder`, `trigger` |

All MCP tool calls write JSON files to the IPC directories. The host's IPC watcher (`src/ipc.ts`) polls these directories and processes the requests.

### Follow-up Messages (IPC Input)

The host can send follow-up messages to a running container by writing JSON files to `data/ipc/{group}/input/`. The agent runner polls this directory every 500ms. When a file is found, the message is piped into the active query stream (or starts a new query if idle).

A `_close` sentinel file at `data/ipc/{group}/input/_close` signals the container to shut down gracefully.

---

## Memory and Sessions

### Memory Hierarchy

| Level | Location | Read By | Written By |
|-------|----------|---------|------------|
| Global | `groups/global/CLAUDE.md` | All groups | Main only |
| Group | `groups/{name}/CLAUDE.md` | That group | That group |
| Files | `groups/{name}/*.md` | That group | That group |

The agent runs with `cwd` set to `groups/{group-name}/`. The Claude Agent SDK with `settingSources: ['project']` automatically loads `../CLAUDE.md` (global) and `./CLAUDE.md` (group).

### Sessions

Each group has a session ID stored in SQLite. The session ID is passed to the Claude Agent SDK's `resume` option for conversation continuity. Session transcripts are JSONL files stored in `data/sessions/{group}/.claude/`.

---

## Scheduled Tasks

Tasks are created via the `schedule_task` MCP tool and run as full agent invocations in the task's group context.

### Schedule Types

| Type | Format | Example |
|------|--------|---------|
| `cron` | Cron expression (local timezone) | `0 9 * * 1` (Mondays 9am) |
| `interval` | Milliseconds | `3600000` (every hour) |
| `once` | Local ISO timestamp (no Z suffix) | `2026-02-01T15:30:00` |

### Context Modes

- **group**: Task runs with chat history and memory (for tasks that need conversation context)
- **isolated**: Task runs in a fresh session (for independent tasks; include all context in the prompt)

---

## Credential Proxy

The credential proxy (`src/credential-proxy.ts`) is an HTTP server on the host that sits between containers and the Anthropic API.

**API key mode:** Proxy strips any `x-api-key` header from the container's request and injects the real API key from `.env`.

**OAuth mode:** Proxy replaces the placeholder Bearer token with the real OAuth token when the container's SDK exchanges it for a temporary API key.

The proxy binds to:
- **macOS (Docker Desktop):** `127.0.0.1` (the VM routes `host.docker.internal` to loopback)
- **Linux (Docker):** the `docker0` bridge IP (so only containers can reach it)
- **WSL:** `127.0.0.1` (same VM routing as macOS)

Containers are configured with:
```
ANTHROPIC_BASE_URL=http://host.docker.internal:<port>
ANTHROPIC_API_KEY=placeholder        # or
CLAUDE_CODE_OAUTH_TOKEN=placeholder
```

This ensures real credentials never enter the container environment.

---

## Building a New Skill: Checklist

### For a Feature Skill (adds code via branch merge)

1. Fork `qwibitai/nanoclaw`, branch from `main`
2. Make code changes (new files, modified source, updated `package.json`)
3. Add `.claude/skills/add-<name>/SKILL.md` with:
   - Frontmatter: `name`, `description`
   - Phase 1: Pre-flight checks
   - Phase 2: Git fetch + merge of the skill branch
   - Phase 3: Interactive setup (credentials, configuration)
   - Phase 4: Registration (if it's a channel)
   - Phase 5: Verification + troubleshooting
4. Open a PR. Maintainers will create the `skill/<name>` branch

### For a Container Skill (runs inside agent)

1. Create `container/skills/<name>/SKILL.md` with:
   - Frontmatter: `name`, `description`, optionally `allowed-tools`
   - Instructions for the agent (how to detect context, what to do, output format)
2. Keep it focused and concise (shares context window with other skills)
3. The host automatically copies it into each group's `.claude/skills/` at container startup

### For an Operational Skill (instruction-only)

1. Create `.claude/skills/<name>/SKILL.md` on `main` with:
   - Frontmatter: `name`, `description`
   - Step-by-step workflow instructions
   - Use `AskUserQuestion` for interactive prompts
2. No code files needed

### For a Utility Skill (ships code)

1. Create `.claude/skills/<name>/SKILL.md` plus code files (e.g., in `scripts/`)
2. Use `${CLAUDE_SKILL_DIR}` in SKILL.md to reference supporting files
3. SKILL.md should contain installation, usage, and troubleshooting instructions

### General SKILL.md Rules

- Under 500 lines; move detail to reference files
- `name`: lowercase, alphanumeric + hyphens, max 64 chars
- `description`: required (Claude uses this for invocation matching)
- Code goes in separate files, not inline
- Use `AskUserQuestion` for user interaction
