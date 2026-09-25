-- ============================================================================
-- FINARK PLATFORM - PHASE 2: ACTIVE PORTFOLIO AUDITING LAYER
-- Target File: db/04-portfolio-audit.sql
-- ============================================================================

\c paysprint;

-- 1. COMPILING OPTION A: THE WINDOW FUNCTION APPROACH (Recommended)
-- Uses ROW_NUMBER() chronologically partitioned for each client inline.
CREATE OR REPLACE VIEW v_audit_window_ranking AS
SELECT 
    client_name,
    model_portfolio,
    subscription_date
FROM (
    SELECT
        c.name AS client_name,
        sh.model_portfolio,
        sh.subscription_date,
        ROW_NUMBER() OVER (
            PARTITION BY sh.client_id
            ORDER BY sh.subscription_date DESC, sh.id DESC
        ) AS row_num
    FROM subscription_history sh
    JOIN client c ON sh.client_id = c.id
) ranked_history
WHERE row_num = 1;

-- 2. COMPILING OPTION B: THE CTE + GROUP BY APPROACH (The "Tie Trap" Danger Zone)
-- Uses MAX() to isolate the highest date per client, then joins back.
CREATE OR REPLACE VIEW v_audit_summary_aggregation AS
WITH latest_subscription_dates AS (
    SELECT
        client_id,
        MAX(subscription_date) AS max_subscription_date
    FROM subscription_history
    GROUP BY client_id
)
SELECT
    c.name AS client_name,
    sh.model_portfolio,
    sh.subscription_date
FROM subscription_history sh
JOIN latest_subscription_dates lsd ON sh.client_id = lsd.client_id
                                  AND sh.subscription_date = lsd.max_subscription_date
JOIN client c ON sh.client_id = c.id;
