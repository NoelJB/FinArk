# FinArk Lesson: Understanding Database Views

Up to this point in your training, you have interacted with the database tier by executing raw, ad-hoc SQL statements. Whenever you needed information, your application sent a long string of query instructions to the server to join tables, compute metrics, and filter columns on the fly.

To build production-grade architectures, we introduce a powerful abstraction layer: The Database View.

---

## 1. What is a View? (The Conceptual Blueprint)

A standard Database View is a saved, named SQL query registered permanently inside the system catalog. 

A common student misconception is that a View is a new table that copies and duplicates your data. It is not. A standard View does not store any data rows on the disk. Instead, you are saving the blueprint of the query logic itself. 

Execution Layout Vector:
[ Application Layer ] -> Querying View: "SELECT * FROM v_compliance_window_analysis"
                                 |
                                 v
                     [ Relational Database Engine ]
                     - Looks up the saved View blueprint
                     - Executes the underlying SQL query against raw tables
                     - Returns data rows to the application instantly

Think of a View as a virtual table. To your backend application code (Java Spring Boot, NestJS, etc.), querying a View looks identical to querying a real physical table. The database engine intercepts the request, runs the underlying query logic behind the scenes, and passes the results back cleanly.

---

## 2. Why Use Views? (The Architectural Value)

Using Views instead of hardcoding raw queries into your backend application provides three massive engineering advantages:

* Decoupled UI & Schema Logic: If your frontend dashboard needs a complex portfolio drift percentage, your application code doesn't need to know how to calculate window partitions. It simply requests rows from the View. If you ever optimize your database table structures later, you only have to modify the inner query of the View—your application code remains completely untouched.
* Centralized Single Source of Truth: Instead of having three different backend microservices write their own slightly different SQL versions of what a "compliant portfolio" means, the business rules are written exactly once inside the database catalog. 
* Security & Column Redaction: If an auditor or external service needs access to client historical portfolio names but is legally blocked from seeing sensitive fields (like cash quantities, net worth, or advisor IDs), you can build a View that explicitly omits those columns. You grant the service permission to read the View while locking them completely out of the source tables.

---

## 3. Looking Ahead: Standard Views vs. Materialized Views

As the FinArk Platform scales to handle massive transaction volumes, standard views hit a strict physical limit: they calculate their inner math from scratch on every single execution. If a View contains complex window function partitioning or deep table joins, querying that view thousands of times a second will cause server CPU limits to skyrocket.

To solve this, enterprise systems use a hybrid structure called a Materialized View. 

Comparison Grid Metrics:
* Standard View: Stores zero data. Saves only the SQL code definition string. Re-runs the entire multi-table query block from scratch every time. Always reflects the exact microsecond state of base tables.
* Materialized View: Allocates real, physical space on disk to cache the query result rows. Reads pre-computed rows straight off the disk like a normal table. Becomes stale as base tables mutate until an explicit refresh occurs via the database command: REFRESH MATERIALIZED VIEW.

### The Materialized View Opportunity
Later in our curriculum, we will encounter an excellent scenario for a Materialized View: End-of-Day EOD Regulatory Compliance Audits. 

Because historical audit records for previous market close dates are static and never change, running heavy, repetitive window logic over millions of immutable history rows on every dashboard load is completely wasteful. We will write a Materialized View to freeze that snapshot data on disk, maximizing dashboard load performance while keeping database overhead at absolute zero.
