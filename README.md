# OmniFocal

A bridge that connects [NanoClaw](https://github.com/qwibitai/nanoclaw) agents to [OmniFocus](https://www.omnigroup.com/omnifocus) on macOS via the Omni Automation JavaScript API.

---

## ⛔ DANGER — READ BEFORE USE

> **By running this software, you acknowledge the risks below and accept full responsibility for any consequences. See [NOTICE](NOTICE) for the complete safety warning.**

**This server executes arbitrary JavaScript against OmniFocus with full read/write privileges.** There is:

- **No sandboxing** — JavaScript runs with the same privileges as OmniFocus itself
- **No authentication** — any client that can reach the port can execute code
- **No input validation** — the server passes JavaScript directly to `osascript`
- **No undo** — destructive operations (delete, modify, bulk changes) are permanent

### What can go wrong

An AI agent, a misconfigured script, or any network client that can reach port 7890 can:

- **Delete all your tasks, projects, and folders** with a single HTTP request
- **Modify or corrupt your OmniFocus database** silently and irreversibly
- **Exfiltrate your entire task history** if the server is exposed beyond localhost

### Your responsibility

- **Never expose this server to untrusted networks.** Bind to `127.0.0.1` or use firewall rules.
- **Review any AI agent's instructions** before granting it access to the server.
- **Back up your OmniFocus database** before use.
- **The `--i-accept-the-risk` flag is required to start the server.** This is intentional.

### No warranty

**THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT WARRANTY OF ANY KIND.** The authors and contributors accept no liability for data loss, corruption, or any other damages arising from the use of this software. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

---

## Architecture

```
NanoClaw Agent (Apple Container)
    │
    │  HTTP POST /eval  (body: JS string)
    │
    ▼
omnifocal-server (Go, launchd daemon on Mac host, port 7890)
    │
    │  osascript -l JavaScript
    │
    ▼
OmniFocus.app (Omni Automation)
    │
    │  JSON result
    │
    ▼
(back up the chain)
```

## Components

**omnifocal-server** — A Go binary that listens on port 7890, accepts JavaScript via `POST /eval`, executes it against OmniFocus via `osascript`, and returns the result. Managed by launchd for automatic startup and restart.

**omnifocal skill** — A NanoClaw skill (markdown) that teaches agents how to compose OmniFocus JavaScript queries and call the server. The skill enforces read-only access by instruction, not by mechanism.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/eval` | Execute OmniFocus JavaScript. Body is the JS string. Returns result as `text/plain`. |
| GET | `/health` | Returns `200 OK` when the server is running. |

## Quick Start

```bash
# Build
go build -o omnifocal-server ./cmd/omnifocal-server

# Run (the --i-accept-the-risk flag is required)
./omnifocal-server --i-accept-the-risk

# Test
curl -X POST http://localhost:7890/eval -d 'JSON.stringify(flattenedTasks.length)'
```

## launchd Installation

```bash
cp launchd/com.omnifocal.server.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.omnifocal.server.plist
```

## License

Apache 2.0 — see [LICENSE](LICENSE).

---

## How this was made

This project was designed and built almost entirely by AI agents. The architecture was brainstormed collaboratively with [Claude](https://claude.ai), the implementation was produced by a [Kilroy](https://github.com/danshapiro/kilroy) Attractor pipeline using Claude Opus, GPT-5.3 Codex, and GPT-5.4, and the verification was performed by adversarial AI reviewers. A human provided direction, made design decisions, and caught the problems the factory missed. The full build story — including 6 failed runs before success — is a case study in AI-driven software factories and what it takes to make them work reliably.
