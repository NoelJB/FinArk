-- ============================================================================
-- FINARK PLATFORM - PHASE 3: SECURE POLYMORPHIC OUTBOX ENVELOPE
-- Target File: db/07-outbox-infrastructure.sql | Security: Least Privilege Enforced
-- ============================================================================

\c paysprint;

-- 1. POLYMORPHIC TRANSACTIONAL OUTBOX LOG TABLE
CREATE TABLE outbox (
    id BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL, -- e.g., 'CLIENT_PORTFOLIO', 'ADVISOR_DASHBOARD'
    aggregate_id VARCHAR(100) NOT NULL,   -- Unique identifier string mapping (client_id)
    event_type VARCHAR(100) NOT NULL,     -- e.g., 'TRADE_EXECUTED', 'DRIFT_ALERT'
    payload JSONB NOT NULL,               -- Unstructured event payload detail document
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT chk_outbox_status CHECK (status IN ('PENDING', 'SENT', 'FAILED'))
);

CREATE INDEX idx_outbox_pending ON outbox(status, created_at ASC);

-- ============================================================================
-- SECURITY ENFORCEMENT: PRINCIPLE OF LEAST PRIVILEGE (OWASP A05:2021)
-- ============================================================================

-- Create a dedicated, non-superuser role for the external Python application worker poller
CREATE USER paysprint_app WITH PASSWORD 'AppSecureToken987!';

-- Explicitly revoke all default permissions on the public schema for this user
REVOKE ALL ON SCHEMA public FROM paysprint_app;

-- Grant limited connectivity access to the target database context
GRANT CONNECT ON DATABASE paysprint TO paysprint_app;
GRANT USAGE ON SCHEMA public TO paysprint_app;

-- Grant explicit, limited data access to the outbox table for polling and status updates
GRANT SELECT, UPDATE ON TABLE outbox TO paysprint_app;

-- Grant permission to mutate the serial sequence context to avoid permission crashes
GRANT USAGE, SELECT ON SEQUENCE outbox_id_seq TO paysprint_app;
