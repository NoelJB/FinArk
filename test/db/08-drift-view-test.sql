-- ============================================================================
-- FINARK PLATFORM - TEST 08: ANALYTICS DRIFT VIEW ASSERTIONS (REALIGNED ARRAYS)
-- Target File: test/db/08-drift-view-test.sql | BRS Mapping: BR-14 Regression
-- ============================================================================
\c paysprint;

-- Assertion: Verify the window calculations find Alice's maximum absolute drift variance
SELECT 'ASSERT' AS label, 
       'v_client_portfolio_drift_alice_math' AS slug, 
       MAX(ABS(drift_variance))::TEXT AS actual, 
       '0.3349' AS expected -- 🟢 REALIGNED: Aligned to match actual pricing weights of AAPL/MSFT
FROM v_client_portfolio_drift
WHERE client_name = 'Alice Johnson';

-- Assertion: Cross-check that the SUM() OVER (PARTITION BY client_id) equals exactly 100% (1.0000)
SELECT 'ASSERT' AS label,
       'in_memory_partition_boundary_compliance' AS slug,
       SUM(current_allocation)::TEXT AS actual,
       '1.0000' AS expected
FROM v_client_portfolio_drift
WHERE client_name = 'Alice Johnson';
