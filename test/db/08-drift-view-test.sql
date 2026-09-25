-- ============================================================================
-- FINARK PLATFORM - TEST 02: ANALYTICS DRIFT VIEW ASSERTIONS
-- ============================================================================
\c paysprint;

-- Assertion: Verify the window calculations find Alice's maximum absolute drift variance
SELECT 'ASSERT' AS label, 
       'v_client_portfolio_drift_alice_math' AS slug, 
       MAX(ABS(drift_variance))::TEXT AS actual, 
       '0.5348' AS expected
FROM v_client_portfolio_drift
WHERE client_name = 'Alice Johnson';

-- Assertion: Cross-check that the SUM() OVER (PARTITION BY client_id) equals exactly 100% (1.0000)
SELECT 'ASSERT' AS label,
       'in_memory_partition_boundary_compliance' AS slug,
       SUM(current_allocation)::TEXT AS actual,
       '1.0000' AS expected
FROM v_client_portfolio_drift
WHERE client_name = 'Alice Johnson';
