-- ============================================================================
-- 02-seed.sql: SEED LOOKUPS, ENTITIES, AND MARKET PRICING
-- ============================================================================

\c paysprint;

-- 1. SEED INDEPENDENT LOOKUP TABLES
INSERT INTO advisor (name) VALUES
('Priya Shah'),
('Daniel Osei'),
('Wei Zhang'),
('Fatima Al-Rashid');

INSERT INTO model_portfolio (name) VALUES
('Balanced Growth'),
('Adventurous Growth'),
('Income Focus');

INSERT INTO instrument (ticker, name, current_price) VALUES
('GLBEQ1', 'Global Equity Index Fund', 142.5000),
('CORPB1', 'Sterling Corporate Bond Fund', 12.2500),
('CASHGBP', 'Cash (GBP)', 1.0000),
('GILT10', 'UK 10-Year Gilt', 98.4500);

-- 2. SEED CORE ENTITY (CLIENT)
INSERT INTO client (name, advisor_id, model_portfolio_id, subscription_date) VALUES
('Alice Johnson', (SELECT id FROM advisor WHERE name = 'Priya Shah'),
 (SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), '2023-01-15'),
('Brian Osei', (SELECT id FROM advisor WHERE name = 'Daniel Osei'),
 (SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), '2023-03-01'),
('Carla Mendes', (SELECT id FROM advisor WHERE name = 'Priya Shah'),
 (SELECT id FROM model_portfolio WHERE name = 'Income Focus'), '2022-11-01'),
('David Kim', (SELECT id FROM advisor WHERE name = 'Wei Zhang'),
 (SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), '2023-06-01'),
('Elena Petrova', (SELECT id FROM advisor WHERE name = 'Daniel Osei'),
 (SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), '2022-09-01'),
('Farid Hossain', (SELECT id FROM advisor WHERE name = 'Fatima Al-Rashid'),
 (SELECT id FROM model_portfolio WHERE name = 'Income Focus'), '2024-01-20');

-- 3. SEED PORTFOLIO ALLOCATION TARGETS (MODEL_INSTRUMENT)
INSERT INTO model_instrument (model_id, instrument_id, weight) VALUES
-- Balanced Growth Portfolio
((SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), (SELECT id FROM instrument WHERE ticker = 'GLBEQ1'), 0.4000),
((SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), (SELECT id FROM instrument WHERE ticker = 'CORPB1'), 0.3000),
((SELECT id FROM model_portfolio WHERE name = 'Balanced Growth'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 0.3000),
-- Adventurous Growth Portfolio
((SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), (SELECT id FROM instrument WHERE ticker = 'GLBEQ1'), 0.7000),
((SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), (SELECT id FROM instrument WHERE ticker = 'GILT10'), 0.2000),
((SELECT id FROM model_portfolio WHERE name = 'Adventurous Growth'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 0.1000),
-- Income Focus Portfolio
((SELECT id FROM model_portfolio WHERE name = 'Income Focus'), (SELECT id FROM instrument WHERE ticker = 'CORPB1'), 0.6000),
((SELECT id FROM model_portfolio WHERE name = 'Income Focus'), (SELECT id FROM instrument WHERE ticker = 'GILT10'), 0.3000),
((SELECT id FROM model_portfolio WHERE name = 'Income Focus'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 0.1000);

-- 4. SEED TRANSACTION AUDITS (SUBSCRIPTION_HISTORY)
INSERT INTO subscription_history (client_id, model_portfolio, subscription_date) VALUES
((SELECT id FROM client WHERE name = 'Alice Johnson'), 'Balanced Growth', '2023-01-15'),
((SELECT id FROM client WHERE name = 'Brian Osei'), 'Adventurous Growth', '2023-03-01'),
((SELECT id FROM client WHERE name = 'Carla Mendes'), 'Income Focus', '2022-11-01'),
((SELECT id FROM client WHERE name = 'David Kim'), 'Adventurous Growth', '2023-06-01'),
((SELECT id FROM client WHERE name = 'Elena Petrova'), 'Balanced Growth', '2022-09-01'),
((SELECT id FROM client WHERE name = 'Farid Hossain'), 'Income Focus', '2024-01-20');

-- 5. INITIALIZE CLIENT ACTUAL POSITIONS (CLIENT_INSTRUMENT)
INSERT INTO client_instrument (client_id, instrument_id, quantity) VALUES
-- Alice Johnson (Balanced Growth)
((SELECT id FROM client WHERE name = 'Alice Johnson'), (SELECT id FROM instrument WHERE ticker = 'GLBEQ1'), 400.0000),
((SELECT id FROM client WHERE name = 'Alice Johnson'), (SELECT id FROM instrument WHERE ticker = 'CORPB1'), 300.0000),
((SELECT id FROM client WHERE name = 'Alice Johnson'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 300.0000),
-- Brian Osei (Adventurous Growth)
((SELECT id FROM client WHERE name = 'Brian Osei'), (SELECT id FROM instrument WHERE ticker = 'GLBEQ1'), 700.0000),
((SELECT id FROM client WHERE name = 'Brian Osei'), (SELECT id FROM instrument WHERE ticker = 'GILT10'), 200.0000),
((SELECT id FROM client WHERE name = 'Brian Osei'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 100.0000),
-- Carla Mendes (Income Focus)
((SELECT id FROM client WHERE name = 'Carla Mendes'), (SELECT id FROM instrument WHERE ticker = 'CORPB1'), 600.0000),
((SELECT id FROM client WHERE name = 'Carla Mendes'), (SELECT id FROM instrument WHERE ticker = 'GILT10'), 300.0000),
((SELECT id FROM client WHERE name = 'Carla Mendes'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 100.0000),
-- David Kim (Adventurous Growth)
((SELECT id FROM client WHERE name = 'David Kim'), (SELECT id FROM instrument WHERE ticker = 'GLBEQ1'), 700.0000),
((SELECT id FROM client WHERE name = 'David Kim'), (SELECT id FROM instrument WHERE ticker = 'GILT10'), 200.0000),
((SELECT id FROM client WHERE name = 'David Kim'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 100.0000),
-- Elena Petrova (Balanced Growth)
((SELECT id FROM client WHERE name = 'Elena Petrova'), (SELECT id FROM instrument WHERE ticker = 'GLBEQ1'), 400.0000),
((SELECT id FROM client WHERE name = 'Elena Petrova'), (SELECT id FROM instrument WHERE ticker = 'CORPB1'), 300.0000),
((SELECT id FROM client WHERE name = 'Elena Petrova'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 300.0000),
-- Farid Hossain (Income Focus)
((SELECT id FROM client WHERE name = 'Farid Hossain'), (SELECT id FROM instrument WHERE ticker = 'CORPB1'), 600.0000),
((SELECT id FROM client WHERE name = 'Farid Hossain'), (SELECT id FROM instrument WHERE ticker = 'GILT10'), 300.0000),
((SELECT id FROM client WHERE name = 'Farid Hossain'), (SELECT id FROM instrument WHERE ticker = 'CASHGBP'), 100.0000);
