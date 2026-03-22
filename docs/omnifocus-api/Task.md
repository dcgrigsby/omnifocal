# OmniFocus API — Task

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
