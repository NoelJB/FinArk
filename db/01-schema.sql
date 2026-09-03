-- ============================================================================
-- 01-schema.sql: CORE TABLE DEFINITIONS & CONSTRAINTS
-- ============================================================================

\c paysprint;

-- 1. INDEPENDENT TABLES
CREATE TABLE advisor (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE model_portfolio (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE instrument (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    current_price NUMERIC(18, 4) NOT NULL DEFAULT 1.0000
);

-- 2. CORE ENTITIES
CREATE TABLE client (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    advisor_id INT NOT NULL,
    model_portfolio_id INT,
    subscription_date DATE,
    CONSTRAINT fk_client_advisor FOREIGN KEY (advisor_id) REFERENCES advisor(id) ON DELETE RESTRICT,
    CONSTRAINT fk_client_portfolio FOREIGN KEY (model_portfolio_id) REFERENCES model_portfolio(id) ON DELETE SET NULL
);

-- 3. ASSOCIATIVE & HISTORY TABLES
CREATE TABLE subscription_history (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    model_portfolio VARCHAR(255) NOT NULL,
    subscription_date DATE NOT NULL,
    CONSTRAINT fk_history_client FOREIGN KEY (client_id) REFERENCES client(id) ON DELETE CASCADE
);

CREATE TABLE client_instrument (
    client_id INT NOT NULL,
    instrument_id INT NOT NULL,
    quantity NUMERIC(18, 4) NOT NULL DEFAULT 0.0000,
    PRIMARY KEY (client_id, instrument_id),
    CONSTRAINT fk_ci_client FOREIGN KEY (client_id) REFERENCES client(id) ON DELETE CASCADE,
    CONSTRAINT fk_ci_instrument FOREIGN KEY (instrument_id) REFERENCES instrument(id) ON DELETE RESTRICT
);

CREATE TABLE model_instrument (
    model_id INT NOT NULL,
    instrument_id INT NOT NULL,
    weight NUMERIC(5, 4) NOT NULL,
    PRIMARY KEY (model_id, instrument_id),
    CONSTRAINT fk_mi_model FOREIGN KEY (model_id) REFERENCES model_portfolio(id) ON DELETE CASCADE,
    CONSTRAINT fk_mi_instrument FOREIGN KEY (instrument_id) REFERENCES instrument(id) ON DELETE RESTRICT,
    CONSTRAINT chk_weight_range CHECK (weight >= 0.0000 AND weight <= 1.0000)
);

-- 4. PERFORMANCE INDEXES
CREATE INDEX idx_client_advisor ON client(advisor_id);
CREATE INDEX idx_sub_history_lookup ON subscription_history(client_id, subscription_date DESC);
CREATE INDEX idx_client_inst_inst ON client_instrument(instrument_id);
