# 📡 MARKET DATA INGESTION ENGINE ARCHITECTURE SPECIFICATIONS
### High-Performance Synchronization Canopy & Stateful Delta Recovery Blueprint

This document details the architectural design and resource-isolation constraints implemented inside the platform reference ingestion engine. The system synchronizes external cloud price data feeds directly into the persistent relational data layer and the low-latency volatile memory grid concurrently.

---

## 🏗️ 1. Invariant-Safe Local ID Mapping
To bypass database transaction read-snapshot limitations and race conditions caused by out-of-band asynchronous database seeding fixtures during container boot cycles, the ingestion system isolates variable identification mapping from downstream database execution blocks:

```text
[ Ingestion Thread Worker Boot ]
               │
               ▼
   SELECT id, ticker FROM instrument (Upfront Master Snapshot Scan)
               │
               ▼ Compiles:
   local_id_cache = { ticker: id } (Python Memory Lookup Dictionary)
               │
               ▼
   Fires Cloud Inbound Network Flights (23 Serialized Chunk Slices)
               │
               ▼
   Executes Relational DB UPDATE & COMMIT Transaction Blocks
               │
               ▼
   Loops Valkey Pipeline Command Stream:
   If ticker in local_id_cache -> Injects market_price:{id} to RAM
```

### Architectural Engineering Safeguards
* **Snapshot Isolation:** The master list of instrument primary keys and matching string tokens is fetched at the very entrance of the loop handler. This builds an immutable mapping dictionary in Python memory that is decoupled from downstream transaction boundaries.
* **Redundant Scan Elimination:** By caching the primary keys upfront in memory, the system skips running expensive secondary table select scans after the relational database writes complete, reducing data tier storage overhead to absolute zero.

---

## ⏱️ 2. Dynamic Cache Eviction & Time-To-Live (TTL) Parameters
Data caching lifecycles are explicitly separated by operational context to maximize grid memory efficiency while providing absolute starvation protection blocks:

### A. Cold-Start Pre-Warm Pass (Initial Hydration Phase)
* **Configuration Target:** `prewarm_and_hydrate_cache_universe`
* **Assigned Lifespan:** Strict **1-Hour TTL (3600 seconds)**.
* **Infrastructure Design Rationale:** Iterating sequentially across all 557 core instruments across the public network requires 23 separate, consecutive chunk flights. Because each individual flight handles network handshakes and includes an intentional `time.sleep(0.1)` pacing throttle to protect API gateway capacity limits, the loop requires several seconds to finish processing. Applying an extended 1-hour lifecycle ensures that the earliest chunk keys written to RAM are not auto-evicted by the memory manager before the entire master pass completes its relational disk commits.

### B. Heuristic Priority Sweeps (Continuous Maintenance Phase)
* **Configuration Target:** `_async_network_ingestion_worker` (Sweeps 1 & 2)
* **Assigned Lifespan:** Tight, aggressive **90-Second TTL**.
* **Infrastructure Design Rationale:** Scheduled ticks sweep the 25 most active and 25 most starved symbols every 60 seconds. A low-latency 90-second expiration ensures that stale price configurations are automatically pruned from memory in microseconds if a background microservice thread or cloud network lane drops out, preventing downstream applications from reading corrupt price metrics.

---

## 🔒 3. Concurrency Protection & Coexisting Database Drivers
The background orchestrator executes tasks concurrently within a single container layer while enforcing complete library isolation barriers:

* **Preemptive Concurrency Protection:** Task routing is wrapped inside a cooperative mutex lock (`_SYNC_LOCK = threading.Lock()`). If a network pass stalls and a secondary scheduled task tick fires, the entrance worker evaluates the lock status via `if _SYNC_LOCK.locked(): return` and instantly aborts, protecting database connections from thread pile-ups.
* **Multi-Paradigm Driver Coexistence:** To maximize execution throughput without triggering library compatibility friction, the platform configures a hybrid connection mesh inside the sidecar file layout:
  1. **Synchronous Ingestion:** Utilizes the pure-Python **`pg8000.dbapi`** driver context connected via blocking thread routines inside `market_sync.py` to handle standard data-tier writes.
  2. **Asynchronous Streaming:** Provisioned with compiled native C-extension drivers (**`asyncpg`** and **`aiokafka`**) to feed high-velocity event streams without stalling the parent scheduler.
