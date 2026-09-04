-- ============================================================================
-- FINARK PLATFORM - TEST 04: MATERIALIZED REGULATORY COMPLIANCE ASSERTIONS
-- Target File: test/04-eod-test.sql
-- ============================================================================
\c paysprint;

-- Assertion A: Verify the physical Materialized View contains exactly 6 client snapshot rows
SELECT 'ASSERT' AS label, 
       'mv_eod_regulatory_cache_row_count' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '6' AS expected
FROM mv_eod_regulatory_compliance;

-- Assertion B: Verify that our custom compliance status accurately filters the frozen cache rows
SELECT 'ASSERT' AS label, 
       'mv_eod_regulatory_cache_status_check' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '6' AS expected
FROM mv_eod_regulatory_compliance
WHERE regulatory_status = 'COMPLIANT';
