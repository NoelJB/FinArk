-- ============================================================================
-- FINARK PLATFORM - PHASE 2: EOD REGULATORY COMPLIANCE ENGINES
-- Target File: db/05-eod-regulation.sql
-- ============================================================================

\c paysprint;

-- 1. THE MATERIALIZED VIEW DEPLOYMENT
-- Physically captures and freezes a static audit snapshot of historical client portfolio compliance states on disk.
CREATE MATERIALIZED VIEW mv_eod_regulatory_compliance AS
SELECT 
    c.id AS client_id,
    c.name AS client_name,
    m.name AS active_portfolio,
    SUM(mi.weight) AS calculated_total_weight,
    CASE 
        WHEN SUM(mi.weight) = 1.0000 THEN 'COMPLIANT'
        ELSE 'OUT OF COMPLIANCE'
    END AS regulatory_status,
    CURRENT_TIMESTAMP AS snapshot_generated_at
FROM client c
JOIN model_portfolio m ON c.model_portfolio_id = m.id
JOIN model_instrument mi ON m.id = mi.model_id
GROUP BY c.id, c.name, m.name;

-- Create a unique physical block index on the materialized data cache to maximize query speed
CREATE UNIQUE INDEX idx_mv_regulatory_client ON mv_eod_regulatory_compliance(client_id);

-- 2. ADMINISTRATIVE INTEGRATION MECHANISM
-- Because a Materialized View is a frozen cache, it does not update automatically when base tables mutate.
-- This placeholder helper shows how a system cron task or transaction script refreshes data limits.
CREATE OR REPLACE PROCEDURE refresh_regulatory_snapshots()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Administrative Event: Re-indexing historical data caches...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_eod_regulatory_compliance;
END;
$$;
