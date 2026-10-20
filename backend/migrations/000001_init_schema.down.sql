-- Migration: 000001_init_schema.down.sql

DROP TABLE IF EXISTS laundry_history CASCADE;
DROP TABLE IF EXISTS location_history CASCADE;
DROP TABLE IF EXISTS collection_items CASCADE;
DROP TABLE IF EXISTS storage_locations CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
