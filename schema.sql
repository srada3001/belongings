PRAGMA foreign_keys = ON;
CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE COLLATE NOCASE,
    prefix CHAR(1) NOT NULL UNIQUE,
    CHECK (length(prefix)=1 AND prefix NOT GLOB '*[^A-Z]*')
);
CREATE TABLE locations (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL COLLATE NOCASE,
    parent_id INTEGER REFERENCES locations(id) ON DELETE RESTRICT,
    UNIQUE (parent_id, name)
);
CREATE UNIQUE INDEX locations_top_level_name ON locations (name) WHERE parent_id IS NULL;
CREATE TABLE items (
    id INTEGER PRIMARY KEY,
    code VARCHAR UNIQUE,
    name VARCHAR(100) NOT NULL COLLATE NOCASE,
    category_id INTEGER NOT NULL  REFERENCES categories(id),
    brand VARCHAR(100),
    model VARCHAR(100),
    price_minor INTEGER,
    currency VARCHAR(3),
    acquired_on TEXT,
    location_id INTEGER REFERENCES locations(id) ON DELETE RESTRICT,
    container_id INTEGER REFERENCES items(id) ON DELETE RESTRICT,
    accessory_of_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
    is_container INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    CHECK (
        acquired_on GLOB '[0-9][0-9][0-9][0-9]'
        OR date(acquired_on || '-01') IS acquired_on || '-01'
        OR date(acquired_on) IS acquired_on
    ),
    CHECK (currency = 'USD' OR currency = 'COP'),
    CHECK (location_id IS NULL OR container_id IS NULL),
    CHECK ((price_minor IS NOT NULL AND currency IS NOT NULL) OR (price_minor IS NULL AND currency IS NULL)),
    CHECK (is_container=0 or is_container=1)
);
CREATE TRIGGER items_container_check BEFORE INSERT ON items
WHEN NEW.container_id IS NOT NULL AND (SELECT is_container FROM items WHERE id = NEW.container_id) = 0
BEGIN
    SELECT RAISE(ABORT, 'container_id must point to a container');
END;
CREATE TRIGGER items_container_check_update BEFORE UPDATE OF container_id ON items
WHEN NEW.container_id IS NOT NULL AND (SELECT is_container FROM items WHERE id = NEW.container_id) = 0
BEGIN
    SELECT RAISE(ABORT, 'container_id must point to a container');
END;
CREATE TRIGGER items_is_container_check_update BEFORE UPDATE OF is_container ON items
WHEN NEW.is_container=0 AND EXISTS (SELECT * FROM items WHERE container_id=OLD.id)
BEGIN SELECT RAISE(ABORT, 'a container with items inside cannot stop being a container');
END;
/* We'll leave images for later
CREATE TABLE images ()*/
