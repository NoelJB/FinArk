-- ============================================================================
-- FINARK PLATFORM - TEST 02: MODEL COMPLIANCE STATIC VALIDATIONS
-- Target File: test/02-compliance-test.sql
-- ============================================================================
\c paysprint;

-- Assertion A: Verify the Window Function View preserves all 9 granular asset rows
SELECT 'ASSERT' AS label, 
       'compliance_window_preserves_rows' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '9' AS expected
FROM v_compliance_window_analysis;

-- Assertion B: Verify the Window Function View marks all 9 asset assignments as COMPLIANT
SELECT 'ASSERT' AS label, 
       'compliance_window_status_check' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '9' AS expected
FROM v_compliance_window_analysis
WHERE compliance_status = 'COMPLIANT';

-- Assertion C: Verify the Group By View collapses rows down to exactly 3 portfolios
SELECT 'ASSERT' AS label, 
       'compliance_summary_collapses_rows' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '3' AS expected
FROM v_compliance_summary_analysis;

-- Assertion D: Verify the Group By View flags every portfolio as COMPLIANT
SELECT 'ASSERT' AS label, 
       'compliance_summary_status_check' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '3' AS expected
FROM v_compliance_summary_analysis
WHERE compliance_status = 'COMPLIANT';
