-- ============================================================================
-- FINARK PLATFORM - PHASE 3: CREDENTIALS RBAC PRIVILEGE CONFIGURATION
-- Target File: db/12-credentials-rbac.sql | BRS Mapping: BR-02 Enforced
-- ============================================================================

\c paysprint;

-- Securely grant our application role user access to the hardened login registry
GRANT SELECT, INSERT, UPDATE ON TABLE client_credentials TO paysprint_app;
