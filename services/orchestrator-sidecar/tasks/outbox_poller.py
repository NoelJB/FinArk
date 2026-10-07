# services/orchestrator-sidecar/tasks/outbox_poller.py
import os
import sys
import json
import asyncio
import threading
import asyncpg
from aiokafka import AIOKafkaProducer

SECRET_DB_PASS_PATH = "/run/secrets/pg_master_pass"
DB_HOST = os.getenv("DB_HOST", "paysprint-postgres")
DB_NAME = "paysprint"
DB_USER = "postgres"
KAFKA_SERVER = os.getenv("KAFKA_BOOTSTRAP_SERVER", "paysprint-kafka:29092")

_POLLER_LOCK = threading.Lock()

def read_hardened_container_secret(file_path):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"🚷 Secret missing at: {file_path}")
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read().strip()

DB_PASSWORD = read_hardened_container_secret(SECRET_DB_PASS_PATH)

async def _async_outbox_processing_loop():
    """Inner coroutine event loop managing transactional outbox event distribution

    using native pre-parsed asyncpg binary type decoders.
    """
    producer = None
    conn = None
    try:
        # Context manager handles the non-blocking production Kafka client lifecycle
        async with AIOKafkaProducer(bootstrap_servers=KAFKA_SERVER) as producer:
            
            conn = await asyncpg.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            
            async with conn.transaction():
                # 🪐 HIGH-PERFORMANCE NON-BLOCKING ROW LOCKING
                records = await conn.fetch("""
                    SELECT id, aggregate_type, aggregate_id, event_type, payload 
                    FROM outbox 
                    WHERE status = 'PENDING' 
                    ORDER BY created_at ASC 
                    LIMIT 100 
                    FOR UPDATE SKIP LOCKED;
                """)

                if not records:
                    return

                print(f"📡 [outbox-poller] Isolated {len(records)} pending events from the outbox queue.", flush=True)

                for row in records:
                    row_id = row['id']
                    topic_channel = row['aggregate_type']  # -- Polymorphic topic routing key
                    event_key = row['aggregate_id']
                    
                    # 🟢 FIXED: Removed the redundant dict() conversion constructor.
                    # Since asyncpg pre-decodes JSONB columns into dictionaries natively, 
                    # we serialize the pre-parsed payload directly to transmission wire bytes.
                    serialized_payload = json.dumps(row['payload']).encode('utf-8')

                    try:
                        # Stream event packet asynchronously and await verified partition acknowledgment
                        await producer.send_and_wait(
                            topic=topic_channel,
                            value=serialized_payload,
                            key=event_key.encode('utf-8')
                        )
                        
                        # Mark as SENT only after the streaming layer registers partition success
                        await conn.execute("UPDATE outbox SET status = 'SENT' WHERE id = $1;", row_id)
                        print(f"✅ [outbox-poller] Event ID {row_id} successfully streamed to Kafka topic '{topic_channel}'.", flush=True)

                    except Exception as streaming_err:
                        print(f"❌ [outbox-poller] Failed to relay event ID {row_id}: {streaming_err}", file=sys.stderr, flush=True)
                        await conn.execute("UPDATE outbox SET status = 'FAILED' WHERE id = $1;", row_id)

    except Exception as system_err:
        print(f"⚠️ [outbox-poller] Transactional event sweep encountered an infrastructure error: {system_err}", file=sys.stderr, flush=True)
    finally:
        if conn:
            try:
                await conn.close()
            except Exception:
                pass

def _worker_thread_entrypoint(reschedule):
    """Runs inside the detached background OS worker thread to manage the asyncio lifecycle and handle closures."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        loop.run_until_complete(_async_outbox_processing_loop())
    finally:
        loop.close()
        if reschedule: 
            reschedule()

def execute_outbox_stream_relay(reschedule=None):
    """Synchronous task gateway that spawns its own background thread worker internally."""
    if _POLLER_LOCK.locked():
        return
        
    with _POLLER_LOCK:
        threading.Thread(target=_worker_thread_entrypoint, args=(reschedule,), daemon=True).start()
