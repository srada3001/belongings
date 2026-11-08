# Specification — Personal inventory

A record of my possessions: what I own, where it is, and useful facts about it.
It is also a portfolio project to practice SQL.

## Phases

1. **Data model** (current): SQLite schema, a few real records to find out which attributes are useful, and sample queries.
2. **App**: create, read, update and delete records.

Out of scope for now: currency conversion, serial numbers.

## Conventions

- Everything in English.
- SQL keywords in UPPERCASE; table and column names in lowercase `snake_case`; table names in plural.
- Database: SQLite, with foreign keys enabled on every connection (`PRAGMA foreign_keys = ON`).

## Entities

### categories

| Column | Notes |
|---|---|
| `name` | Required, unique (case-insensitive). |
| `prefix` | Required, unique. One uppercase letter (`A`–`Z`) used in item codes (`E` for Electronics, `F` for Furniture). |

### locations

Places that are not possessions: a house, a room, a closet.

| Column | Notes |
|---|---|
| `name` | Required. Unique within its parent, and among top-level places (case-insensitive). |
| `parent_id` | Location that contains it; empty for top-level places. |

### items

| Column | Notes |
|---|---|
| `id` | Integer primary key with no meaning (surrogate key). |
| `code` | Unique, optional. See [Codes](#codes). |
| `name` | Required. |
| `category_id` | Required. |
| `brand` | |
| `model` | |
| `price_minor` | Integer, in hundredths of the currency unit (US$19.99 → `1999`). |
| `currency` | ISO 4217 code: `COP` or `USD`. |
| `acquired_on` | Partial ISO 8601 date: `YYYY`, `YYYY-MM` or `YYYY-MM-DD`; it must be a real date (no `2023-02-30`). |
| `location_id` | Place where the item is. |
| `container_id` | Item it is stored in. |
| `accessory_of_id` | Item it belongs to (spare parts, remote controls…). |
| `is_container` | Whether other items can be stored in it. Defaults to false. |
| `notes` | Free text. |

### images

Not in the schema yet.

| Column | Notes |
|---|---|
| `item_id` | Required. Deleting the item deletes its images. |
| `path` | Required. Relative to the images folder; the file itself is not stored in the database. |
| `caption` | |

## Rules

### Codes

- Format `<prefix>-<NNN>`: a sequence per category, three digits (`E-001`, `E-002`).
- An accessory's code is the code of the item it belongs to plus a lowercase letter (`F-002-a`); that item must have a code. When that code changes, the accessories' codes change with it (`F-002-a` → `H-005-a`).

### Location

- An item is either in a place (`location_id`) or in a container (`container_id`), never both. Both empty means unknown.
- A container must have `is_container` set, and a container with items in it cannot stop being one. Triggers enforce both.
- No cycles: an item cannot end up inside itself, directly or through other items; the same applies to locations. The app enforces this (a `CHECK` constraint cannot look at other rows).
- An accessory's location is independent of the item it belongs to (the chair is in the bedroom, its spare screws in a toolbox).

### Deletion

- A location cannot be deleted while it contains locations or items.
- An item cannot be deleted while it contains items.
- Deleting an item deletes its accessories.

### Price and date

- Prices are stored in the currency paid and never converted; totals are computed per currency.
- `price_minor` and `currency` are both set or both empty.
- Prices are integers because SQLite has no exact decimal type and floating point rounds money.
- Partial dates sort correctly as text. Filter by year with the text prefix, not with SQLite date functions (they reject `2023`).

## Privacy

The repository is public. The real database and images are never committed (`.gitignore`); the repository contains only the schema, fictitious sample data and queries.

## Files

| Path | Content |
|---|---|
| `schema.sql` | Tables and constraints. |
| `seed.sql` | Fictitious sample data. |
| `queries.sql` | Useful queries: where an item is, value per category and currency, items without a code… |
| `data/` | Ignored by Git: real database, real records and images. |
