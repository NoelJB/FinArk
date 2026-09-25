-- ============================================================================
-- FINARK PLATFORM - TEST 07: APPLICATION ROLE PRIVILEGE ENFORCEMENT
-- Target File: test/07-outbox-privilege-test.sql | Security: Verification Hook
-- ============================================================================
\c paysprint;

-- 1. Test Case A: Verify the application user CAN select from the outbox table
DO $$
DECLARE
    v_actual INT := 0;
BEGIN
    SET ROLE paysprint_app;
    
    BEGIN
        PERFORM id FROM outbox LIMIT 1;
        v_actual := 1;
    EXCEPTION WHEN OTHERS THEN
        v_actual := 0;
    END;
    
    RESET ROLE;
    RAISE NOTICE 'ASSERT,outbox_table_access_allowed,%,1', v_actual;
END $$;

-- 2. Test Case B: Verify the application user is BLOCKED from core tables (OWASP A05)
DO $$
DECLARE
    v_actual INT := 0;
BEGIN
    SET ROLE paysprint_app;
    
    BEGIN
        PERFORM id FROM client LIMIT 1;
        v_actual := 0;
    EXCEPTION WHEN insufficient_privilege THEN
        v_actual := 1; -- Correctly blocked by database-level security policies!
    END;
    
    RESET ROLE;
    RAISE NOTICE 'ASSERT,core_table_access_blocked,%,1', v_actual;
END $$;
