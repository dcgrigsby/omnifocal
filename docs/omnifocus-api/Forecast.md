# OmniFocus API — Forecast

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
