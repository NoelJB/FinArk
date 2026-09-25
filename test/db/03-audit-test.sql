-- ============================================================================
-- FINARK PLATFORM - TEST 03: ACTIVE PORTFOLIO HISTORY AUDIT VALIDATIONS
-- Target File: test/03-audit-test.sql
-- ============================================================================
\c paysprint;

-- Assertion A: Verify the Window Function View filters down to exactly 6 unique clients
SELECT 'ASSERT' AS label, 
       'audit_window_ranking_unique_clients' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '6' AS expected
FROM v_audit_window_ranking;

-- Assertion B: Verify the CTE Group By View filters down to exactly 6 unique clients on baseline
SELECT 'ASSERT' AS label, 
       'audit_summary_aggregation_unique_clients' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '6' AS expected
FROM v_audit_summary_aggregation;
