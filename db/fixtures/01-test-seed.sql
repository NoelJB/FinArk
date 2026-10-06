-- ============================================================================
-- 01-test-seed.sql: CLUSTER PORTFOLIO TRANSACTIONAL DATA FIXTURES
-- Target File: db/fixtures/01-test-seed.sql | BRS Mapping: BR-14 Decoupled
-- ============================================================================
\c paysprint;

-- ============================================================================
-- 🟢 STEP 1: REGRESSION TEST CALIBRATION PASS
-- Explicitly forces our core testing assets to their deterministic baselines 
-- before client allocations are mapped. This does NOT trigger the drift engine.
-- ============================================================================
BEGIN;
UPDATE instrument SET current_price = 180.5000 WHERE ticker = 'AAPL';
UPDATE instrument SET current_price = 420.2500 WHERE ticker = 'MSFT';
UPDATE instrument SET current_price = 125.0000 WHERE ticker = 'NVDA';
UPDATE instrument SET current_price = 510.4500 WHERE ticker = 'SPY';
COMMIT;

-- 2. SEED INDEPENDENT LOOKUP TABLES
INSERT INTO advisor (name) VALUES
('Priya Shah'),
('Daniel Osei'),
('Wei Zhang'),
('Fatima Al-Rashid');

INSERT INTO model_portfolio (name) VALUES
('Balanced Growth'),
('Adventurous Growth'),
('Income Focus');

-- 3. SEED CORE ENTITY (CLIENT)
INSERT INTO client (name, advisor_id, model_portfolio_id, subscription_date) VALUES
('Alice Johnson', (SELECT id FROM advisor WHERE name = 'Priya Shah'), (SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), '2023-01-15'),
('Brian Osei', (SELECT id FROM advisor WHERE name = 'Daniel Osei'), (SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), '2023-03-01'),
('Carla Mendes', (SELECT id FROM advisor WHERE name = 'Priya Shah'), (SELECT id FROM model_portfolio WHERE name = 'Income Focus'), '2022-11-01'),
('David Kim', (SELECT id FROM advisor WHERE name = 'Wei Zhang'), (SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), '2023-06-01'),
('Elena Petrova', (SELECT id FROM advisor WHERE name = 'Daniel Osei'), (SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), '2022-09-01'),
('Farid Hossain', (SELECT id FROM advisor WHERE name = 'Fatima Al-Rashid'), (SELECT id FROM model_portfolio WHERE name = 'Income Focus'), '2024-01-20');

-- 4. SEED PORTFOLIO ALLOCATION TARGETS (MODEL_INSTRUMENT)
INSERT INTO model_instrument (model_id, instrument_id, weight) VALUES
((SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), (SELECT id FROM instrument WHERE ticker = 'AAPL'), 0.4000),
((SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), (SELECT id FROM instrument WHERE ticker = 'MSFT'), 0.3000),
((SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 0.3000),
((SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), (SELECT id FROM instrument WHERE ticker = 'AAPL'), 0.7000),
((SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), (SELECT id FROM instrument WHERE ticker = 'SPY'), 0.2000),
((SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), (SELECT id FROM instrument WHERE ticker = 'CASHUSD'), 0.1000),
((SELECT id FROM model_portfolio WHERE name = 'Income Focus'), (SELECT id FROM instrument WHERE ticker = 'MSFT'), 0.6000),
((SELECT id FROM model_portfolio WHERE name = 'Income Focus'), (SELECT id FROM instrument WHERE ticker = 'SPY'), 0.3000),
((SELECT id FROM model_portfolio WHERE name = 'Income Focus'), (SELECT id FROM instrument WHERE ticker = 'CASHUSD'), 0.1000);

-- 5. SEED TRANSACTION AUDITS (SUBSCRIPTION_HISTORY)
INSERT INTO subscription_history (client_id, model_portfolio, subscription_date) VALUES
((SELECT id FROM client WHERE name = 'Alice Johnson'), 'Balanced Growth', '2023-01-15'),
((SELECT id FROM client WHERE name = 'Brian Osei'), 'Adventurous Growth', '2023-03-01'),
((SELECT id FROM client WHERE name = 'Carla Mendes'), 'Income Focus', '2022-11-01'),
((SELECT id FROM client WHERE name = 'David Kim'), 'Adventurous Growth', '2023-06-01'),
((SELECT id FROM client WHERE name = 'Elena Petrova'), 'Balanced Growth', '2022-09-01'),
((SELECT id FROM client WHERE name = 'Farid Hossain'), 'Income Focus', '2024-01-20');

-- ============================================================================
-- ⚡ ATOMIC TRANSACTION LAYER
-- ============================================================================
BEGIN;

INSERT INTO client_instrument (client_id, instrument_id, quantity) VALUES
((SELECT id FROM client WHERE name = 'Alice Johnson'), (SELECT id FROM instrument WHERE ticker = 'AAPL'), 400.0000),
((SELECT id FROM client WHERE name = 'Alice Johnson'), (SELECT id FROM instrument WHERE ticker = 'MSFT'), 300.0000),
((SELECT id FROM client WHERE name = 'Alice Johnson'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 300.0000),
((SELECT id FROM client WHERE name = 'Brian Osei'), (SELECT id FROM instrument WHERE ticker = 'AAPL'), 700.0000),
((SELECT id FROM client WHERE name = 'Brian Osei'), (SELECT id FROM instrument WHERE ticker = 'SPY'), 200.0000),
((SELECT id FROM client WHERE name = 'Brian Osei'), (SELECT id FROM instrument WHERE ticker = 'CASHUSD'), 100.0000),
((SELECT id FROM client WHERE name = 'Carla Mendes'), (SELECT id FROM instrument WHERE ticker = 'MSFT'), 600.0000),
((SELECT id FROM client WHERE name = 'Carla Mendes'), (SELECT id FROM instrument WHERE ticker = 'SPY'), 300.0000),
((SELECT id FROM client WHERE name = 'Carla Mendes'), (SELECT id FROM instrument WHERE ticker = 'CASHUSD'), 100.0000),
((SELECT id FROM client WHERE name = 'David Kim'), (SELECT id FROM instrument WHERE ticker = 'AAPL'), 700.0000),
((SELECT id FROM client WHERE name = 'David Kim'), (SELECT id FROM instrument WHERE ticker = 'SPY'), 200.0000),
((SELECT id FROM client WHERE name = 'David Kim'), (SELECT id FROM instrument WHERE ticker = 'CASHUSD'), 100.0000),
((SELECT id FROM client WHERE name = 'Elena Petrova'), (SELECT id FROM instrument WHERE ticker = 'AAPL'), 400.0000),
((SELECT id FROM client WHERE name = 'Elena Petrova'), (SELECT id FROM instrument WHERE ticker = 'MSFT'), 300.0000),
((SELECT id FROM client WHERE name = 'Elena Petrova'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 300.0000),
((SELECT id FROM client WHERE name = 'Farid Hossain'), (SELECT id FROM instrument WHERE ticker = 'MSFT'), 600.0000),
((SELECT id FROM client WHERE name = 'Farid Hossain'), (SELECT id FROM instrument WHERE ticker = 'SPY'), 300.0000),
((SELECT id FROM client WHERE name = 'Farid Hossain'), (SELECT id FROM instrument WHERE ticker = 'CASHUSD'), 100.0000);

COMMIT;

-- 6. SEED IDENTITY STORE PROFILE VECTORS
INSERT INTO client_credentials (client_id, username, password_hash)
VALUES 
((SELECT id FROM client WHERE name = 'Alice Johnson'), 'alice', crypt('mission123', gen_salt('bf', 8))),
((SELECT id FROM client WHERE name = 'Brian Osei'), 'bob', crypt('wrongpermissions', gen_salt('bf', 8)))
ON CONFLICT (client_id) DO NOTHING;

-- 7. SYNCHRONIZE STATE DATA SNAPSHOT CACHES
REFRESH MATERIALIZED VIEW mv_eod_regulatory_compliance;

-- 8. TEST ROLE SEED DATA
INSERT INTO platform_roles (role_name) VALUES ('MISSION_OPERATOR'), ('GUEST') ON CONFLICT DO NOTHING;
INSERT INTO client_role_mappings (client_id, role_id) SELECT 1, role_id FROM platform_roles WHERE role_name = 'MISSION_OPERATOR' ON CONFLICT DO NOTHING;
INSERT INTO client_role_mappings (client_id, role_id) SELECT 2, role_id FROM platform_roles WHERE role_name = 'GUEST' ON CONFLICT DO NOTHING;
