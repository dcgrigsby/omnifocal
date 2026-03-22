# OmniFocus API — Perspective

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
