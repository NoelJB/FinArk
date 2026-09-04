-- ============================================================================
-- FINARK PLATFORM - PHASE 2: PORTFOLIO DRIFT MONITORING LAYER
-- Target File: db/04-portfolio-monitoring.sql
-- ============================================================================

\c paysprint;

-- 1. POLYMORPHIC TRANSACTIONAL OUTBOX LOG TABLE
CREATE TABLE outbox (
    id BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL, -- 'ADVISOR_DASHBOARD', 'CLIENT_PORTFOLIO'
    aggregate_id VARCHAR(100) NOT NULL,   -- Maps to client_id
    event_type VARCHAR(100) NOT NULL,     -- 'DRIFT_ALERT' or 'TRADE_EXECUTED'
    payload JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT chk_outbox_status CHECK (status IN ('PENDING', 'SENT', 'FAILED'))
);

CREATE INDEX idx_outbox_pending ON outbox(status, created_at ASC);

-- 2. REACTIVE PORTFOLIO DRIFT COMPLIANCE ALERTER TRIGGER ROUTINE
CREATE OR REPLACE FUNCTION check_portfolio_drift_compliance()
RETURNS TRIGGER AS $$
DECLARE
    max_drift NUMERIC(5,4);
BEGIN
    -- Query our window analytics view to locate the highest absolute deviation
    SELECT MAX(ABS(drift_variance)) INTO max_drift
    FROM v_client_portfolio_drift
    WHERE client_id = COALESCE(NEW.client_id, OLD.client_id);

    -- If a future modification pushes them past ±2% variance, flag a breach
    IF max_drift > 0.0200 THEN
        INSERT INTO outbox (aggregate_type, aggregate_id, event_type, payload)
        VALUES (
            'ADVISOR_DASHBOARD',
            COALESCE(NEW.client_id, OLD.client_id)::VARCHAR,
            'DRIFT_ALERT',
            jsonb_build_object(
                'client_id', COALESCE(NEW.client_id, OLD.client_id),
                'max_drift_detected', max_drift,
                'status', 'BREACH',
                'alert_timestamp', CURRENT_TIMESTAMP
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evaluate_drift_post_trade
    AFTER INSERT OR UPDATE ON client_instrument
    FOR EACH ROW
    EXECUTE FUNCTION check_portfolio_drift_compliance();

-- 3. HISTORICAL MIGRATION BACKFILL (Captures pre-existing anomalies like Alice)
INSERT INTO outbox (aggregate_type, aggregate_id, event_type, payload)
SELECT 
    'ADVISOR_DASHBOARD' AS aggregate_type,
    client_id::VARCHAR AS aggregate_id,
    'DRIFT_ALERT' AS event_type,
    jsonb_build_object(
        'client_id', client_id,
        'max_drift_detected', MAX(ABS(drift_variance)),
        'status', 'BREACH',
        'alert_timestamp', CURRENT_TIMESTAMP
    ) AS payload
FROM v_client_portfolio_drift
GROUP BY client_id
HAVING MAX(ABS(drift_variance)) > 0.0200;
