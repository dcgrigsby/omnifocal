---
name: omnifocal
description: Query OmniFocus data via the omnifocal-server. Compose read-only OmniFocus JavaScript queries using the Omni Automation API and execute them through the server's POST /eval endpoint. Use this skill whenever the user asks about their tasks, projects, folders, tags, or anything stored in OmniFocus.
---

# OmniFocal — Read-Only OmniFocus Access

This skill lets you query OmniFocus on the user's Mac by composing JavaScript (Omni Automation) and sending it to the omnifocal-server.

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

## Read-Only Constraint — CRITICAL

**You MUST only compose read-only queries. Never modify OmniFocus data.**

Prohibited actions — never do any of these:
- Never assign properties — do not write to `.name`, `.flagged`, `.dueDate`, or any other settable property
- Never call mutating methods — no `markComplete`, `markIncomplete`, `drop`, `addTag`, `removeTag`, `clearTags`, `appendStringToNote`
- Never persist changes — do not call the database `save` method
- Never construct new objects — do not instantiate Task, Project, Folder, or Tag constructors
- Never call `moveTasks`, `duplicateTasks`, `deleteObject`, `moveSections`, `duplicateSections`, `moveTags`, `duplicateTags`
- Never call `undo` or `redo`

**Only use read accessors**: property getters (`.name()`, `.id()`, `.tasks()`, etc.) and collection accessors (`flattenedTasks`, `flattenedProjects`, etc.).

## Writing Queries

### Query Template

Every query follows this pattern:

```javascript
var doc = Application("OmniFocus").defaultDocument; <your query logic>; JSON.stringify(<result>)
```

Key points:
- Access the database via `Application("OmniFocus").defaultDocument`
- The document object gives you `flattenedTasks`, `flattenedProjects`, `flattenedFolders`, `flattenedTags`, `inbox`, `library`, `tags`, and more
- Always wrap the final result in `JSON.stringify()` so the output is parseable JSON
- Property access on OmniFocus objects uses method-call syntax: `task.name()` not `task.name`

### Available Collection Accessors

From the document object:

| Accessor | Returns | Description |
|----------|---------|-------------|
| `doc.inbox` | TaskArray | Inbox tasks |
| `doc.flattenedTasks` | TaskArray | All tasks (flattened hierarchy) |
| `doc.flattenedProjects` | ProjectArray | All projects |
| `doc.flattenedFolders` | FolderArray | All folders |
| `doc.flattenedTags` | TagArray | All tags |
| `doc.library` | SectionArray | Top-level library |
| `doc.projects` | ProjectArray | Top-level projects |
| `doc.folders` | FolderArray | Top-level folders |
| `doc.tags` | Tags | Top-level tags |

### Lookup by Name

| Method | Returns |
|--------|---------|
| `doc.projectNamed("name")` | Project or null |
| `doc.folderNamed("name")` | Folder or null |
| `doc.tagNamed("name")` | Tag or null |
| `doc.taskNamed("name")` | Task or null |

### Search

| Method | Returns |
|--------|---------|
| `doc.projectsMatching("search")` | Array of Projects |
| `doc.foldersMatching("search")` | Array of Folders |
| `doc.tagsMatching("search")` | Array of Tags |

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
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var tasks = doc.inbox(); JSON.stringify(tasks.map(function(t) { return {name: t.name(), id: t.id(), flagged: t.flagged()}; }))' http://localhost:7890/eval
```

### List All Projects

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var projs = doc.flattenedProjects(); JSON.stringify(projs.map(function(p) { return {name: p.name(), status: p.status().toString(), id: p.id()}; }))' http://localhost:7890/eval
```

### Find Tasks by Tag

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var tag = doc.tagNamed("work"); var tasks = tag ? tag.tasks() : []; JSON.stringify(tasks.map(function(t) { return {name: t.name(), id: t.id(), due: t.dueDate() ? t.dueDate().toISOString() : null}; }))' http://localhost:7890/eval
```

### Search for Tasks by Name

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var all = doc.flattenedTasks(); var matches = all.filter(function(t) { return t.name().toLowerCase().indexOf("report") !== -1; }); JSON.stringify(matches.map(function(t) { return {name: t.name(), id: t.id(), project: t.containingProject() ? t.containingProject().name() : null}; }))' http://localhost:7890/eval
```

### Find Overdue Tasks

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var all = doc.flattenedTasks(); var overdue = all.filter(function(t) { return t.taskStatus() === Task.Status.Overdue; }); JSON.stringify(overdue.map(function(t) { return {name: t.name(), due: t.effectiveDueDate() ? t.effectiveDueDate().toISOString() : null, project: t.containingProject() ? t.containingProject().name() : null}; }))' http://localhost:7890/eval
```

### Find Flagged Tasks

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var all = doc.flattenedTasks(); var flagged = all.filter(function(t) { return t.effectiveFlagged() && !t.completed(); }); JSON.stringify(flagged.map(function(t) { return {name: t.name(), id: t.id(), due: t.dueDate() ? t.dueDate().toISOString() : null}; }))' http://localhost:7890/eval
```

### List Tasks in a Specific Project

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var proj = doc.projectNamed("My Project"); var tasks = proj ? proj.flattenedTasks() : []; JSON.stringify(tasks.map(function(t) { return {name: t.name(), status: t.taskStatus().toString(), completed: t.completed()}; }))' http://localhost:7890/eval
```

### List All Tags

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var tgs = doc.flattenedTags(); JSON.stringify(tgs.map(function(tg) { return {name: tg.name(), id: tg.id(), taskCount: tg.tasks().length}; }))' http://localhost:7890/eval
```

### List All Folders

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var folders = doc.flattenedFolders(); JSON.stringify(folders.map(function(f) { return {name: f.name(), id: f.id(), projectCount: f.projects().length}; }))' http://localhost:7890/eval
```

### Get Tasks Due Soon

```bash
curl -s -X POST -d 'var doc = Application("OmniFocus").defaultDocument; var all = doc.flattenedTasks(); var dueSoon = all.filter(function(t) { return t.taskStatus() === Task.Status.DueSoon; }); JSON.stringify(dueSoon.map(function(t) { return {name: t.name(), due: t.effectiveDueDate() ? t.effectiveDueDate().toISOString() : null}; }))' http://localhost:7890/eval
```

## Tips

- **Limit results**: For large databases, use `.slice(0, N)` to limit the number of results returned.
- **Check for null**: Many properties can be null (dates, parent references). Always check before calling methods on them.
- **Date formatting**: Use `.toISOString()` on Date objects for consistent serialization.
- **Tag access**: Use `doc.tagNamed("name")` for exact match, `doc.tagsMatching("search")` for partial match.
- **Project lookup**: Use `doc.projectNamed("name")` for exact match, `doc.projectsMatching("search")` for partial match.
- **Error handling**: If a query returns an HTTP 500, the response body contains the osascript error message. Read it to diagnose the issue.
