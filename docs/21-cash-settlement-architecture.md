# 🪙 CASH SETTLEMENT & HORIZON LEDGER SPECIFICATIONS
### Analytical Window Horizons, Settleable Cash Invariants, and Purchasing Power Derivations

This document establishes the official reference architecture for tracking Settled Cash versus Unsettled Cash within the platform data tier. To protect system performance and maintain third-normal-form (3NF) relational integrity, positions are calculated dynamically via chronological database views rather than introducing table schema mutations.

---

## 🏗️ 1. Core Financial Data Invariants
All fiat currencies inside the wealth management chasis behave identically to tradable asset coordinates. The platform tracks cleared capital balances cleanly by mapping distinct associative rows inside the primary `client_instrument` inventory table to our persistent currency tokens:
*   `CASHGBP` (Cash - British Pound Sterling)
*   `CASHUSD` (Cash - United States Dollar)

### The Purchasing Power Equation
In professional wealth management and high-frequency clearing engines, a tenant's absolute available transaction limits are defined by a rolling **Settlement T+1 Window Horizon**. Direct table updates to single balance columns are blocked; calculations are derived continuously over the append-only transactional ledger:

\[\text{Available Purchasing Power} = \text{Settled Cleared Cash} + \text{Unsettled Trade Deltas}\]

---

## 📊 2. Dynamic Settlement Ledger Blueprint (`db/core_ddl/`)
The following reference query details the analytical window definition used to calculate un-cleared cash balances and enforce pre-trade capital coverage restrictions dynamically at runtime:

```sql
-- Target Migration: db/core_ddl/21-cash-settlement-ledger.sql
\c paysprint;

CREATE OR REPLACE VIEW v_client_cash_settlement_ledger AS
WITH pending_settlement_cash AS (
    -- Step A: Aggregate all append-only trades executed within the active clearing window
    SELECT 
        te.client_id,
        i.currency,
        SUM(
            CASE 
                WHEN te.side = 'BUY' THEN -(te.quantity * te.execution_price)
                WHEN te.side = 'SELL' THEN (te.quantity * te.execution_price)
            END
        ) AS unsettled_cash_delta
    FROM trade_execution te
    JOIN instrument i ON te.instrument_id = i.id
    WHERE te.executed_at >= NOW() - INTERVAL '24 hours' -- Enforces a standard T+1 Execution Horizon
    GROUP BY te.client_id, i.currency
)
-- Step B: Merge transactional deltas onto physical inventory balances via an outer join
SELECT 
    c.id AS client_id,
    c.name AS client_name,
    inst.ticker AS cash_ticker,
    COALESCE(ci.quantity, 0.0000) AS settled_cash_balance,
    COALESCE(psc.unsettled_cash_delta, 0.0000) AS unsettled_cash_horizon,
    (COALESCE(ci.quantity, 0.0000) + COALESCE(psc.unsettled_cash_delta, 0.0000)) AS available_purchasing_power
FROM client c
JOIN instrument inst ON inst.instrument_type = 'CASH'
LEFT JOIN client_instrument ci ON c.id = ci.client_id AND inst.id = ci.instrument_id
LEFT JOIN pending_settlement_cash psc ON c.id = psc.client_id AND inst.currency = psc.currency;
```

---

## 🛡️ 3. Pre-Trade Capital Coverage Restrictions
When the platform processes an incoming order structure, the ingestion services evaluate this ledger snapshot to validate capital constraints before any transaction can land on the append-only disk engine:

1. **BUY Transactions:** The Spring Boot validation layer reads the matching currency row's `available_purchasing_power` field and asserts that it is greater than or equal to the total order cost (`quantity * price`). If a tenant attempts to spend un-cleared capital outside the settlement window, the transaction is instantly rejected at the boundary.
2. **Asynchronous Clearing Passes:** Downstream settlement services process batch maturities by pushing rows to an independent data warehouse, executing automated cache-pruning passes, and resetting the T+1 horizon parameters, maintaining a zero-leak footprint.
