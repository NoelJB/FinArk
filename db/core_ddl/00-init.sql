-- ============================================================================
-- 00-init.sql: DATABASE INITIALIZATION
-- ============================================================================

-- Pre-requisite: the database is established from the docker-compose.yaml file.

-- 1. Standardize timezone rendering to UTC for uniform event tracking
ALTER DATABASE paysprint SET timezone TO 'UTC';
