# OmniFocal

A bridge that connects [NanoClaw](https://github.com/qwibitai/nanoclaw) agents to [OmniFocus](https://www.omnigroup.com/omnifocus) on macOS, enabling read-only access to tasks, projects, folders, tags, and perspectives.

---

## ⚠️ DANGER

**This server provides unfiltered access to the OmniFocus JavaScript automation API.** Any JavaScript sent to the `/eval` endpoint is executed directly via `osascript` with full privileges. There is no sandboxing, no query validation, and no write protection at the server level.

This means:

- **An AI agent (or any HTTP client) can create, modify, and delete tasks, projects, and other OmniFocus data.** The read-only constraint exists only in the NanoClaw skill's instructions, not in the server itself.
- **Malicious or malformed JavaScript can cause data loss.** There is no undo mechanism at the server level.
- **The server has no authentication.** Anyone who can reach the port can execute arbitrary OmniFocus JavaScript.

**This software is provided AS-IS, with absolutely no warranty, express or implied.** Use at your own risk. See the [LICENSE](LICENSE) file for full terms.

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

# Run
./omnifocal-server

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
