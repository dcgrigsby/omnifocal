# OmniFocus Omni Automation API — Cheatsheet

> Compact reference for all classes, read-only properties, and relationships.
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

## Task : ActiveObject (read-only properties)

| Property | Type |
|----------|------|
| `children` | `TaskArray` |
| `completed` | `Boolean` |
| `completionDate` | `Date \| null` |
| `containingProject` | `Project \| null` |
| `effectiveCompletedDate` | `Date \| null` |
| `effectiveDeferDate` | `Date \| null` |
| `effectiveDropDate` | `Date \| null` |
| `effectiveDueDate` | `Date \| null` |
| `effectiveFlagged` | `Boolean` |
| `flattenedChildren` | `TaskArray` |
| `flattenedTasks` | `TaskArray` |
| `hasChildren` | `Boolean` |
| `inInbox` | `Boolean` |
| `linkedFileURLs` | `Array<URL>` |
| `notifications` | `Array<Task.Notification>` |
| `parent` | `Task \| null` |
| `project` | `Project \| null` |
| `tags` | `TagArray` |
| `taskStatus` | `Task.Status` |
| `tasks` | `TaskArray` |

**Task.Status**: `Available`, `Blocked`, `Completed`, `Dropped`, `DueSoon`, `Next`, `Overdue`

Read-write (for reference): `deferDate`, `dueDate`, `estimatedMinutes`, `flagged`, `name`, `note`, `sequential`

## Project : DatabaseObject (read-only properties)

| Property | Type |
|----------|------|
| `children` | `TaskArray` |
| `completed` | `Boolean` |
| `effectiveCompletedDate` | `Date \| null` |
| `effectiveDeferDate` | `Date \| null` |
| `effectiveDropDate` | `Date \| null` |
| `effectiveDueDate` | `Date \| null` |
| `effectiveFlagged` | `Boolean` |
| `flattenedChildren` | `TaskArray` |
| `flattenedTasks` | `TaskArray` |
| `hasChildren` | `Boolean` |
| `nextReviewDate` | `Date \| null` |
| `nextTask` | `Task \| null` |
| `notifications` | `Array<Task.Notification>` |
| `parentFolder` | `Folder \| null` |
| `tags` | `TagArray` |
| `task` | `Task` |
| `taskStatus` | `Task.Status` |
| `tasks` | `TaskArray` |

**Project.Status**: `Active`, `Done`, `Dropped`, `OnHold`

Read-write (for reference): `completionDate`, `deferDate`, `dueDate`, `estimatedMinutes`, `flagged`, `name`, `note`, `sequential`, `status`

## Folder : ActiveObject (read-only properties)

| Property | Type |
|----------|------|
| `children` | `SectionArray` |
| `flattenedChildren` | `SectionArray` |
| `flattenedFolders` | `FolderArray` |
| `flattenedProjects` | `ProjectArray` |
| `flattenedSections` | `SectionArray` |
| `folders` | `FolderArray` |
| `parent` | `Folder \| null` |
| `projects` | `ProjectArray` |
| `sections` | `SectionArray` |

Read-write (for reference): `name`, `status`

**Folder.Status**: `Active`, `Dropped`

## Tag : ActiveObject (read-only properties)

| Property | Type |
|----------|------|
| `allowsNextAction` | `Boolean` |
| `availableTasks` | `TaskArray` |
| `children` | `TagArray` |
| `flattenedChildren` | `TagArray` |
| `flattenedTags` | `TagArray` |
| `parent` | `Tag \| null` |
| `projects` | `ProjectArray` |
| `remainingTasks` | `TaskArray` |
| `tags` | `TagArray` |
| `tasks` | `TaskArray` |

Read-write (for reference): `name`, `status`

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
