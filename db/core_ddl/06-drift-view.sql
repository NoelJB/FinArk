-- ============================================================================
-- FINARK PLATFORM - PHASE 1: PORTFOLIO DRIFT COMPLIANCE VIEW
-- Dialect: PostgreSQL | Target File: db/03-drift-view.sql
-- ============================================================================

\c paysprint;

CREATE OR REPLACE VIEW v_client_portfolio_drift AS
WITH ClientMarketValues AS (
    -- Step 1: Calculate the true fiat market value for every individual asset holding
    SELECT
        ci.client_id,
        ci.instrument_id,
        ci.quantity AS actual_quantity,
        i.current_price,
        (ci.quantity * i.current_price) AS asset_market_value
    FROM client_instrument ci
    JOIN instrument i ON ci.instrument_id = i.id
),
ClientPortfolioWeight AS (
    -- Step 2: Use window functions to calculate total wealth and individual asset % mixes
    SELECT
        c.id AS client_id,
        c.name AS client_name,
        c.model_portfolio_id,
        cmv.instrument_id,
        cmv.actual_quantity,
        cmv.asset_market_value,
        SUM(cmv.asset_market_value) OVER(PARTITION BY c.id) AS total_portfolio_value,
        ROUND(
            cmv.asset_market_value / SUM(cmv.asset_market_value) OVER(PARTITION BY c.id),
            4
        ) AS actual_weight_pct
    FROM client c
    JOIN ClientMarketValues cmv ON c.id = cmv.client_id
),
ModelTargets AS (
    -- Step 3: Isolate target portfolio benchmarks for clean outer join mapping
    SELECT
        model_id,
        instrument_id,
        weight AS target_weight_pct
    FROM model_instrument
)
-- Step 4: Core execution layer computing the financial drift variance across models
SELECT
    cpw.client_id,
    cpw.client_name,
    cpw.model_portfolio_id,
    i.ticker AS instrument_ticker,
    i.name AS instrument_name,
    cpw.actual_quantity,
    ROUND(cpw.asset_market_value, 2) AS market_value_fiat,
    ROUND(cpw.total_portfolio_value, 2) AS total_portfolio_value_fiat,
    cpw.actual_weight_pct AS current_allocation,
    COALESCE(mt.target_weight_pct, 0.0000) AS target_allocation,
    (cpw.actual_weight_pct - COALESCE(mt.target_weight_pct, 0.0000)) AS drift_variance
FROM ClientPortfolioWeight cpw
LEFT JOIN ModelTargets mt ON cpw.model_portfolio_id = mt.model_id
                         AND cpw.instrument_id = mt.instrument_id
JOIN instrument i ON cpw.instrument_id = i.id;
