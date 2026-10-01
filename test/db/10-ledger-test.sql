-- ============================================================================
-- FINARK PLATFORM - TEST 10: IMMUTABLE LEDGER & SETTLEMENT ASSERTIONS
-- Target File: test/10-ledger-test.sql
-- ============================================================================
-- test/db/10-ledger-test.sql
\c paysprint;

-- 1. Execute a mock BUY trade entry into our ledger for David Kim (client_id = 4)
INSERT INTO trade_execution (client_id, instrument_id, side, quantity, execution_price)
VALUES (
    (SELECT id FROM client WHERE name = 'David Kim'),
    (SELECT id FROM instrument WHERE ticker = 'AAPL'), -- 🟢 Realigned
    'BUY',
    10.0000,
    180.5000 -- 🟢 Realigned
);

-- Assertion A: Verify simulated settlement auto-cleared into client balances (700 + 10 = 710.0000)
SELECT 'ASSERT' AS label, 
       'simulated_ledger_clearing_settlement' AS slug, 
       quantity::TEXT AS actual, 
       '710.0000' AS expected
FROM client_instrument 
WHERE client_id = (SELECT id FROM client WHERE name = 'David Kim')
  AND instrument_id = (SELECT id FROM instrument WHERE ticker = 'AAPL');

-- Assertion B: Verify the transactional outbox successfully staged the polymorphic trade payload
SELECT 'ASSERT' AS label, 
       'outbox_trade_executed_staging' AS slug, 
       COUNT(*)::TEXT AS actual, 
       '1' AS expected
FROM outbox 
WHERE aggregate_type = 'execution-ledger'
  AND event_type = 'TRADE_EXECUTED' 
  AND aggregate_id = (SELECT id FROM client WHERE name = 'David Kim')::VARCHAR;
