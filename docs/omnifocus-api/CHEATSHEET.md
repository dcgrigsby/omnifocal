# OmniFocus Omni Automation API — Cheatsheet

> Compact reference for all classes, properties (read-only and read-write), and relationships.
> For full details on any class, see the individual reference files in this directory.
> Source: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)

## Globals

```javascript
document                          // DatabaseDocument
inbox                             // TaskArray (inbox tasks)
library                           // SectionArray (top-level library)
tags                              // TagArray (top-level tags)

flattenedTasks                    // TaskArray — all tasks
flattenedProjects                 // ProjectArray — all projects
flattenedFolders                  // FolderArray — all folders
flattenedSections                 // SectionArray — all sections
flattenedTags                     // TagArray — all tags
```

## Lookup & Search

```javascript
tagNamed(name: String)            // Tag | null
folderNamed(name: String)         // Folder | null
projectNamed(name: String)        // Project | null
taskNamed(name: String)           // Task | null

projectsMatching(search: String)  // Array<Project>
foldersMatching(search: String)   // Array<Folder>
tagsMatching(search: String)      // Array<Tag>
```

## Database (read-only properties)

| Property | Type |
|----------|------|
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

## Task : ActiveObject

| Property | Type | Access |
|----------|------|--------|
| `children` | `TaskArray` | read-only |
| `completed` | `Boolean` | read-only |
| `completionDate` | `Date \| null` | **read-write** |
| `containingProject` | `Project \| null` | read-only |
| `deferDate` | `Date \| null` | **read-write** |
| `dueDate` | `Date \| null` | **read-write** |
| `effectiveCompletedDate` | `Date \| null` | read-only |
| `effectiveDeferDate` | `Date \| null` | read-only |
| `effectiveDropDate` | `Date \| null` | read-only |
| `effectiveDueDate` | `Date \| null` | read-only |
| `effectiveFlagged` | `Boolean` | read-only |
| `estimatedMinutes` | `Number \| null` | **read-write** |
| `flagged` | `Boolean` | **read-write** |
| `flattenedChildren` | `TaskArray` | read-only |
| `flattenedTasks` | `TaskArray` | read-only |
| `hasChildren` | `Boolean` | read-only |
| `inInbox` | `Boolean` | read-only |
| `linkedFileURLs` | `Array<URL>` | read-only |
| `name` | `String` | **read-write** |
| `note` | `String` | **read-write** |
| `notifications` | `Array<Task.Notification>` | read-only |
| `parent` | `Task \| null` | read-only |
| `project` | `Project \| null` | read-only |
| `sequential` | `Boolean` | **read-write** |
| `tags` | `TagArray` | read-only |
| `taskStatus` | `Task.Status` | read-only |
| `tasks` | `TaskArray` | read-only |

**Mutating methods**: `markComplete()`, `markIncomplete()`, `drop(flag)`, `addTag(tag)`, `removeTag(tag)`, `clearTags()`, `appendStringToNote(string)`, `addLinkedFileURL(url)`, `removeLinkedFileURL(url)`, `save()`

**Constructors**: `new Task(name, position)` — create in inbox; `new Task(name, project)` — create in project

**Task.Status**: `Available`, `Blocked`, `Completed`, `Dropped`, `DueSoon`, `Next`, `Overdue`

## Project : DatabaseObject

| Property | Type | Access |
|----------|------|--------|
| `children` | `TaskArray` | read-only |
| `completed` | `Boolean` | read-only |
| `completionDate` | `Date \| null` | **read-write** |
| `deferDate` | `Date \| null` | **read-write** |
| `dueDate` | `Date \| null` | **read-write** |
| `effectiveCompletedDate` | `Date \| null` | read-only |
| `effectiveDeferDate` | `Date \| null` | read-only |
| `effectiveDropDate` | `Date \| null` | read-only |
| `effectiveDueDate` | `Date \| null` | read-only |
| `effectiveFlagged` | `Boolean` | read-only |
| `estimatedMinutes` | `Number \| null` | **read-write** |
| `flagged` | `Boolean` | **read-write** |
| `flattenedChildren` | `TaskArray` | read-only |
| `flattenedTasks` | `TaskArray` | read-only |
| `hasChildren` | `Boolean` | read-only |
| `name` | `String` | **read-write** |
| `nextReviewDate` | `Date \| null` | read-only |
| `nextTask` | `Task \| null` | read-only |
| `note` | `String` | **read-write** |
| `notifications` | `Array<Task.Notification>` | read-only |
| `parentFolder` | `Folder \| null` | read-only |
| `sequential` | `Boolean` | **read-write** |
| `status` | `Project.Status` | **read-write** |
| `tags` | `TagArray` | read-only |
| `task` | `Task` | read-only |
| `taskStatus` | `Task.Status` | read-only |
| `tasks` | `TaskArray` | read-only |

**Mutating methods**: `markComplete()`, `markIncomplete()`, `addTag(tag)`, `removeTag(tag)`, `save()`

**Constructors**: `new Project(name)`, `new Project(name, folder)`

**Project.Status**: `Active`, `Done`, `Dropped`, `OnHold`

## Folder : ActiveObject

| Property | Type | Access |
|----------|------|--------|
| `children` | `SectionArray` | read-only |
| `flattenedChildren` | `SectionArray` | read-only |
| `flattenedFolders` | `FolderArray` | read-only |
| `flattenedProjects` | `ProjectArray` | read-only |
| `flattenedSections` | `SectionArray` | read-only |
| `folders` | `FolderArray` | read-only |
| `name` | `String` | **read-write** |
| `parent` | `Folder \| null` | read-only |
| `projects` | `ProjectArray` | read-only |
| `sections` | `SectionArray` | read-only |
| `status` | `Folder.Status` | **read-write** |

**Constructors**: `new Folder(name)`, `new Folder(name, parentFolder)`

**Folder.Status**: `Active`, `Dropped`

## Tag : ActiveObject

| Property | Type | Access |
|----------|------|--------|
| `allowsNextAction` | `Boolean` | read-only |
| `availableTasks` | `TaskArray` | read-only |
| `children` | `TagArray` | read-only |
| `flattenedChildren` | `TagArray` | read-only |
| `flattenedTags` | `TagArray` | read-only |
| `name` | `String` | **read-write** |
| `parent` | `Tag \| null` | read-only |
| `projects` | `ProjectArray` | read-only |
| `remainingTasks` | `TaskArray` | read-only |
| `status` | `Tag.Status` | **read-write** |
| `tags` | `TagArray` | read-only |
| `tasks` | `TaskArray` | read-only |

**Constructors**: `new Tag(name)`, `new Tag(name, parentTag)`

**Tag.Status**: `Active`, `Dropped`, `OnHold`

Class property: `Tag.forecastTag` -> `Tag | null`

## Perspective.Custom : DatedObject

| Property | Type |
|----------|------|
| `identifier` | `String` (read-only) |
| `name` | `String` (read-only) |

Lookup: `Perspective.Custom.byName(name)`, `Perspective.Custom.byIdentifier(id)`, `Perspective.Custom.all`

**Perspective.BuiltIn**: `Flagged`, `Forecast`, `Inbox`, `Nearby`, `Projects`, `Review`, `Search`, `Tags`

## ForecastDay

| Property | Type |
|----------|------|
| `badgeCount` | `Number` (read-only) |
| `date` | `Date` (read-only) |
| `deferredCount` | `Number` (read-only) |
| `kind` | `ForecastDay.Kind` (read-only) |
| `name` | `String` (read-only) |

**ForecastDay.Kind**: `Day`, `DistantFuture`, `FutureMonth`, `Past`, `Today`

**ForecastDay.Status**: `Available`, `DueSoon`, `NoneAvailable`, `Overdue`

## Common Base Classes

**DatabaseObject**: `id` (ObjectIdentifier, read-only)

**DatedObject** extends DatabaseObject: `added`, `modified` (Date | null)

**ActiveObject** extends DatedObject: `active` (Boolean), `effectiveActive` (Boolean, read-only)

## Date & Time Helpers

```javascript
Calendar.current.startOfDay(date)
Calendar.current.dateByAddingDateComponents(date, components)
Calendar.current.dateComponentsBetweenDates(start, end)
new DateComponents()  // set .day, .month, .year, .hour, .minute, .second
Formatter.Date.withStyle(dateStyle, timeStyle)
Formatter.Date.withFormat("yyyy-MM-dd")
```
