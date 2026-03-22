# OmniFocus API — Core Architecture & Database

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

---

## Core Architecture

OmniFocus Omni Automation scripts run in a JavaScript context with a global `document` object representing the open OmniFocus database. Key global accessors:

```javascript
// The database document
document                          // DatabaseDocument
document.windows[0]               // DocumentWindow

// Top-level collections
inbox                             // Inbox (TaskArray)
library                           // Library (SectionArray)
tags                              // Tags (TagArray)

// Flattened access (all items regardless of hierarchy)
flattenedTasks                    // TaskArray
flattenedProjects                 // ProjectArray
flattenedFolders                  // FolderArray
flattenedSections                 // SectionArray
flattenedTags                     // TagArray

// Lookup by name
tagNamed("name")                  // Tag | null
folderNamed("name")               // Folder | null
projectNamed("name")              // Project | null
taskNamed("name")                 // Task | null

// Search
projectsMatching("search")       // Array<Project>
foldersMatching("search")        // Array<Folder>
tagsMatching("search")           // Array<Tag>

// Settings
settings                          // Settings
```

---

## Database

### Database

The root object providing access to all OmniFocus data.

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `tagNamed` | `(name: String)` | `Tag \| null` |
| `folderNamed` | `(name: String)` | `Folder \| null` |
| `projectNamed` | `(name: String)` | `Project \| null` |
| `taskNamed` | `(name: String)` | `Task \| null` |
| `projectsMatching` | `(search: String)` | `Array<Project>` |
| `foldersMatching` | `(search: String)` | `Array<Folder>` |
| `tagsMatching` | `(search: String)` | `Array<Tag>` |
| `save` | `()` | `void` |
| `cleanUp` | `()` | `void` |
| `undo` | `()` | `void` |
| `redo` | `()` | `void` |
| `moveTasks` | `(tasks: Array<Task>, position: Project \| Task \| Task.ChildInsertionLocation)` | `void` |
| `duplicateTasks` | `(tasks: Array<Task>, position: Project \| Task \| Task.ChildInsertionLocation)` | `TaskArray` |
| `convertTasksToProjects` | `(tasks: Array<Task>, position: Folder \| Folder.ChildInsertionLocation)` | `Array<Project>` |
| `moveSections` | `(sections: Array<Project \| Folder>, position: Folder \| Folder.ChildInsertionLocation)` | `void` |
| `duplicateSections` | `(sections: Array<Project \| Folder>, position: Folder \| Folder.ChildInsertionLocation)` | `SectionArray` |
| `moveTags` | `(tags: Array<Tag>, position: Tag \| Tag.ChildInsertionLocation)` | `void` |
| `duplicateTags` | `(tags: Array<Tag>, position: Tag \| Tag.ChildInsertionLocation)` | `TagArray` |
| `deleteObject` | `(object: DatabaseObject)` | `void` |
| `copyTasksToPasteboard` | `(tasks: Array<Task>, pasteboard: Pasteboard)` | `void` |
| `canPasteTasks` | `(pasteboard: Pasteboard)` | `Boolean` |
| `pasteTasksFromPasteboard` | `(pasteboard: Pasteboard)` | `Array<Task>` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `app` | `Application` |
| `canRedo` | `Boolean` |
| `canUndo` | `Boolean` |
| `console` | `Console` |
| `document` | `DatabaseDocument \| null` |
| `flattenedFolders` | `FolderArray` |
| `flattenedProjects` | `ProjectArray` |
| `flattenedSections` | `SectionArray` |
| `flattenedTags` | `TagArray` |
| `flattenedTasks` | `TaskArray` |
| `folders` | `FolderArray` |
| `inbox` | `Inbox` |
| `library` | `Library` |
| `projects` | `ProjectArray` |
| `tags` | `Tags` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `settings` | `Settings` |

### DatabaseObject

Base class for all persistent objects.

| Property | Type | Access |
|----------|------|--------|
| `id` | `ObjectIdentifier` | read-only |

### DatedObject : DatabaseObject

| Property | Type | Access |
|----------|------|--------|
| `added` | `Date \| null` | read-write |
| `modified` | `Date \| null` | read-write |

### ActiveObject : DatedObject

| Property | Type | Access |
|----------|------|--------|
| `active` | `Boolean` | read-write |
| `effectiveActive` | `Boolean` | read-only |
