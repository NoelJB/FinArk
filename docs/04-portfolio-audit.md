# FinArk Lesson: Active Portfolio Audits & The Microsecond Tie Trap

## The Core Business Concept
In enterprise architectures and financial systems, updating rows directly within historical tables is an audit risk. Instead, data modifications are logged by continuously appending fresh records onto a timeline table (an "append-only log"). 

In this sandbox, our subscription_history table functions as a compliance log tracking every asset mix strategy shift a client undergoes. When an internal auditor or compliance manager runs a platform report, they do not want to parse dead history records—they only want to query the single most recent active portfolio choice assigned to each unique person.

This lesson guides students through extracting chronologically ranked limits using standard window primitives while highlighting a severe production engineering hazard: The Microsecond Tie Trap.

---

## Technical Alterations: Surrogate Primary Keys

In basic database structures, designers frequently assign a composite primary key consisting of (client_id, subscription_date). While this enforces strict boundaries on paper, it introduces a dangerous system bug: if an advisor changes a client's strategy choice twice on the exact same calendar day, the database throws a unique constraint violation and crashes the user's transaction.

To ensure the historical log remains robust against multiple intraday revisions, FinArk drops the restrictive calendar date unique block and introduces a standard, independent surrogate auto-increment identity sequence:
GENERATED ALWAYS AS IDENTITY PRIMARY KEY

---

## Evaluating the Two Analytical Approaches

### Option A: The Window Function Approach (Recommended)
This approach wraps a ROW_NUMBER() calculation inside an inline subquery partition block:
ROW_NUMBER() OVER (PARTITION BY sh.client_id ORDER BY sh.subscription_date DESC, sh.id DESC)

* How it Works: It tells the relational engine to group records by each unique client_id, sort their log history chronologically by date, and use the auto-increment identity sequence as a secondary tie-breaker. It assigns a physical 'Row Number 1' to the absolute newest active state.
* Architectural Tradeoff: Performance is optimal because the database engine evaluates the log table exactly once in memory to execute the sort and filter. More importantly, it is immune to tie conditions—it guarantees exactly one row per client, always.

### Option B: The CTE + GROUP BY Approach (The "Tie Trap" Danger Zone)
This alternative method utilizes a Common Table Expression to extract the maximum date envelope per client using MAX(subscription_date), and then joins that result dataset back against the raw historical logs to resolve the portfolio names.

* The Performance Trap: This forces the database server to perform an expensive double table scan. It must read the log table once to compute the maximum dates, and a second time to execute the inner data join.
* The "Microsecond Tie" Trap: If a client triggers two strategy updates on the exact same date stamp (or millisecond stamp, depending on production column choices), MAX() will match both entries. When the join executes, the view will duplicate that client's records in the final audit report. This creates a severe data duplication error that throws automated downstream reporting or billing metrics completely out of line.
