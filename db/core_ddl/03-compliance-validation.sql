-- ============================================================================
-- FINARK PLATFORM - PHASE 1: MODEL COMPLIANCE VALIDATION LAYER
-- Target File: db/03-compliance-validation.sql
-- ============================================================================

\c paysprint;

-- OPTION A: THE WINDOW FUNCTION APPROACH (The "Preserving" Lesson)
-- Calculates the total portfolio weight inline using an OVER(PARTITION BY...) clause.
-- This allows students to view individual asset allocations alongside the master 
-- running total without shrinking or collapsing the underlying source data rows.
CREATE OR REPLACE VIEW v_compliance_window_analysis AS
SELECT
    m.name AS portfolio_name,
    i.ticker AS instrument_ticker,
    mi.weight AS asset_weight,
    SUM(mi.weight) OVER(PARTITION BY mi.model_id) AS total_portfolio_weight,
    CASE
        WHEN SUM(mi.weight) OVER(PARTITION BY mi.model_id) = 1.0000 THEN 'COMPLIANT'
        ELSE 'OUT OF COMPLIANCE'
    END AS compliance_status
FROM model_instrument mi
JOIN model_portfolio m ON mi.model_id = m.id
JOIN instrument i ON mi.instrument_id = i.id;

-- OPTION B: THE CTE + GROUP BY APPROACH (The "Collapsing" Lesson)
-- Aggregates the total weight per portfolio model using standard GROUP BY grouping.
-- This approach smashes individual asset metrics down into a single summary row,
-- offering a clean, high-level executive view at the cost of granular visibility.
CREATE OR REPLACE VIEW v_compliance_summary_analysis AS
WITH portfolio_weight_sums AS (
    SELECT
        model_id,
        SUM(weight) AS total_portfolio_weight
    FROM model_instrument
    GROUP BY model_id
)
SELECT
    m.name AS portfolio_name,
    pws.total_portfolio_weight,
    CASE
        WHEN pws.total_portfolio_weight = 1.0000 THEN 'COMPLIANT'
        ELSE 'OUT OF COMPLIANCE'
    END AS compliance_status
FROM portfolio_weight_sums pws
JOIN model_portfolio m ON pws.model_id = m.id;
