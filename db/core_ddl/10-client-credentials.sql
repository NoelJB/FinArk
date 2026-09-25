-- ============================================================================
-- FINARK PLATFORM - PHASE 3: DEDICATED RELATIONAL CREDENTIALS CAPABILITY
-- Target File: db/core_ddl/10-client-credentials.sql | BRS Mapping: BR-01 Enforced
-- ============================================================================

\c paysprint;

-- 1. ENABLE EXTENSION VAULT CAPABILITIES
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. SECURE ISOLATED CREDENTIALS STORAGE TABLE
CREATE TABLE client_credentials (
    client_id INT PRIMARY KEY,
    username VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_credentials_client FOREIGN KEY (client_id) REFERENCES client(id) ON DELETE CASCADE
);

-- Indexing optimized for high-speed authentication check lookup loops
CREATE INDEX idx_credentials_auth ON client_credentials(username);
