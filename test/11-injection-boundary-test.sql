-- ============================================================================
-- FINARK PLATFORM - TEST 11: PARAMETERIZED INJECTION BOUNDARY ASSERTIONS
-- Target File: test/11-injection-boundary-test.sql | Security: OWASP A03 Check
-- ============================================================================
\c paysprint;

-- 1. PRE-COMPILE THE BLUEPRINT SCHEMA (Simulating Backend Framework Driver Behavior)
-- This instructs the relational optimizer to lock down the query structure upfront.
PREPARE advisor_secure_lookup (VARCHAR) AS 
    SELECT COUNT(*) FROM advisor WHERE name = $1;

-- 2. AUTOMATED ASSERTION UNIT
-- We pass an attacking payload designed to force a traditional unparameterized query to return all rows.
DO $$
DECLARE
    v_attack_payload VARCHAR := ''' OR ''1''=''1';
    v_returned_rows  INT;
    v_assertion_pass INT := 0;
BEGIN
    -- Execute the prepared plan by injecting the malicious string into the query variable slot $1
    EXECUTE advisor_secure_lookup(v_attack_payload) INTO v_returned_rows;
    
    -- If the boundary protection works, the engine searches for the literal string value.
    -- Since no advisor is named after raw SQL code code injections, it must return exactly 0 rows.
    -- If it returns greater than 0, the query logic was modified by the input, signaling a breach.
    IF v_returned_rows = 0 THEN
        v_assertion_pass := 1; -- Success: Input string successfully neutralized into basic data
    ELSE
        v_assertion_pass := 0; -- Failure: SQL injection backdoor exposed!
    END IF;

    RAISE NOTICE 'ASSERT,parameter_binding_injection_defense,%,1', v_assertion_pass;
END $$;

-- Clean up the prepared plan context from the active session cache execution memory
DEALLOCATE advisor_secure_lookup;
