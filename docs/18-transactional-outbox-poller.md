# 🪐 TRANSACTIONAL OUTBOX STREAM RELAY ENGINE SPECIFICATIONS
### Asynchronous Cooperative Resource Controls & Inversion-Of-Control Callbacks

This specification documents the asynchronous, event-driven message relayer daemon tasked with bridging persistent relational ledger mutations to the distributed Apache Kafka streaming cluster brokers.

---

## 🏗️ 1. Loose-Coupled Self-Pacing Loop Architecture
Traditional background microservice workers execute inside rigid infinite loop structures configured on fixed interval ticks. Under heavy systemic volume spikes, this pattern thrashes operating system threads and causes aggressive container memory fragmentation. 

The platform re-engineers this by implementing an uncoupled **Self-Paced Rescheduling Hook Loop**:

```text
[ main.py Entrypoint ] ──> Queues single-shot task pass (Delay = 60s Buffer)
                                         │
                                         ▼ Fires:
                             [ execute_outbox_stream_relay ]
                                         │
                                         ▼ Spawns:
                             [ _worker_thread_entrypoint ]
                                         │
                                         ▼ Boots isolated loop:
                             [ _async_outbox_processing_loop ]
                                         │
                                         ▼ Clears table queue, then:
                             [ loop.close() Teardown Canopy ]
                                         │
                                         ▼ Triggers:
                             if reschedule -> reschedule() (lambda closure)
                                         │
                                         ▼ (Inverts Control)
                             Re-injects single-shot delayed task pass (5s)
```

### Operational Invariants
* **Inversion of Control (IoC):** The outbox task module (`outbox_poller.py`) accepts a zero-argument function pointer argument (`reschedule=None`). It executes its data pipelines completely blinded to the class mechanics or method signatures of the parent scheduler engine, achieving absolute loose coupling.
* **Dynamic Load Absorption:** The single-shot delayed pass configuration ensures that the 5-second cooldown timer begins counting down **only after the current row processing workload has completely finished on disk**. If a trade explosion stalls the network, the scheduler slows its frequency automatically, scaling execution pacing dynamically under load.

---

## 🔒 2. Non-Blocking Row Isolation & Type Serialization Contracts

### A. High-Performance Concurrency Partitioning
Multiple horizontal scaling sidecar containers can query the outbox database partition simultaneously without hitting deadlock blocks or resource contentions. The script achieves this by executing a non-blocking PostgreSQL locking primitive statement:
```sql
SELECT id, aggregate_type, aggregate_id, event_type, payload 
FROM outbox 
WHERE status = 'PENDING' 
ORDER BY created_at ASC 
LIMIT 100 
FOR UPDATE SKIP LOCKED;
```
The relational engine isolates up to 100 pending records for the current connection, while instructionally skipping any rows already locked by parallel workers, optimizing cross-service scalability.

### B. Binary Type Serialization Parity
The relayer module leverages `asyncpg`’s native binary type decoders to strip processing latency. Because the `payload` database column uses the native **`JSONB` binary data format**, `asyncpg` automatically deserializes the wire bytes straight into a pre-hydrated Python dictionary object. 

The loop bypasses redundant runtime casting (`dict()`) constructors, feeding the memory object directly to the `json.dumps()` stream to output raw UTF-8 transmission wire bytes straight to the broker socket lanes.

---

## 🛡️ 3. At-Least-Once Delivery Guarantees
To satisfy modern financial audit guidelines, the platform enforces an absolute atomic commit boundary wrapper rule:

```text
1. Fetch 100 PENDING Rows  ──>  2. Stream payload over Kafka wire
                                            │
   4. DB SET status='SENT' <──  3. Await verified Broker Partition ACK Receipt
```

* **No Phantom Emissions:** The database row status can never toggle from `PENDING` to `SENT` pre-emptively. The script drops an explicit `await producer.send_and_wait()` anchor. 
* **Atomic Failure Isolations:** If the Kafka broker drops a connection packet or fails to synchronize its metadata partitions mid-flight, the acknowledgment fails. The inner loop intercepts the error trace inside an isolated `try/except` canopy, updates the status flag locally to `FAILED`, and rolls back the database transaction, keeping systems aligned.
