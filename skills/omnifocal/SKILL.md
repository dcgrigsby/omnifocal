---
name: omnifocal
description: Interact with OmniFocus via the omnifocal-server. Compose OmniFocus JavaScript queries and commands using the Omni Automation API and execute them through the server's POST /eval endpoint. Use this skill whenever the user asks about their tasks, projects, folders, tags, or wants to create, modify, or complete items in OmniFocus.
---

# OmniFocal — OmniFocus Access

This skill lets you read and write OmniFocus data on the user's Mac by composing JavaScript (Omni Automation) and sending it to the omnifocal-server.

## How It Works

1. You compose an OmniFocus JavaScript query string
2. You POST it to the omnifocal-server's `/eval` endpoint
3. The server executes it via `osascript` against OmniFocus
4. You receive the result (typically JSON) in the response body

## Server Communication

The omnifocal-server listens on `http://localhost:7890`.

**Send a query:**

```bash
curl -s -X POST -d '<your JavaScript query>' http://localhost:7890/eval
```

**Check server health:**

```bash
curl -s http://localhost:7890/health
```

The server returns:
- **HTTP 200** with the query result as `text/plain` on success
- **HTTP 400** if the request body is empty
- **HTTP 500** with osascript error text if the script fails

Always check the server is healthy before running queries. If you get a connection error, the server may not be running.

## Write Operations

You can create, modify, and complete OmniFocus items. When performing write operations:

- **Always confirm destructive actions with the user** before deleting tasks, projects, or folders
- **Use `save()` sparingly** — OmniFocus auto-saves, but call `doc.save()` after batch modifications to ensure persistence
- Property writes use assignment syntax: `task.name = "new name"` (not method-call syntax)
- Property reads use method-call syntax: `task.name()` (not assignment syntax)

### Available Write Operations

**Task**: set `name`, `note`, `dueDate`, `deferDate`, `flagged`, `estimatedMinutes`, `sequential`, `completionDate`; call `markComplete()`, `markIncomplete()`, `drop(flag)`, `addTag(tag)`, `removeTag(tag)`, `clearTags()`, `appendStringToNote(string)`; create with `new Task(name, position)`

**Project**: set `name`, `note`, `dueDate`, `deferDate`, `flagged`, `estimatedMinutes`, `sequential`, `status`, `completionDate`; call `markComplete()`, `markIncomplete()`, `addTag(tag)`, `removeTag(tag)`; create with `new Project(name)` or `new Project(name, folder)`

**Folder**: set `name`, `status`; create with `new Folder(name)` or `new Folder(name, parentFolder)`

**Tag**: set `name`, `status`; create with `new Tag(name)` or `new Tag(name, parentTag)`

## Writing Queries

### Query Template

Every query follows this pattern:

```javascript
<your query logic>; JSON.stringify(<result>)
```

Key points:
- Global accessors are available directly: `inbox`, `flattenedTasks`, `flattenedProjects`, etc. — no `Application()` or `document` prefix needed
- Always wrap the final result in `JSON.stringify()` so the output is parseable JSON
- Property access uses direct dot notation: `task.name` not `task.name()`
- Property writes use assignment: `task.name = "new name"`
- Standard JS works: `.map()`, `.filter()`, arrow functions, template literals

### Available Global Accessors

| Accessor | Returns | Description |
|----------|---------|-------------|
| `inbox` | TaskArray | Inbox tasks |
| `flattenedTasks` | TaskArray | All tasks (flattened hierarchy) |
| `flattenedProjects` | ProjectArray | All projects |
| `flattenedFolders` | FolderArray | All folders |
| `flattenedTags` | TagArray | All tags |
| `library` | SectionArray | Top-level library |
| `projects` | ProjectArray | Top-level projects |
| `folders` | FolderArray | Top-level folders |
| `tags` | Tags | Top-level tags |

### Lookup by Name

| Method | Returns |
|--------|---------|
| `projectNamed("name")` | Project or null |
| `folderNamed("name")` | Folder or null |
| `tagNamed("name")` | Tag or null |
| `taskNamed("name")` | Task or null |

### Search

| Method | Returns |
|--------|---------|
| `projectsMatching("search")` | Array of Projects |
| `foldersMatching("search")` | Array of Folders |
| `tagsMatching("search")` | Array of Tags |

## API Reference

The OmniFocus API reference is split into focused files for progressive discovery:

1. **Start here**: Read `docs/omnifocus-api/CHEATSHEET.md` for a compact overview of all classes, properties, and methods
2. **Deep dive**: For detailed documentation on a specific class, read the individual reference file:
   - `docs/omnifocus-api/Task.md` — Task properties, methods, status values, notifications
   - `docs/omnifocus-api/Project.md` — Project properties, status, review scheduling
   - `docs/omnifocus-api/Folder.md` — Folder hierarchy and properties
   - `docs/omnifocus-api/Tag.md` — Tag properties and task filtering
   - `docs/omnifocus-api/Perspective.md` — Built-in and custom perspectives
   - `docs/omnifocus-api/Forecast.md` — Forecast days and badge counts
   - `docs/omnifocus-api/Database.md` — Core architecture, globals, and database methods
   - `docs/omnifocus-api/DateAndTime.md` — Date manipulation and formatters

Always read the CHEATSHEET first. Only load individual class files when you need details beyond what the cheatsheet provides.

## Query Patterns — Concrete Examples

### List Inbox Tasks

```bash
curl -s -X POST -d 'JSON.stringify(inbox.map(t => ({name: t.name, id: t.id.primaryKey, flagged: t.flagged})))' http://localhost:7890/eval
```

### List All Projects

```bash
curl -s -X POST -d 'JSON.stringify(flattenedProjects.map(p => ({name: p.name, status: p.status.name, id: p.id.primaryKey})))' http://localhost:7890/eval
```

### Find Tasks by Tag

```bash
curl -s -X POST -d 'var tag = tagNamed("work"); JSON.stringify(tag ? tag.tasks.map(t => ({name: t.name, id: t.id.primaryKey, due: t.dueDate ? t.dueDate.toISOString() : null})) : [])' http://localhost:7890/eval
```

### Search for Tasks by Name

```bash
curl -s -X POST -d 'JSON.stringify(flattenedTasks.filter(t => t.name.toLowerCase().includes("report")).map(t => ({name: t.name, id: t.id.primaryKey, project: t.containingProject ? t.containingProject.name : null})))' http://localhost:7890/eval
```

### Find Overdue Tasks

```bash
curl -s -X POST -d 'JSON.stringify(flattenedTasks.filter(t => t.taskStatus === Task.Status.Overdue).map(t => ({name: t.name, due: t.effectiveDueDate ? t.effectiveDueDate.toISOString() : null, project: t.containingProject ? t.containingProject.name : null})))' http://localhost:7890/eval
```

### Find Flagged Tasks

```bash
curl -s -X POST -d 'JSON.stringify(flattenedTasks.filter(t => t.effectiveFlagged && !t.completed).map(t => ({name: t.name, id: t.id.primaryKey, due: t.dueDate ? t.dueDate.toISOString() : null})))' http://localhost:7890/eval
```

### List Tasks in a Specific Project

```bash
curl -s -X POST -d 'var proj = projectNamed("My Project"); JSON.stringify(proj ? proj.flattenedTasks.map(t => ({name: t.name, status: t.taskStatus.name, completed: t.completed})) : [])' http://localhost:7890/eval
```

### List All Tags

```bash
curl -s -X POST -d 'JSON.stringify(flattenedTags.map(tg => ({name: tg.name, id: tg.id.primaryKey, taskCount: tg.tasks.length})))' http://localhost:7890/eval
```

### List All Folders

```bash
curl -s -X POST -d 'JSON.stringify(flattenedFolders.map(f => ({name: f.name, id: f.id.primaryKey, projectCount: f.projects.length})))' http://localhost:7890/eval
```

### Get Tasks Due Soon

```bash
curl -s -X POST -d 'JSON.stringify(flattenedTasks.filter(t => t.taskStatus === Task.Status.DueSoon).map(t => ({name: t.name, due: t.effectiveDueDate ? t.effectiveDueDate.toISOString() : null})))' http://localhost:7890/eval
```

### Create a New Task in Inbox

```bash
curl -s -X POST -d 'var t = new Task("Buy groceries", inbox.beginning); JSON.stringify({name: t.name, id: t.id.primaryKey})' http://localhost:7890/eval
```

### Create a Task in a Specific Project

```bash
curl -s -X POST -d 'var proj = projectNamed("My Project"); var t = new Task("Write report", proj); JSON.stringify({name: t.name, id: t.id.primaryKey, project: t.containingProject.name})' http://localhost:7890/eval
```

### Mark a Task Complete

```bash
curl -s -X POST -d 'var t = flattenedTasks.find(t => t.name === "Buy groceries"); if (t) { t.markComplete(); JSON.stringify({name: t.name, completed: t.completed}); } else { JSON.stringify({error: "task not found"}); }' http://localhost:7890/eval
```

### Set Due Date on a Task

```bash
curl -s -X POST -d 'var t = flattenedTasks.find(t => t.name === "Write report"); if (t) { t.dueDate = new Date("2026-04-01T17:00:00"); JSON.stringify({name: t.name, due: t.dueDate.toISOString()}); } else { JSON.stringify({error: "task not found"}); }' http://localhost:7890/eval
```

### Add a Tag to a Task

```bash
curl -s -X POST -d 'var t = flattenedTasks.find(t => t.name === "Write report"); var tag = tagNamed("urgent"); if (t && tag) { t.addTag(tag); JSON.stringify({name: t.name, tags: t.tags.map(tg => tg.name)}); } else { JSON.stringify({error: "task or tag not found"}); }' http://localhost:7890/eval
```

### Create a New Project

```bash
curl -s -X POST -d 'var p = new Project("Q2 Planning"); JSON.stringify({name: p.name, id: p.id.primaryKey})' http://localhost:7890/eval
```

## Tips

- **Limit results**: For large databases, use `.slice(0, N)` to limit the number of results returned.
- **Check for null**: Many properties can be null (dates, parent references). Always check before calling methods on them.
- **Date formatting**: Use `.toISOString()` on Date objects for consistent serialization.
- **Tag access**: Use `doc.tagNamed("name")` for exact match, `doc.tagsMatching("search")` for partial match.
- **Project lookup**: Use `doc.projectNamed("name")` for exact match, `doc.projectsMatching("search")` for partial match.
- **Error handling**: If a query returns an HTTP 500, the response body contains the osascript error message. Read it to diagnose the issue.
