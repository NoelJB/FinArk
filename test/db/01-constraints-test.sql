-- ============================================================================
-- FINARK PLATFORM - TEST 01: HARDENING & INTEGRITY ASSERTIONS
-- ============================================================================
\c paysprint;

DO $$
DECLARE
    v_actual INT := 0;
BEGIN
    -- Test Case 1: Attempt to insert a negative instrument price
    BEGIN
        INSERT INTO instrument (ticker, name, current_price) 
        VALUES ('BADPRC', 'Negative Price Asset', -10.0000);
    EXCEPTION WHEN check_violation THEN
        v_actual := 1; -- Successfully blocked by constraint
    END;
    
    RAISE NOTICE 'ASSERT,chk_instrument_price,%,1', v_actual;
END $$;

DO $$
DECLARE
    v_actual INT := 0;
BEGIN
    -- Test Case 2: Attempt to insert an empty whitespace advisor name
    BEGIN
        INSERT INTO advisor (name) VALUES ('   ');
    EXCEPTION WHEN check_violation THEN
        v_actual := 1; -- Successfully blocked by constraint
    END;
    
    RAISE NOTICE 'ASSERT,chk_advisor_name_nonzero,%,1', v_actual;
END $$;
