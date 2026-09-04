# FinArk Architecture: Immutable Transaction Execution Ledger

## 🧠 Core Philosophy: The Single Source of Economic Reality
In standard commercial application design, developers frequently update account balance columns directly whenever an event occurs (e.g., adding or subtracting numbers inside a client portfolio row). In professional banking, wealth management, and high-frequency trading platforms, this architecture represents a critical operational risk. If a database record is corrupted or modified incorrectly, the true audit trail is completely lost.

FinArk enforces systemic compliance by applying the principle of an **Immutable Append-Only Ledger**. 

```text
Incoming Order -> [ trade_execution ] (Append-Only Immutable Entry Ledger)
                           │
                           ▼
             trg_on_trade_execution Trigger
                           │
           ┌───────────────┴───────────────┐
           ▼                               ▼
[ client_instrument ]            [ outbox ]
(Synchronous Settlement Cache)   (Polymorphic Event Pipeline)
```

The `trade_execution` table functions as the ultimate economic source of truth. Data entries are strictly read-and-append. Rows inside this table can never be altered via `UPDATE` or deleted via `DELETE` statements. If a mistake happens, an explicitly balanced reversing transaction entry must be appended to the log instead.

---

## 🏗️ Automated Synchronous Clearing & Event Emission

To guarantee atomicity and keep data layers decoupled, writing a row into the ledger triggers two separate system actions inside a single database transaction context:

### 1. Simulated Internal Clearing/Settlement
The trigger routine intercepts the incoming trade record and immediately balances the inventory:
* BUY Order: Injects or updates the target security inside the `client_instrument` cache using an ON CONFLICT DO UPDATE clause.
* SELL Order: Subtracts the settled share counts cleanly from the customer balance.

### 2. Transactional Outbox Staging
Simultaneously, the trigger processes the transaction attributes, formats them into a polymorphic binary document frame (`event_type = 'TRADE_EXECUTED'`), and streams it straight into the `outbox` pipeline table. Because this occurs inside the exact same atomic transaction boundary, database adjustments and event logs succeed or fail as a single unit, avoiding data sync anomalies.
