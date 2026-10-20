-- Migration: 000001_init_schema.up.sql
-- Koleksi Punya Rini Rashifah Database Schema for PostgreSQL / Neon

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Storage Locations Table (Hierarchical)
CREATE TABLE IF NOT EXISTS storage_locations (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    parent_location_id VARCHAR(36) REFERENCES storage_locations(id) ON DELETE RESTRICT,
    location_type VARCHAR(50),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_storage_locations_parent ON storage_locations(parent_location_id);

-- 3. Collection Items Table
CREATE TABLE IF NOT EXISTS collection_items (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id VARCHAR(36) NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    image_url TEXT,
    color VARCHAR(50),
    brand VARCHAR(100),
    size VARCHAR(50),
    current_location_id VARCHAR(36) REFERENCES storage_locations(id) ON DELETE SET NULL,
    position_detail TEXT,
    availability_status VARCHAR(30) NOT NULL DEFAULT 'Available',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_collection_items_category ON collection_items(category_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_location ON collection_items(current_location_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_status ON collection_items(availability_status);

-- 4. Location History Table
CREATE TABLE IF NOT EXISTS location_history (
    id VARCHAR(36) PRIMARY KEY,
    item_id VARCHAR(36) NOT NULL REFERENCES collection_items(id) ON DELETE CASCADE,
    previous_location_id VARCHAR(36) REFERENCES storage_locations(id) ON DELETE SET NULL,
    new_location_id VARCHAR(36) REFERENCES storage_locations(id) ON DELETE SET NULL,
    moved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_location_history_item ON location_history(item_id);

-- 5. Laundry History Table
CREATE TABLE IF NOT EXISTS laundry_history (
    id VARCHAR(36) PRIMARY KEY,
    item_id VARCHAR(36) NOT NULL REFERENCES collection_items(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_laundry_history_item ON laundry_history(item_id);
