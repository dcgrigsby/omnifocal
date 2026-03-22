# OmniFocus API — Project

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
