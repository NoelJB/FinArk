# FinArk Lesson: End-of-Day (EOD) Regulation & Materialized Views

## The Core Business Concept
Financial regulatory frameworks require platforms to maintain unalterable compliance reports showing that client investments match structural rules at market close. Because these historical audits represent a fixed moment in time, their values never fluctuate.

This module introduces students to the physical tier of data architecture by contrasting virtual views with physical data caching via Materialized Views.

---

## The Performance Problem with Standard Views
Standard views are elegant logic abstractions, but they hold a significant hidden infrastructure cost: they compute their inner code queries from scratch on every single execution. If an analytics view handles complex math, window partitioning, or heavy multi-table joins, querying that view thousands of times a minute on a high-traffic supervisor dashboard will exhaust server CPU threads and degrade platform performance.

## The Solution: Materialized Views
To protect infrastructure performance, we implement a Materialized View (mv_eod_regulatory_compliance). 

* How it Works: Unlike a virtual view, a Materialized View forces the database engine to allocate actual, physical space on the disk array to write and cache the exact query results as a static snapshot data block.
* The Performance Boost: Querying the materialized layer executes instantly because the database engine reads pre-computed rows straight off the disk like a static table, reducing computational overhead to zero.

---

## Managing Data Staleness (The Refresh Cycle)
The core architectural trade-off of a Materialized View is data freshness. Because the output is physically written to disk, it becomes "stale" the microsecond an underlying table mutates. 

To bridge this gap, enterprise architectures establish an explicit update workflow:
1. Snapshot Caching: The system reads the frozen cache for near-instant dashboard loads.
2. The Refresh Cron: An automated administrative task or background transaction worker executes the database refresh sequence on a routine schedule or at market close:
   REFRESH MATERIALIZED VIEW mv_eod_regulatory_compliance;
