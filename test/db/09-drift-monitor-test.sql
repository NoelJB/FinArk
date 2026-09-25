-- ============================================================================
-- FINARK PLATFORM - TEST 09: DRIFT BACKFILL INITIALIZATION ASSERTIONS
-- Target File: test/09-drift-monitor-test.sql | BRS Mapping: BR-14 / BR-16
-- ============================================================================
\c paysprint;

-- Assertion A: Verify the initialization backfill query correctly caught Alice Johnson's pre-existing drift violation
SELECT 'ASSERT' AS label, 
       'outbox_backfill_staging' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '3' AS expected
FROM outbox
WHERE aggregate_type = 'compliance-alerts'
  AND event_type = 'DRIFT_ALERT'
  AND aggregate_id = (SELECT id::VARCHAR FROM client WHERE name = 'Alice Johnson');
