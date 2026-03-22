# OmniFocus API — Date & Time

> Extracted from the full reference: [omni-automation.com/omnifocus/OF-API.html](https://omni-automation.com/omnifocus/OF-API.html)
> Source file: `docs/specs/OMNIFOCUS-OMNI-AUTOMATION-API.md`

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
