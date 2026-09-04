-- ============================================================================
-- FINARK PLATFORM - PHASE 3: IMMUTABLE TRANSACTION EXECUTION LEDGER
-- Target File: db/08-execution-ledger.sql
-- ============================================================================

\c paysprint;

-- 1. THE IMMUTABLE EXECUTION LEDGER TABLE
-- Tracks the raw economic realities of trades. Rows are strictly append-only.
CREATE TABLE trade_execution (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id INT NOT NULL,
    instrument_id INT NOT NULL,
    side VARCHAR(4) NOT NULL, -- Must be 'BUY' or 'SELL'
    quantity NUMERIC(18, 4) NOT NULL,
    execution_price NUMERIC(18, 4) NOT NULL,
    executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_execution_client FOREIGN KEY (client_id) REFERENCES client(id),
    CONSTRAINT fk_execution_instrument FOREIGN KEY (instrument_id) REFERENCES instrument(id),
    CONSTRAINT chk_execution_side CHECK (side IN ('BUY', 'SELL')),
    CONSTRAINT chk_execution_qty CHECK (quantity > 0.0000),
    CONSTRAINT chk_execution_price CHECK (execution_price > 0.0000)
);

-- 2. AUTOMATED SYNCHRONOUS SETTLEMENT & RELAY TRIGGER ROUTINE
-- Handles internal clearing house mechanics and emits events atomically to the outbox.
CREATE OR REPLACE FUNCTION queue_trade_execution_event()
RETURNS TRIGGER AS $$
BEGIN
    -- STEP A: Simulated Internal Clearing/Settlement (Mutates asset balance inventory)
    IF NEW.side = 'BUY' THEN
        INSERT INTO client_instrument (client_id, instrument_id, quantity)
        VALUES (NEW.client_id, NEW.instrument_id, NEW.quantity)
        ON CONFLICT (client_id, instrument_id) 
        DO UPDATE SET quantity = client_instrument.quantity + EXCLUDED.quantity;
    ELSIF NEW.side = 'SELL' THEN
        UPDATE client_instrument 
        SET quantity = quantity - NEW.quantity
        WHERE client_id = NEW.client_id AND instrument_id = NEW.instrument_id;
    END IF;

    -- STEP B: Write the 'TRADE_EXECUTED' event frame atomically to the polymorphic outbox log
    INSERT INTO outbox (aggregate_type, aggregate_id, event_type, payload)
    VALUES (
        'CLIENT_PORTFOLIO',
        NEW.client_id::VARCHAR,
        'TRADE_EXECUTED',
        jsonb_build_object(
            'execution_id', NEW.id,
            'client_id', NEW.client_id,
            'instrument_id', NEW.instrument_id,
            'action', NEW.side,
            'quantity', NEW.quantity,
            'price', NEW.execution_price,
            'executed_at', NEW.executed_at
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_on_trade_execution
    AFTER INSERT ON trade_execution
    FOR EACH ROW
    EXECUTE FUNCTION queue_trade_execution_event();
