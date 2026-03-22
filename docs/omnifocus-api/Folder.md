# OmniFocus API — Folder

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
