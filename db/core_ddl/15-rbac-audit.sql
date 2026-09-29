-- ============================================================================
-- FINARK PLATFORM - PHASE 3: RELATIONAL RBAC ENGINE & AUDITING SCHEMA
-- Target File: db/core_ddl/15-rbac-audit.sql | BRS Mapping: BR-02 / BR-04
-- ============================================================================
BEGIN;
CREATE TABLE IF NOT EXISTS platform_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(64) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS client_role_mappings (
    client_id INT NOT NULL,
    role_id INT REFERENCES platform_roles(role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (client_id, role_id)
);
CREATE TABLE IF NOT EXISTS security_audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    ip_address VARCHAR(45),
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
