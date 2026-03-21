# OmniFocus Omni Automation JavaScript API Reference

> Extracted from [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> API Version: 3.13.1 (Build 151.27.0)
> OmniFocus 4 additions (v4.7+) noted where applicable.

---

## Table of Contents

1. [Core Architecture](#core-architecture)
2. [Database](#database)
3. [Task](#task)
4. [Project](#project)
5. [Folder](#folder)
6. [Tag](#tag)
7. [Perspective](#perspective)
8. [Forecast](#forecast)
9. [Window & Selection](#window--selection)
10. [Tree & TreeNode](#tree--treenode)
11. [Array Types](#array-types)
12. [Collection Accessors](#collection-accessors)
13. [Application](#application)
14. [Document](#document)
15. [Alert](#alert)
16. [Form & Form Fields](#form--form-fields)
17. [Date & Time](#date--time)
18. [Formatter](#formatter)
19. [URL & Networking](#url--networking)
20. [File Operations](#file-operations)
21. [Text & Style](#text--style)
22. [Color](#color)
23. [Data & Crypto](#data--crypto)
24. [Email](#email)
25. [Speech](#speech)
26. [Device](#device)
27. [Pasteboard](#pasteboard)
28. [Settings & Preferences](#settings--preferences)
29. [Image](#image)
30. [Timer](#timer)
31. [Console](#console)
32. [Credentials](#credentials)
33. [SharePanel](#sharepanel)
34. [XML](#xml)
35. [Numeric Types](#numeric-types)
36. [Version](#version)
37. [Misc Types & Enums](#misc-types--enums)
38. [Error](#error)

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

---

## Task

### Task : ActiveObject

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `byParsingTransportText` | `(text: String, singleTask: Boolean \| null)` | `Array<Task>` |
| `byIdentifier` | `(identifier: String)` | `Task \| null` |

#### Constructor

```javascript
new Task(name: String, position: Project | Task | Task.ChildInsertionLocation | null)
```

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `taskNamed` | `(name: String)` | `Task \| null` |
| `childNamed` | `(name: String)` | `Task \| null` |
| `appendStringToNote` | `(stringToAppend: String)` | `void` |
| `addLinkedFileURL` | `(url: URL)` | `void` |
| `removeLinkedFileWithURL` | `(url: URL)` | `void` |
| `addAttachment` | `(attachment: FileWrapper)` | `void` |
| `removeAttachmentAtIndex` | `(index: Number)` | `void` |
| `addTag` | `(tag: Tag)` | `void` |
| `addTags` | `(tags: Array<Tag>)` | `void` |
| `removeTag` | `(tag: Tag)` | `void` |
| `removeTags` | `(tags: Array<Tag>)` | `void` |
| `clearTags` | `()` | `void` |
| `markComplete` | `(date: Date \| null)` | `Task` |
| `markIncomplete` | `()` | `void` |
| `drop` | `(allOccurrences: Boolean)` | `void` |
| `apply` | `(function: Function)` | `ApplyResult \| null` |
| `addNotification` | `(info: Number \| Date)` | `Task.Notification` |
| `removeNotification` | `(notification: Task.Notification)` | `void` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `after` | `Task.ChildInsertionLocation` |
| `before` | `Task.ChildInsertionLocation` |
| `beginning` | `Task.ChildInsertionLocation` |
| `children` | `TaskArray` |
| `completed` | `Boolean` |
| `completionDate` | `Date \| null` |
| `containingProject` | `Project \| null` |
| `effectiveCompletedDate` | `Date \| null` |
| `effectiveDeferDate` | `Date \| null` |
| `effectiveDropDate` | `Date \| null` |
| `effectiveDueDate` | `Date \| null` |
| `effectiveFlagged` | `Boolean` |
| `ending` | `Task.ChildInsertionLocation` |
| `flattenedChildren` | `TaskArray` |
| `flattenedTasks` | `TaskArray` |
| `hasChildren` | `Boolean` |
| `inInbox` | `Boolean` |
| `linkedFileURLs` | `Array<URL>` |
| `notifications` | `Array<Task.Notification>` |
| `parent` | `Task \| null` |
| `project` | `Project \| null` |
| `taskStatus` | `Task.Status` |
| `tags` | `TagArray` |
| `tasks` | `TaskArray` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `assignedContainer` | `Project \| Task \| Inbox \| null` |
| `attachments` | `Array<FileWrapper>` |
| `completedByChildren` | `Boolean` |
| `deferDate` | `Date \| null` |
| `dropDate` | `Date \| null` |
| `dueDate` | `Date \| null` |
| `estimatedMinutes` | `Number \| null` |
| `flagged` | `Boolean` |
| `name` | `String` |
| `note` | `String` |
| `repetitionRule` | `Task.RepetitionRule \| null` |
| `sequential` | `Boolean` |
| `shouldUseFloatingTimeZone` | `Boolean` |

### Task.Status

| Value | Description |
|-------|-------------|
| `Available` | The task is available to work on |
| `Blocked` | Not available due to future defer date, preceding task in sequential project, or on-hold tag |
| `Completed` | Already completed |
| `Dropped` | Will not be worked on |
| `DueSoon` | Incomplete and due soon |
| `Next` | First available task in a project |
| `Overdue` | Incomplete and overdue |
| `all` | Array of all values |

### Task.ChildInsertionLocation

Opaque location reference returned by `before`, `after`, `beginning`, `ending` properties. Used as position argument for constructors and move operations.

### Task.Notification : DatedObject

#### Properties (read-write)

| Property | Type |
|----------|------|
| `absoluteFireDate` | `Date` |
| `relativeFireOffset` | `Number` |
| `repeatInterval` | `Number` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `initialFireDate` | `Date` |
| `isSnoozed` | `Boolean` |
| `kind` | `Task.Notification.Kind` |
| `nextFireDate` | `Date \| null` |
| `task` | `Task \| null` |
| `usesFloatingTimeZone` | `Boolean` |

### Task.Notification.Kind

| Value | Description |
|-------|-------------|
| `all` | Array of all values |

(Specific kind values not fully enumerated in the API reference.)

### Task.RepetitionMethod

| Value | Description |
|-------|-------------|
| `DeferUntilDate` | Repeat based on defer date |
| `DueDate` | Repeat based on due date |
| `Fixed` | Fixed repetition interval |
| `None` | Task does not repeat |
| `all` | Array of all values |

> **Note**: `Task.RepetitionMethod` is deprecated in OmniFocus 4.7+. Use `Task.RepetitionScheduleType` and `Task.AnchorDateKey` instead.

### Task.RepetitionRule

#### Constructor

```javascript
// Legacy (v3.x)
new Task.RepetitionRule(ruleString: String, method: Task.RepetitionMethod)

// Modern (v4.7+)
new Task.RepetitionRule(
  ruleString: String | null,
  method: Task.RepetitionMethod | null,        // deprecated, pass null
  scheduleType: Task.RepetitionScheduleType | null,
  anchorDateKey: Task.AnchorDateKey | null,
  catchUpAutomatically: Boolean | null
)
```

#### Properties (read-only)

| Property | Type | Notes |
|----------|------|-------|
| `ruleString` | `String` | ICS formatted recurrence string (RFC 5545) |
| `method` | `Task.RepetitionMethod` | Deprecated in v4.7+ |
| `scheduleType` | `Task.RepetitionScheduleType` | v4.7+ |
| `anchorDateKey` | `Task.AnchorDateKey` | v4.7+ |
| `catchUpAutomatically` | `Boolean` | v4.7+ - auto-skips past occurrences |

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `firstDateAfterDate` | `(date: Date)` | `Date` |

### Task.RepetitionScheduleType (v4.7+)

| Value | Description |
|-------|-------------|
| `Fixed` | Fixed schedule |
| `Regularly` | Regular repetition |
| `all` | Array of all values |

### Task.AnchorDateKey (v4.7+)

| Value | Description |
|-------|-------------|
| `DeferDate` | Anchor to defer date |
| `DueDate` | Anchor to due date |
| `all` | Array of all values |

### ICS Recurrence Rule Strings

The `ruleString` parameter uses RFC 5545 recurrence rules:

```
FREQ=DAILY                          // Every day
FREQ=WEEKLY                         // Every week
FREQ=WEEKLY;INTERVAL=2              // Every 2 weeks
FREQ=MONTHLY                        // Every month
FREQ=MONTHLY;BYMONTHDAY=15          // 15th of every month
FREQ=YEARLY                         // Every year
FREQ=WEEKLY;BYDAY=MO,WE,FR          // Mon, Wed, Fri
```

---

## Project

### Project : DatabaseObject

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `byIdentifier` | `(identifier: String)` | `Project \| null` |

#### Constructor

```javascript
new Project(name: String, position: Folder | Folder.ChildInsertionLocation | null)
```

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `taskNamed` | `(name: String)` | `Task \| null` |
| `appendStringToNote` | `(stringToAppend: String)` | `void` |
| `addAttachment` | `(attachment: FileWrapper)` | `void` |
| `removeAttachmentAtIndex` | `(index: Number)` | `void` |
| `markComplete` | `(date: Date \| null)` | `Task` |
| `markIncomplete` | `()` | `void` |
| `addNotification` | `(info: Number \| Date)` | `Task.Notification` |
| `removeNotification` | `(notification: Task.Notification)` | `void` |
| `addTag` | `(tag: Tag)` | `void` |
| `addTags` | `(tags: Array<Tag>)` | `void` |
| `removeTag` | `(tag: Tag)` | `void` |
| `removeTags` | `(tags: Array<Tag>)` | `void` |
| `clearTags` | `()` | `void` |
| `addLinkedFileURL` | `(url: URL)` | `void` |
| `removeLinkedFileWithURL` | `(url: URL)` | `void` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `after` | `Folder.ChildInsertionLocation` |
| `before` | `Folder.ChildInsertionLocation` |
| `beginning` | `Task.ChildInsertionLocation` |
| `children` | `TaskArray` |
| `completed` | `Boolean` |
| `effectiveCompletedDate` | `Date \| null` |
| `effectiveDeferDate` | `Date \| null` |
| `effectiveDropDate` | `Date \| null` |
| `effectiveDueDate` | `Date \| null` |
| `effectiveFlagged` | `Boolean` |
| `ending` | `Task.ChildInsertionLocation` |
| `flattenedChildren` | `TaskArray` |
| `flattenedTasks` | `TaskArray` |
| `hasChildren` | `Boolean` |
| `linkedFileURLs` | `Array<URL>` |
| `nextReviewDate` | `Date \| null` |
| `nextTask` | `Task \| null` |
| `notifications` | `Array<Task.Notification>` |
| `parentFolder` | `Folder \| null` |
| `tags` | `TagArray` |
| `task` | `Task` |
| `taskStatus` | `Task.Status` |
| `tasks` | `TaskArray` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `attachments` | `Array<FileWrapper>` |
| `completedByChildren` | `Boolean` |
| `completionDate` | `Date \| null` |
| `containsSingletonActions` | `Boolean` |
| `defaultSingletonActionHolder` | `Boolean` |
| `deferDate` | `Date \| null` |
| `dropDate` | `Date \| null` |
| `dueDate` | `Date \| null` |
| `estimatedMinutes` | `Number \| null` |
| `flagged` | `Boolean` |
| `lastReviewDate` | `Date \| null` |
| `name` | `String` |
| `note` | `String` |
| `repetitionRule` | `Task.RepetitionRule \| null` |
| `reviewInterval` | `Project.ReviewInterval` |
| `sequential` | `Boolean` |
| `shouldUseFloatingTimeZone` | `Boolean` |
| `status` | `Project.Status` |

### Project.Status

| Value | Description |
|-------|-------------|
| `Active` | Default status for new or ongoing projects |
| `Done` | Project successfully completed |
| `Dropped` | Project will not be continued |
| `OnHold` | Project paused, may resume |
| `all` | Array of all values |

### Project.ReviewInterval

| Property | Type | Description |
|----------|------|-------------|
| `steps` | `Number` | Count of units (e.g. 14 days, 12 months) |
| `unit` | `String` | Unit type: `"days"`, `"weeks"`, `"months"`, `"years"` |

---

## Folder

### Folder : ActiveObject

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `byIdentifier` | `(identifier: String)` | `Folder \| null` |

#### Constructor

```javascript
new Folder(name: String, position: Folder | Folder.ChildInsertionLocation | null)
```

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `folderNamed` | `(name: String)` | `Folder \| null` |
| `projectNamed` | `(name: String)` | `Project \| null` |
| `sectionNamed` | `(name: String)` | `Project \| Folder \| null` |
| `childNamed` | `(name: String)` | `Project \| Folder \| null` |
| `apply` | `(function: Function)` | `ApplyResult \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `after` | `Folder.ChildInsertionLocation` |
| `before` | `Folder.ChildInsertionLocation` |
| `beginning` | `Folder.ChildInsertionLocation` |
| `children` | `SectionArray` |
| `ending` | `Folder.ChildInsertionLocation` |
| `flattenedChildren` | `SectionArray` |
| `flattenedFolders` | `FolderArray` |
| `flattenedProjects` | `ProjectArray` |
| `flattenedSections` | `SectionArray` |
| `folders` | `FolderArray` |
| `parent` | `Folder \| null` |
| `projects` | `ProjectArray` |
| `sections` | `SectionArray` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `name` | `String` |
| `status` | `Folder.Status` |

### Folder.Status

| Value | Description |
|-------|-------------|
| `Active` | The folder is active |
| `Dropped` | The folder has been dropped |
| `all` | Array of all values |

### Folder.ChildInsertionLocation

Opaque location reference for inserting children into folders.

---

## Tag

### Tag : ActiveObject

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `byIdentifier` | `(identifier: String)` | `Tag \| null` |

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `forecastTag` | `Tag \| null` |

#### Constructor

```javascript
new Tag(name: String, position: Tag | Tag.ChildInsertionLocation | null)
```

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `tagNamed` | `(name: String)` | `Tag \| null` |
| `childNamed` | `(name: String)` | `Tag \| null` |
| `apply` | `(function: Function)` | `ApplyResult \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `after` | `Tag.ChildInsertionLocation` |
| `allowsNextAction` | `Boolean` |
| `availableTasks` | `TaskArray` |
| `before` | `Tag.ChildInsertionLocation` |
| `beginning` | `Tag.ChildInsertionLocation` |
| `children` | `TagArray` |
| `ending` | `Tag.ChildInsertionLocation` |
| `flattenedChildren` | `TagArray` |
| `flattenedTags` | `TagArray` |
| `parent` | `Tag \| null` |
| `projects` | `ProjectArray` |
| `remainingTasks` | `TaskArray` |
| `tags` | `TagArray` |
| `tasks` | `TaskArray` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `name` | `String` |
| `status` | `Tag.Status` |

### Tag.Status

| Value | Description |
|-------|-------------|
| `Active` | The tag is active |
| `Dropped` | The tag has been dropped |
| `OnHold` | The tag has been put on hold |
| `all` | Array of all values |

### Tag.ChildInsertionLocation

Opaque location reference for inserting child tags.

---

## Perspective

### Perspective.BuiltIn

| Value | Description |
|-------|-------------|
| `Flagged` | Flagged items |
| `Forecast` | Upcoming due items |
| `Inbox` | The inbox of tasks |
| `Nearby` | Nearby items on a map (iOS only) |
| `Projects` | The library of projects |
| `Review` | Projects needing review |
| `Search` | Database search (read-only, appears when user searches) |
| `Tags` | The hierarchy of tags |

Transient reference perspectives: `Completed`, `Changed`.

### Perspective.Custom : DatedObject

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `Perspective.Custom \| null` |
| `byIdentifier` | `(identifier: String)` | `Perspective.Custom \| null` |

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `all` | `Array<Perspective.Custom>` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `fileWrapper` | `()` | `FileWrapper` |
| `writeFileRepresentationIntoDirectory` | `(parentURL: URL)` | `URL` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `identifier` | `String` |
| `name` | `String` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `iconColor` | `Color \| null` |
| `archivedFilterRules` | `Object` |
| `archivedTopLevelFilterAggregation` | `String \| null` |

---

## Forecast

### ForecastDay

#### Class Properties

| Property | Type | Access |
|----------|------|--------|
| `badgeCountsIncludeDeferredItems` | `Boolean` | read-write |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `badgeKind` | `()` | `ForecastDay.Status` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `badgeCount` | `Number` |
| `date` | `Date` |
| `deferredCount` | `Number` |
| `kind` | `ForecastDay.Kind` |
| `name` | `String` |

### ForecastDay.Kind

| Value | Description |
|-------|-------------|
| `Day` | A regular day |
| `DistantFuture` | The distant future bucket |
| `FutureMonth` | A future month bucket |
| `Past` | The past bucket |
| `Today` | Today |
| `all` | Array of all values |

### ForecastDay.Status

| Value | Description |
|-------|-------------|
| `Available` | Tasks available |
| `DueSoon` | Tasks due soon |
| `NoneAvailable` | No tasks available |
| `Overdue` | Tasks overdue |
| `all` | Array of all values |

---

## Window & Selection

### Window

| Property | Type | Access |
|----------|------|--------|
| `document` | `Document \| null` | read-only |

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `close` | `()` | `void` |

### DocumentWindow : Window

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `close` | `()` | `void` |
| `selectObjects` | `(objects: Array<DatabaseObject>)` | `void` |
| `forecastDayForDate` | `(date: Date)` | `ForecastDay` |
| `selectForecastDays` | `(days: Array<ForecastDay>)` | `void` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `content` | `ContentTree \| null` | read-only |
| `focus` | `Array<Project \| Folder> \| null` | read-write |
| `inspectorVisible` | `Boolean` | read-write |
| `isCompact` | `Boolean` | read-only |
| `isTab` | `Boolean` | read-only |
| `perspective` | `Perspective.BuiltIn \| Perspective.Custom \| null` | read-write |
| `selection` | `Selection` | read-only |
| `sidebar` | `SidebarTree \| null` | read-only |
| `sidebarVisible` | `Boolean` | read-write |
| `tabGroupWindows` | `Array<DocumentWindow>` | read-only |
| `toolbarVisible` | `Boolean` | read-write |

### Selection

| Property | Type | Access |
|----------|------|--------|
| `tasks` | `TaskArray` | read-only |
| `projects` | `ProjectArray` | read-only |
| `folders` | `FolderArray` | read-only |
| `tags` | `TagArray` | read-only |
| `databaseObjects` | `Array<DatabaseObject>` | read-only |
| `allObjects` | `Array<Object>` | read-only |

### DatabaseDocument : Document

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `newWindow` | `()` | `Promise<DocumentWindow>` |
| `newTabOnWindow` | `(window: DocumentWindow)` | `Promise<DocumentWindow>` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `windows` | `Array<DocumentWindow>` |

---

## Tree & TreeNode

### Tree

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `apply` | `(function: Function)` | `ApplyResult \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `nodes` | `Array<TreeNode>` |

### ContentTree : Tree

| Property | Type | Access |
|----------|------|--------|
| `selectedNodes` | `Array<TreeNode>` | read-only |

### SidebarTree : Tree

| Property | Type | Access |
|----------|------|--------|
| `selectedNodes` | `Array<TreeNode>` | read-only |

### TreeNode

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `descendantsNumber` | `()` | `Number` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `object` | `DatabaseObject \| DatabaseDocument \| Perspective.Custom \| null` | read-only |
| `parent` | `TreeNode \| null` | read-only |
| `children` | `Array<TreeNode>` | read-only |
| `descendantCount` | `Number` | read-only |
| `isExpanded` | `Boolean` | read-write |

### ApplyResult

Used as return value from `apply()` callbacks to control tree traversal.

| Value | Description |
|-------|-------------|
| `SkipChildren` | Skip children of current node |
| `SkipPeers` | Skip peer nodes |
| `Stop` | Stop traversal entirely |
| `all` | Array of all values |

---

## Array Types

All array types extend JavaScript `Array` with a `byName` convenience method.

### TaskArray : Array

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `Task \| null` |

### ProjectArray : Array

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `Project \| null` |

### FolderArray : Array

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `Folder \| null` |

### SectionArray : Array

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `Project \| Folder \| null` |

### TagArray : Array

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `Tag \| null` |

---

## Collection Accessors

### Inbox : TaskArray

| Method | Signature | Returns |
|--------|-----------|---------|
| `apply` | `(function: Function)` | `ApplyResult \| null` |

| Property | Type | Access |
|----------|------|--------|
| `beginning` | `Task.ChildInsertionLocation` | read-only |
| `ending` | `Task.ChildInsertionLocation` | read-only |

### Library : SectionArray

| Method | Signature | Returns |
|--------|-----------|---------|
| `apply` | `(function: Function)` | `ApplyResult \| null` |

| Property | Type | Access |
|----------|------|--------|
| `beginning` | `Folder.ChildInsertionLocation` | read-only |
| `ending` | `Folder.ChildInsertionLocation` | read-only |

### Tags : TagArray

| Method | Signature | Returns |
|--------|-----------|---------|
| `apply` | `(function: Function)` | `ApplyResult \| null` |

| Property | Type | Access |
|----------|------|--------|
| `beginning` | `Tag.ChildInsertionLocation` | read-only |
| `ending` | `Tag.ChildInsertionLocation` | read-only |

---

## Application

### Application

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `openDocument` | `(from: Document \| null, url: URL, completed: Function)` | `void` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `buildVersion` | `Version` |
| `commandKeyDown` | `Boolean` |
| `controlKeyDown` | `Boolean` |
| `name` | `String` |
| `optionKeyDown` | `Boolean` |
| `platformName` | `String` |
| `shiftKeyDown` | `Boolean` |
| `userVersion` | `Version` |
| `version` | `String` (deprecated) |

---

## Document

### Document

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `makeNew` | `(resultFunction: Function(document: Document \| Error) \| null)` | `Promise<Document>` |
| `makeNewAndShow` | `(resultFunction: Function(document: Document \| Error) \| null)` | `Promise<Document>` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `close` | `(didCancel: Function(document: Document) \| null)` | `void` |
| `save` | `()` | `void` |
| `fileWrapper` | `(type: String \| null)` | `FileWrapper` (deprecated) |
| `makeFileWrapper` | `(baseName: String, type: String \| null)` | `Promise<FileWrapper>` |
| `undo` | `()` | `void` |
| `redo` | `()` | `void` |
| `show` | `(completed: Function() \| null)` | `void` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `canRedo` | `Boolean` |
| `canUndo` | `Boolean` |
| `fileType` | `String \| null` |
| `name` | `String \| null` |
| `writableTypes` | `Array<String>` |

---

## Alert

### Alert

#### Constructor

```javascript
new Alert(title: String, message: String)
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `show` | `(callback: Function(option: Number) \| null)` | `Promise<Number>` |
| `addOption` | `(string: String)` | `void` |

---

## Form & Form Fields

### Form

#### Constructor

```javascript
new Form()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `addField` | `(field: Form.Field, index: Number \| null)` | `void` |
| `removeField` | `(field: Form.Field)` | `void` |
| `show` | `(title: String, confirmTitle: String)` | `Promise<Form>` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `fields` | `Array<Form.Field>` | read-only |
| `values` | `Object` | read-only |
| `validate` | `Function(form: Form): Boolean \| null` | read-write |

### Form.Field (base class)

| Property | Type | Access |
|----------|------|--------|
| `displayName` | `String \| null` | read-only |
| `key` | `String` | read-only |

### Form.Field.Checkbox : Form.Field

```javascript
new Form.Field.Checkbox(key: String, displayName: String | null, value: Boolean | null)
```

### Form.Field.Date : Form.Field

```javascript
new Form.Field.Date(key: String, displayName: String | null, value: Date | null, formatter: Formatter.Date | null)
```

### Form.Field.MultipleOptions : Form.Field

```javascript
new Form.Field.MultipleOptions(key: String, displayName: String | null, options: Array<Object>, names: Array<String> | null, selected: Array<Object>)
```

### Form.Field.Option : Form.Field

```javascript
new Form.Field.Option(key: String, displayName: String | null, options: Array<Object>, names: Array<String> | null, selected: Object | null, nullOptionTitle: String | null)
```

| Property | Type | Access |
|----------|------|--------|
| `allowsNull` | `Boolean` | read-write |
| `nullOptionTitle` | `String \| null` | read-write |

### Form.Field.Password : Form.Field

```javascript
new Form.Field.Password(key: String, displayName: String | null, value: String | null)
```

### Form.Field.String : Form.Field

```javascript
new Form.Field.String(key: String, displayName: String | null, value: Object | null, formatter: Formatter | null)
```

---

## Date & Time

### Calendar

#### Class Properties (read-only)

`buddhist`, `chinese`, `coptic`, `current`, `ethiopicAmeteAlem`, `ethiopicAmeteMihret`, `gregorian`, `hebrew`, `indian`, `islamic`, `islamicCivil`, `islamicTabular`, `islamicUmmAlQura`, `iso8601`, `japanese`, `persian`, `republicOfChina`

All of type `Calendar`.

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `dateByAddingDateComponents` | `(date: Date, components: DateComponents)` | `Date \| null` |
| `dateFromDateComponents` | `(components: DateComponents)` | `Date \| null` |
| `dateComponentsFromDate` | `(date: Date)` | `DateComponents` |
| `dateComponentsBetweenDates` | `(start: Date, end: Date)` | `DateComponents` |
| `startOfDay` | `(date: Date)` | `Date` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `identifier` | `String` |
| `locale` | `Locale \| null` |
| `timeZone` | `TimeZone` |

### DateComponents

#### Constructor

```javascript
new DateComponents()
```

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `date` | `Date \| null` | read-only |
| `day` | `Number \| null` | read-write |
| `era` | `Number \| null` | read-write |
| `hour` | `Number \| null` | read-write |
| `minute` | `Number \| null` | read-write |
| `month` | `Number \| null` | read-write |
| `nanosecond` | `Number \| null` | read-write |
| `second` | `Number \| null` | read-write |
| `timeZone` | `TimeZone \| null` | read-write |
| `year` | `Number \| null` | read-write |

### DateRange

| Property | Type | Access |
|----------|------|--------|
| `end` | `Date` | read-only |
| `name` | `String` | read-only |
| `start` | `Date` | read-only |

### TimeZone

Time zone abstraction. Used with `Calendar` and `DateComponents`.

### Locale

Locale information abstraction. Available on `Calendar.locale`.

---

## Formatter

### Formatter

Base class for formatters. Cannot be instantiated directly.

### Formatter.Date : Formatter

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `withStyle` | `(dateStyle: Formatter.Date.Style, timeStyle: Formatter.Date.Style \| null)` | `Formatter.Date` |
| `withFormat` | `(format: String)` | `Formatter.Date` |

### Formatter.Date.Style

| Value | Description |
|-------|-------------|
| `Full` | Full date/time style |
| `Long` | Long date/time style |
| `Medium` | Medium date/time style |
| `Short` | Short date/time style |
| `all` | Array of all values |

### Formatter.Decimal : Formatter

Decimal number formatter for localized number display.

### Formatter.Duration : Formatter

Duration formatter for time interval display.

---

## URL & Networking

### URL

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `fromString` | `(string: String)` | `URL \| null` |
| `getCurrentAppSchemeURL` | `()` | `URL` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `appendPathComponent` | `(component: String)` | `URL` |
| `appendPathExtension` | `(ext: String)` | `URL \| null` |
| `getBookmark` | `()` | `URL.Bookmark` |
| `readBookmark` | `(bookmark: URL.Bookmark)` | `URL \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `absoluteString` | `String \| null` |
| `components` | `URL.Components \| null` |
| `host` | `String \| null` |
| `lastPathComponent` | `String \| null` |
| `path` | `String \| null` |
| `pathComponents` | `Array<String>` |
| `pathExtension` | `String \| null` |
| `scheme` | `String \| null` |
| `standardizedFileSystemRepresentation` | `String \| null` |
| `URLByDeletingLastPathComponent` | `URL \| null` |
| `URLByDeletingPathExtension` | `URL \| null` |
| `URLByStandardizingPath` | `URL \| null` |

### URL.Access

| Value | Description |
|-------|-------------|
| `Read` | Read access |
| `Write` | Write access |
| `all` | Array of all values |

### URL.Bookmark

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `resolveURL` | `()` | `URL \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `data` | `Data` |

### URL.Components

#### Properties (all read-write)

| Property | Type |
|----------|------|
| `fragment` | `String \| null` |
| `host` | `String \| null` |
| `password` | `String \| null` |
| `path` | `String \| null` |
| `port` | `Number \| null` |
| `query` | `String \| null` |
| `queryItems` | `Array<URL.QueryItem> \| null` |
| `scheme` | `String \| null` |
| `user` | `String \| null` |

### URL.FetchRequest

#### Constructor

```javascript
new URL.FetchRequest(url: URL)
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `fetch` | `(completionHandler: Function(response: URL.FetchResponse \| Error) \| null)` | `Promise<URL.FetchResponse>` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `url` | `URL` | read-only |
| `method` | `String` | read-write |
| `headers` | `Object` | read-write |
| `body` | `Data \| null` | read-write |
| `cachePolicy` | `Number` | read-write |

### URL.FetchResponse

#### Properties (read-only)

| Property | Type |
|----------|------|
| `statusCode` | `Number` |
| `headers` | `Object` |
| `body` | `Data` |
| `bodyString` | `String \| null` |

### URL.QueryItem

#### Constructor

```javascript
new URL.QueryItem(name: String, value: String | null)
```

#### Properties (read-only)

| Property | Type |
|----------|------|
| `name` | `String` |
| `value` | `String \| null` |

---

## File Operations

### FilePicker

#### Constructor

```javascript
new FilePicker()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `show` | `()` | `Promise<Array<URL>>` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `folders` | `Boolean` |
| `message` | `String` |
| `multiple` | `Boolean` |
| `types` | `Array<TypeIdentifier> \| null` |

### FileSaver

#### Constructor

```javascript
new FileSaver()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `show` | `(fileWrapper: FileWrapper)` | `Promise<URL>` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `message` | `String` |
| `nameLabel` | `String` |
| `prompt` | `String` |
| `types` | `Array<TypeIdentifier> \| null` |

### FileWrapper

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `withContents` | `(name: String \| null, contents: Data)` | `FileWrapper` |
| `withChildren` | `(name: String \| null, children: Array<FileWrapper>)` | `FileWrapper` |
| `fromURL` | `(url: URL, options: Array<FileWrapper.ReadingOptions> \| null)` | `FileWrapper` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `childNamed` | `(name: String)` | `FileWrapper \| null` |
| `filenameForChild` | `(child: FileWrapper)` | `String \| null` |
| `write` | `(url: URL, options: Array<FileWrapper.WritingOptions> \| null, originalContentsURL: URL \| null)` | `void` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `children` | `Array<FileWrapper>` | read-only |
| `contents` | `Data \| null` | read-only |
| `destination` | `URL \| null` | read-only |
| `type` | `FileWrapper.Type` | read-only |
| `filename` | `String \| null` | read-write |
| `preferredFilename` | `String \| null` | read-write |

### FileWrapper.ReadingOptions

| Value |
|-------|
| `Immediate` |
| `WithoutMapping` |
| `all` |

### FileWrapper.Type

| Value |
|-------|
| `Directory` |
| `File` |
| `Link` |
| `all` |

### FileWrapper.WritingOptions

| Value |
|-------|
| `Atomic` |
| `UpdateNames` |
| `all` |

### TypeIdentifier

File type identifier for specifying acceptable file types in pickers.

---

## Text & Style

### Text

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `find` | `(searchText: String, options: Array<Text.FindOption> \| null, range: Text.Range \| null)` | `Text.Range \| null` |
| `replace` | `(range: Text.Range, replacementText: String)` | `void` |
| `append` | `(text: String)` | `void` |
| `prepend` | `(text: String)` | `void` |
| `removeRange` | `(range: Text.Range)` | `void` |
| `addStyle` | `(style: Style, range: Text.Range \| null)` | `void` |
| `removeStyle` | `(style: Style, range: Text.Range \| null)` | `void` |
| `styleAtPosition` | `(position: Text.Position)` | `Style \| null` |
| `styleInRange` | `(range: Text.Range)` | `Array<Style>` |
| `copy` | `(range: Text.Range \| null)` | `Text` |
| `stringInRange` | `(range: Text.Range \| null)` | `String` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `string` | `String` |
| `length` | `Number` |
| `beginning` | `Text.Position` |
| `ending` | `Text.Position` |

### Text.FindOption

| Value |
|-------|
| `BackwardsSearch` |
| `CaseInsensitive` |
| `RegularExpression` |
| `all` |

### Text.Position

| Property | Type | Access |
|----------|------|--------|
| `offset` | `Number` | read-only |

### Text.Range

| Property | Type | Access |
|----------|------|--------|
| `start` | `Text.Position` | read-only |
| `end` | `Text.Position` | read-only |
| `string` | `String` | read-only |

### TextAlignment

| Value |
|-------|
| `Center` |
| `Justified` |
| `Left` |
| `Natural` |
| `Right` |
| `all` |

### TextComponent

| Value |
|-------|
| `Attachment` |
| `Text` |
| `all` |

### Style

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `addAttribute` | `(attribute: Style.Attribute, value: Object \| null)` | `void` |
| `removeAttribute` | `(attribute: Style.Attribute)` | `void` |
| `attributeForName` | `(name: String)` | `Object \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `attributes` | `Object` |

### NamedStyle : Style

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `byName` | `(name: String)` | `NamedStyle \| null` |

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `all` | `Array<NamedStyle>` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `name` | `String` |

### NamedStyle.List

| Value |
|-------|
| `Body` |
| `Heading1` |
| `Heading2` |
| `Heading3` |
| `Heading4` |
| `Heading5` |
| `Heading6` |
| `all` |

### Style.Attribute

| Value |
|-------|
| `BackgroundColor` |
| `Bold` |
| `Font` |
| `ForegroundColor` |
| `Italic` |
| `Ligature` |
| `Link` |
| `ParagraphAlignment` |
| `ParagraphIndentation` |
| `Strikethrough` |
| `StrikethroughColor` |
| `Underline` |
| `UnderlineColor` |
| `UnderlineStyle` |
| `all` |

---

## Color

### Color

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `RGB` | `(r: Number, g: Number, b: Number, a: Number \| null)` | `Color` |
| `HSB` | `(h: Number, s: Number, b: Number, a: Number \| null)` | `Color` |
| `White` | `(w: Number, a: Number \| null)` | `Color` |

#### Class Properties (read-only)

`black`, `blue`, `brown`, `clear`, `cyan`, `darkGray`, `gray`, `green`, `lightGray`, `magenta`, `orange`, `purple`, `red`, `white`, `yellow`

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `blend` | `(otherColor: Color, fraction: Number)` | `Color \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `alpha` | `Number` |
| `blue` | `Number` |
| `brightness` | `Number` |
| `colorSpace` | `ColorSpace` |
| `green` | `Number` |
| `hue` | `Number` |
| `red` | `Number` |
| `saturation` | `Number` |
| `white` | `Number` |

### ColorSpace

| Value |
|-------|
| `CMYK` |
| `HSB` |
| `Named` |
| `Pattern` |
| `RGB` |
| `White` |
| `all` |

---

## Data & Crypto

### Data

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `fromString` | `(string: String, encoding: StringEncoding \| null)` | `Data` |
| `fromBase64` | `(string: String)` | `Data` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `toString` | `(encoding: StringEncoding \| null)` | `String` |
| `toBase64` | `()` | `String` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `length` | `Number` |
| `toObject` | `Object \| null` |

### Crypto

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `randomData` | `(length: Number)` | `Data` |

### Crypto.SHA256 / Crypto.SHA384 / Crypto.SHA512

All three share the same interface:

#### Constructor

```javascript
new Crypto.SHA256()
new Crypto.SHA384()
new Crypto.SHA512()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `update` | `(data: Data)` | `void` |
| `finalize` | `()` | `Data` |

### StringEncoding

String encoding enum. Used with `Data.fromString()` and `Data.toString()`.

---

## Email

### Email

#### Constructor

```javascript
new Email()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `generate` | `()` | `void` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `blindCarbonCopy` | `String \| Array<String> \| null` |
| `body` | `String \| null` |
| `carbonCopy` | `String \| Array<String> \| null` |
| `fileWrappers` | `Array<FileWrapper>` |
| `receiver` | `String \| Array<String> \| null` |
| `subject` | `String \| null` |

---

## Speech

### Speech.Synthesizer

#### Constructor

```javascript
new Speech.Synthesizer()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `speak` | `(utterance: Speech.Utterance)` | `void` |
| `cancel` | `()` | `void` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `isSpeaking` | `Boolean` |
| `isPaused` | `Boolean` |

### Speech.Utterance

#### Constructor

```javascript
new Speech.Utterance(string: String)
```

#### Properties (read-write)

| Property | Type |
|----------|------|
| `string` | `String` |
| `voice` | `Speech.Voice \| null` |
| `rate` | `Number` |
| `pitchMultiplier` | `Number` |
| `preUtteranceDelay` | `Number` |
| `postUtteranceDelay` | `Number` |

### Speech.Voice

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `voiceWithIdentifier` | `(identifier: String)` | `Speech.Voice \| null` |
| `voiceWithLanguage` | `(language: String)` | `Speech.Voice \| null` |

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `current` | `Speech.Voice \| null` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `identifier` | `String` |
| `name` | `String` |
| `language` | `String` |
| `gender` | `Speech.Voice.Gender` |
| `age` | `Number` |

### Speech.Voice.Gender

| Value |
|-------|
| `Female` |
| `Male` |
| `Neutral` |
| `Unspecified` |
| `all` |

### Speech.Boundary

| Value |
|-------|
| `Intonation` |
| `Sentence` |
| `Word` |
| `all` |

### Audio

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `playAlert` | `(alert: Audio.Alert \| null, completed: Function \| null)` | `void` |

### Audio.Alert

#### Constructor

```javascript
new Audio.Alert(url: URL)
```

---

## Device

### Device

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `current` | `Device` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `iOS` | `Boolean` |
| `iPad` | `Boolean` |
| `mac` | `Boolean` |
| `operatingSystemVersion` | `Version` |
| `type` | `DeviceType \| null` |

### DeviceType

| Value |
|-------|
| `iPad` |
| `iPhone` |
| `mac` |
| `all` |

---

## Pasteboard

### Pasteboard

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `general` | `Pasteboard` |
| `find` | `Pasteboard` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `clear` | `()` | `void` |
| `setString` | `(string: String, forType: String)` | `void` |
| `setStringArray` | `(strings: Array<String>, forType: String)` | `void` |
| `setData` | `(data: Data, forType: String)` | `void` |
| `removeType` | `(type: String)` | `void` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `types` | `Array<String>` |
| `items` | `Array<Pasteboard.Item>` |

### Pasteboard.Item

#### Properties (read-only)

| Property | Type |
|----------|------|
| `types` | `Array<String>` |
| `strings` | `Object` |
| `data` | `Object` |

---

## Settings & Preferences

### Settings

| Method | Signature | Returns |
|--------|-----------|---------|
| `write` | `(key: String, value: Object \| null)` | `void` |
| `read` | `(key: String)` | `Object \| null` |

### Preferences

| Method | Signature | Returns |
|--------|-----------|---------|
| `write` | `(key: String, value: Object \| null)` | `void` |
| `read` | `(key: String)` | `Object \| null` |

---

## Image

### Image

#### Constructors

```javascript
new Image(url: URL)
new Image(size: Object, colorHandler: Function(rect: Object))
```

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `withData` | `(data: Data)` | `Image` |

#### Properties (read-only)

| Property | Type |
|----------|------|
| `size` | `Object` |

---

## Timer

### Timer

#### Constructor

```javascript
new Timer(interval: Number)
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `invalidate` | `()` | `void` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `fireDate` | `Date` | read-write |
| `tolerance` | `Number` | read-write |
| `action` | `Function() \| null` | read-write |
| `repeats` | `Boolean` | read-write |
| `isValid` | `Boolean` | read-only |

---

## Console

### Console

| Method | Signature | Returns |
|--------|-----------|---------|
| `log` | `(message: Object, additional: Array<Object> \| null)` | `void` |
| `error` | `(message: Object, additional: Array<Object> \| null)` | `void` |
| `info` | `(message: Object, additional: Array<Object> \| null)` | `void` |
| `warn` | `(message: Object, additional: Array<Object> \| null)` | `void` |
| `clear` | `()` | `void` |

---

## Credentials

### Credentials

#### Constructor

```javascript
new Credentials()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `read` | `(service: String)` | `Object \| null` |
| `write` | `(service: String, username: String, password: String)` | `void` |
| `remove` | `(service: String)` | `void` |
| `readBookmark` | `(service: String)` | `URL.Bookmark \| null` |
| `writeBookmark` | `(service: String, bookmark: URL.Bookmark)` | `void` |

---

## SharePanel

### SharePanel

#### Constructor

```javascript
new SharePanel()
```

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `show` | `(completionHandler: Function() \| null)` | `void` |

#### Properties (read-write)

| Property | Type |
|----------|------|
| `fileWrappers` | `Array<FileWrapper>` |
| `subject` | `String \| null` |

---

## XML

### XML.Document

XML document parsing and serialization.

#### Configuration

`XML.Document.Configuration` - Parsing configuration options.

### XML.Element

XML element representation within a document tree.

### XML.WhitespaceBehavior

| Value |
|-------|
| (Whitespace handling modes) |

### XML.WhitespaceBehavior.Type

| Value |
|-------|
| (Whitespace behavior type values) |

---

## Numeric Types

### Decimal

#### Class Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `fromString` | `(string: String)` | `Decimal` |

#### Class Properties (read-only)

| Property | Type |
|----------|------|
| `maximum` | `Decimal` |
| `minimum` | `Decimal` |
| `notANumber` | `Decimal` |
| `one` | `Decimal` |
| `zero` | `Decimal` |

#### Instance Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `toString` | `()` | `String` |
| `add` | `(number: Decimal)` | `Decimal` |
| `subtract` | `(number: Decimal)` | `Decimal` |
| `multiply` | `(number: Decimal)` | `Decimal` |
| `divide` | `(number: Decimal)` | `Decimal` |
| `compare` | `(number: Decimal)` | `Number` |
| `equals` | `(number: Decimal)` | `Boolean` |

---

## Version

### Version

#### Properties (read-only)

| Property | Type |
|----------|------|
| `versionString` | `String` |
| `major` | `Number` |
| `minor` | `Number` |
| `patch` | `Number` |

---

## Misc Types & Enums

### ObjectIdentifier

Unique identifier for database objects. Obtained via `DatabaseObject.id`.

### ToolbarItem

| Property | Type | Access |
|----------|------|--------|
| `identifier` | `String` | read-only |

### MenuItem

#### Constructor

```javascript
new MenuItem(title: String, handler: Function | null)
```

#### Properties (read-write)

| Property | Type |
|----------|------|
| `title` | `String` |

### Notification

#### Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `schedule` | `()` | `void` |
| `cancel` | `()` | `void` |

#### Properties

| Property | Type | Access |
|----------|------|--------|
| `deliveryDate` | `Date` | read-only |
| `body` | `String` | read-write |

### UnderlineAffinity

Underline position enumeration.

### UnderlinePattern

Underline pattern enumeration.

### UnderlineStyle

Underline style enumeration.

### NamedStylePosition

Named style position enumeration.

---

## Error

### Error

Standard JavaScript `Error` with OmniFocus extensions.

| Property | Type | Access |
|----------|------|--------|
| `causedByUserCancelling` | `Boolean` | read-only |

---

## Common Patterns

### Iterating with apply()

```javascript
// Process all tasks in library
library.apply(function(item) {
    console.log(item.name)
    return ApplyResult.SkipChildren  // or null to continue
})
```

### Finding items by name

```javascript
let project = projectNamed("My Project")
let tag = tagNamed("Waiting")
let folder = folderNamed("Work")
```

### Searching

```javascript
let matches = projectsMatching("deploy")
let tagMatches = tagsMatching("home")
let folderMatches = foldersMatching("personal")
```

### Looking up by identifier

```javascript
let task = Task.byIdentifier("abc123")
let project = Project.byIdentifier("def456")
let folder = Folder.byIdentifier("ghi789")
let tag = Tag.byIdentifier("jkl012")
```

### Creating objects

```javascript
// New task in inbox
let task = new Task("Buy groceries")

// New task in a project
let task = new Task("Write tests", project)

// New project in a folder
let project = new Project("Website Redesign", folder)

// New folder
let folder = new Folder("Personal")

// New tag
let tag = new Tag("Urgent")
```

### Working with dates

```javascript
let cal = Calendar.current
let now = new Date()
let components = new DateComponents()
components.day = 7
let nextWeek = cal.dateByAddingDateComponents(now, components)

task.dueDate = nextWeek
task.deferDate = now
```

### HTTP requests

```javascript
let url = URL.fromString("https://api.example.com/data")
let request = new URL.FetchRequest(url)
request.method = "GET"
request.headers = {"Authorization": "Bearer token123"}

request.fetch().then(response => {
    let data = JSON.parse(response.bodyString)
    console.log(data)
})
```

### Parsing TaskPaper format

```javascript
let tasks = Task.byParsingTransportText("- Buy groceries @due(2024-01-15) @flagged")
```

### Repetition rules

```javascript
// Repeat weekly from due date (legacy)
task.repetitionRule = new Task.RepetitionRule("FREQ=WEEKLY", Task.RepetitionMethod.DueDate)

// Repeat daily (modern v4.7+)
task.repetitionRule = new Task.RepetitionRule(
    "FREQ=DAILY",
    null,
    Task.RepetitionScheduleType.Regularly,
    Task.AnchorDateKey.DueDate,
    true
)

// Stop repeating
task.repetitionRule = null
```

### Window and perspective control

```javascript
let win = document.windows[0]
win.perspective = Perspective.BuiltIn.Inbox
win.sidebarVisible = true

// Focus on specific folder
let folder = folderNamed("Work")
win.focus = [folder]

// Clear focus
win.focus = []
```

### Selection

```javascript
let sel = document.windows[0].selection
sel.tasks.forEach(task => {
    task.flagged = true
})
```
