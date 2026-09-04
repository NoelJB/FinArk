-- ============================================================================
-- FINARK PLATFORM - TEST 03: MIGRATION BACKFILL OUTBOX ASSERTIONS
-- ============================================================================
\c paysprint;

-- Assertion: Verify migration backfill successfully staged the DRIFT_ALERT row for Alice on stack boot
SELECT 'ASSERT' AS label, 
       'outbox_backfill_staging' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '1' AS expected
FROM outbox
WHERE event_type = 'DRIFT_ALERT'
  AND aggregate_id = (SELECT id::VARCHAR FROM client WHERE name = 'Alice Johnson');
