# services/orchestrator-sidecar/tasks/market_sync.py
import os
import sys
import time
import threading
import valkey
import pg8000.dbapi
from contextlib import closing
from tasks.fauxnance_client import fetch_market_quotes_with_deltas

DB_HOST = os.getenv("DB_HOST", "paysprint-postgres")
VALKEY_HOST = os.getenv("VALKEY_HOST", "paysprint-cache")
VALKEY_PORT = int(os.getenv("VALKEY_PORT", 6379))
DB_NAME = "paysprint"
DB_USER = "postgres"

SECRET_DB_PASS_PATH = "/run/secrets/pg_master_pass"
SECRET_API_URL_PATH = "/run/secrets/fauxnance_api_url"
SECRET_API_KEY_PATH = "/run/secrets/fauxnance_api_key"

_UNIVERSE_INGESTED = False
_PENDING_PREWARM_SYMBOLS = set()
_SYNC_LOCK = threading.Lock()

def read_hardened_container_secret(file_path):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"🚷 Secret missing at: {file_path}")
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read().strip()

DB_PASSWORD = read_hardened_container_secret(SECRET_DB_PASS_PATH)
FAUXNANCE_BASE_URL = read_hardened_container_secret(SECRET_API_URL_PATH)
FAUXNANCE_KEY = read_hardened_container_secret(SECRET_API_KEY_PATH)

def prewarm_and_hydrate_cache_universe(cursor, cache):
    global _UNIVERSE_INGESTED, _PENDING_PREWARM_SYMBOLS
    try:
        if not _UNIVERSE_INGESTED and not _PENDING_PREWARM_SYMBOLS:
            print("⏳ [market-sync] Warming cache grid... Initializing delta tracking set...", flush=True)
            # 🟢 FIXED: Extract strings via index position 0 from rows container cleanly
            cursor.execute("SELECT ticker FROM instrument WHERE instrument_type != 'CASH';")
            _PENDING_PREWARM_SYMBOLS = {row[0] for row in cursor.fetchall() if row}
            
        if not _PENDING_PREWARM_SYMBOLS:
            print("⏳ [market-sync] Instrument master is blank or already fully synchronized.", flush=True)
            return

        print(f"📡 [market-sync] Stateful Delta Pass: {len(_PENDING_PREWARM_SYMBOLS)} symbols remaining to prefetch.", flush=True)
        target_url = f"{FAUXNANCE_BASE_URL.rstrip('/')}/quotes"
        
        price_update_batch, failed_set = fetch_market_quotes_with_deltas(target_url, FAUXNANCE_KEY, _PENDING_PREWARM_SYMBOLS)
        
        print(f"Size of universe: {len(_PENDING_PREWARM_SYMBOLS)}. Failed chunks count = {len(failed_set)}", flush=True)

        if price_update_batch:
            print(f"💾 [market-sync] Bulk writing {len(price_update_batch)} successful cloud entries to disk...", flush=True)
            cursor.execute("BEGIN;")
            cursor.executemany("UPDATE instrument SET current_price = %s, last_synced_at = CURRENT_TIMESTAMP WHERE ticker = %s;", price_update_batch)
            cursor.execute("COMMIT;")

            # 🟢 FIXED: Fetch the ID map AFTER commit completes to guarantee snapshot visibility over all 557 items
            cursor.execute("SELECT id, ticker FROM instrument WHERE instrument_type != 'CASH';")
            local_id_cache = {row[1]: int(row[0]) for row in cursor.fetchall() if row}

            print(f"Loading valkey ... Batch: {len(price_update_batch)}, Cache: {len(local_id_cache)}")
            valkey_pipe = cache.pipeline()
            for price, ticker in price_update_batch:
                if ticker in local_id_cache:
                    valkey_pipe.setex(f"market_price:{local_id_cache[ticker]}", 3600, str(price))
            valkey_pipe.execute()

        _PENDING_PREWARM_SYMBOLS = failed_set
        
        if not _PENDING_PREWARM_SYMBOLS:
            _UNIVERSE_INGESTED = True
            print("✅ [market-sync] Core master prefetch 100% complete. All deltas cleared.", flush=True)
        else:
            print(f"⚠️ [market-sync] Delta prefetch partial save. {len(_PENDING_PREWARM_SYMBOLS)} failed symbols deferred to next pass.", flush=True)
            
    except Exception as e:
        print(f"⚠️ [market-sync] Prefetch block exception: {e}", flush=True)

def _async_network_ingestion_worker():
    global _UNIVERSE_INGESTED
    
    print(f"Ingestion: {_UNIVERSE_INGESTED=}, Locked: {_SYNC_LOCK.locked()}", flush=True)
    if _SYNC_LOCK.locked():
        return
    try:
        with (
            _SYNC_LOCK,
            pg8000.dbapi.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD) as conn,
            closing(conn.cursor()) as cursor
        ):
            cache = valkey.Valkey(host=VALKEY_HOST, port=VALKEY_PORT, decode_responses=True)
            if not _UNIVERSE_INGESTED:
                prewarm_and_hydrate_cache_universe(cursor, cache)

            if _UNIVERSE_INGESTED:
                cursor.execute("SELECT id, ticker FROM instrument WHERE instrument_type != 'CASH';")
                local_id_cache = {row[1]: int(row[0]) for row in cursor.fetchall() if row}

                cursor.execute("SELECT i.ticker FROM instrument i JOIN trade_execution te ON i.id = te.instrument_id WHERE i.last_synced_at <= NOW() - INTERVAL '90 seconds' AND i.instrument_type != 'CASH' GROUP BY i.id, i.ticker ORDER BY MAX(te.executed_at) DESC LIMIT 25;")
                hot_symbols = [row[0] for row in cursor.fetchall() if row]

                cursor.execute("SELECT ticker FROM instrument WHERE instrument_type != 'CASH' ORDER BY last_synced_at ASC LIMIT 25;")
                stale_symbols = [row[0] for row in cursor.fetchall() if row]

                ticker_set = set(hot_symbols + stale_symbols)
                if ticker_set:
                    loop_target_url = f"{FAUXNANCE_BASE_URL.rstrip('/')}/quotes"
                    sync_batch, failed_loop_set = fetch_market_quotes_with_deltas(loop_target_url, FAUXNANCE_KEY, ticker_set)
                    
                    if sync_batch:
                        cursor.execute("BEGIN;")
                        cursor.executemany("UPDATE instrument SET current_price = %s, last_synced_at = CURRENT_TIMESTAMP WHERE ticker = %s;", sync_batch)
                        cursor.execute("COMMIT;")

                        valkey_pipe = cache.pipeline()
                        for p, t in sync_batch:
                            if t in local_id_cache:
                                valkey_pipe.setex(f"market_price:{local_id_cache[t]}", 90, str(p))
                        valkey_pipe.execute()
                        print(f"📡 [market-sync] 1-Minute batch pass completed. Synchronized {len(sync_batch)} entries.", flush=True)
    except Exception as e:
        print(f"⚠️ [market-sync] Background sync loop encountered an error: {e}", flush=True)

def execute_dual_query_sync_pass():
    print("Starting market_sync", flush=True)
    threading.Thread(target=_async_network_ingestion_worker, daemon=True).start()
