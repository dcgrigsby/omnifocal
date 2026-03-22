# OmniFocus API — Tag

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
