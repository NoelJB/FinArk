# FinArk Architecture: Moving Beyond Simple Data Updates

When building software that interacts with a database, it is tempting to jump straight into making raw state changes. If a customer buys shares of a stock, your first instinct might be to write code that immediately modifies their balance row in an inventory table. 

While that approach works fine for simple apps, mutating inventory tables directly is a severe architectural anti-pattern for professional trading networks and enterprise platforms.

This document explains why that anti-pattern breaks production networks, how the FinArk Architecture corrects it using an immutable ledger, and how all the moving parts work together.

---

## 1. The Core Problem: Why Direct Updates Fail

In a basic database setup, a trade might look like this:

[ Incoming Buy Order ] -> ( Direct UPDATE / INSERT ) -> [ client_instrument Table ]

This direct-mutation approach introduces two critical failures into an enterprise environment:

* The Loss of Truth (No Audit Trail): Financial systems must maintain a permanent historical log of exactly WHY a balance changed. If an inventory table simply shows that a client owns 400 shares of a stock today, you have no native database record showing whether they bought those shares all at once, accumulated them over ten separate trades, or inherited them. The history is erased.
* The Synchronization Nightmare: Professional applications do not live in isolation. If a trade executes, external systems (like an advisor's dashboard or a clearinghouse broker) need to be notified instantly via a streaming framework like Apache Kafka. If your application attempts to update the database table and talk to a network message broker at the same time, a temporary network glitch will throw the entire system out of sync.

---

## 2. The Solution: The Immutable Ledger & The Outbox Pattern

To protect data integrity, professional financial systems separate the INTENT of a transaction from the CURRENT BALANCE STATE of the system. We achieve this by combining three core engineering patterns into a unified database layer:

1. The Immutable Ledger (trade_execution): We establish a strictly append-only table. Rows are only ever inserted; they are never updated or deleted. This serves as our absolute source of truth and audit history.
2. Automated Synchronous Settlement: The moment a trade lands in our ledger, a database trigger automatically handles updating the client's current asset balance behind the scenes.
3. The Polymorphic Outbox (outbox): A single, generic tracking table acts as an box envelope. Instead of sending messages across a shaky network during a live trade, we write the event data directly into this local database table inside the exact same atomic transaction block.

The FinArk Transaction Lifecycle Flow:
[ 1. Append Intent ] -> [ 2. Auto-Settle Balance ] -> [ 3. Stage Outbox Payload ]
INSERT trade_execution     Trigger updates balances     Atomic JSONB snapshot captured
 (Strictly Immutable)     client_instrument quantities   safely inside Outbox envelope

---

## 3. Breaking Down the System Moving Parts

The db/03-execution-ledger.sql script sets up four specific database components that operate sequentially like clockwork. Here is exactly how they handle a single incoming transaction:

### Component A: The trade_execution Ledger
This table tracks the raw economic realities of the trade itself. 
* The side Column: Explicitly locked via constraints to only accept 'BUY' or 'SELL'.
* Defensive Guards: Strict check constraints block negative prices or zero quantities before the row can even touch the disk storage engine.

### Component B: The Polymorphic outbox Log
This is a shared, generic table that can hold absolutely any event type from any domain within our system.
* aggregate_type & event_type: These text columns act as routing tags (e.g., 'CLIENT_PORTFOLIO' and 'TRADE_EXECUTED'). They tell our background workers exactly which network streaming channels (Kafka topics) this specific message belongs on.
* The payload Column: Utilizes PostgreSQL's native binary JSON format (JSONB). Because it is unstructured document storage, a trade record containing stock tickers can sit right next to a system alert record containing percentage calculations in the same table.

### Component C: The Settlement Trigger (trg_on_trade_execution)
This component acts as an automated clearinghouse. The split second an INSERT hits our immutable ledger table, this trigger interceptor fires:
1. Clears the Trade: It checks if the trade was a BUY or a SELL. If it was a BUY, it safely increments the client's asset count using an ON CONFLICT merge rule. If it was a SELL, it decrements their share count.
2. Envelopes the Event: In the very next line of code, it constructs a complete JSON document containing the trade data and drops it directly into the outbox table. 

Note on the ACID Guarantee: Because this trigger executes completely inside the original transaction boundary, it is ATOMIC. If the balance adjustment fails (for example, if a client tries to sell shares they don't own, tripping a constraint), the entire transaction rolls back. The ledger row vanishes, the outbox record vanishes, and zero corrupt data leaks into your infrastructure.

### Component D: The Reactive Drift Monitor (trg_evaluate_drift_post_trade)
Our system's final moving part provides decoupled system awareness. Because Component C just updated our client asset balances, the client's portfolio allocation percentages have shifted. This trigger instantly fires on the asset balance table to evaluate compliance:
1. Scans the Analytics View: It checks our pre-built window analytics view (v_client_portfolio_drift) to find the highest absolute drift variation for that specific client.
2. Enforces the Tolerance Gatekeeper: If it detects that the client's asset mix has drifted past your strict 2% (0.0200) safety band, it creates a second type of message envelope ('DRIFT_ALERT') and drops it straight into that exact same polymorphic outbox table.

---

## 4. Why This Architecture Matters

By implementing this layout, you are cleanly demonstrating a production-grade backend design:
* Guaranteed Data Consistency: Your data pipeline will never broadcast a phantom event across your network because event creation is structurally bound to database storage success.
* Clean Architectural Boundaries: Your user-facing code only has to worry about appending rows to an immutable ledger. The database itself completely automates state updates, compliance scanning, and microservice messaging records under the hood.
