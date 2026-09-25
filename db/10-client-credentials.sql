-- ============================================================================
-- FINARK PLATFORM - PHASE 3: DEDICATED RELATIONAL CREDENTIALS CAPABILITY
-- Target File: db/10-client-credentials.sql | BRS Mapping: BR-01 Enforced
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

CREATE INDEX idx_credentials_auth ON client_credentials(username);

-- 3. SEED INITIAL IDENTITIES (BRS BR-01 Alignment)
-- Dynamically pulls valid IDs for users present in the production 02-seed matrix
INSERT INTO client_credentials (client_id, username, password_hash)
VALUES 
(
    (SELECT id FROM client WHERE name = 'Alice Johnson'), 
    'alice', 
    crypt('mission123', gen_salt('bf', 8))
),
(
    (SELECT id FROM client WHERE name = 'Brian Osei'), -- Aligned with real seed record
    'bob', -- Preserves standard username stub for application lookup compatibility
    crypt('wrongpermissions', gen_salt('bf', 8))
)
ON CONFLICT (client_id) DO NOTHING;
