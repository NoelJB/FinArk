-- ============================================================================
-- 00-init.sql: DATABASE INITIALIZATION
-- ============================================================================

-- 1. Create the dedicated database catalog container
CREATE DATABASE paysprint;

-- 2. Connect/Switch to the new database catalog context
\c paysprint;

-- 3. Standardize timezone rendering to UTC for uniform event tracking
ALTER DATABASE paysprint SET timezone TO 'UTC';
