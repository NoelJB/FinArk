#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - DUAL-QUERY REFERENCE MARKET SYNC DAEMON TASK
# Target File: services/orchestrator-sidecar/tasks/market_sync.py
# BRS Mapping: BR-16 Long-Running Dual-Query Cloud Quota Protection
# ============================================================================

import os
import sys
import requests
import valkey
import pg8000.dbapi

DB_HOST = os.getenv("DB_HOST", "paysprint-postgres")
VALKEY_HOST = os.getenv("VALKEY_HOST", "paysprint-cache")
VALKEY_PORT = int(os.getenv("VALKEY_PORT", 6379))
DB_NAME = "paysprint"
DB_USER = "postgres"

FAUXNANCE_URL = "https://amazonaws.com"
FAUXNANCE_KEY = "fnx_dev_l8DbdCpp7D2Ld42KBdBu5jkW5lYfH3f7"
SECRET_FILE_PATH = "/run/secrets/pg_master_pass"

def get_vault_password():
    """Securely extracts master administrative database tokens from mounted secret volumes."""
    if os.path.exists(SECRET_FILE_PATH):
        try:
            with open(SECRET_FILE_PATH, "r", encoding="utf-8") as f:
                return f.read().strip()
        except Exception as e:
            print(f"⚠️ [market-sync] Vault Read Warning: Unable to parse password volume: {e}")
    return os.getenv("DB_PASSWORD", "postgres")

def execute_dual_query_sync_pass():
    """Executes a dual-query priority sweep to sync hot and stale market tickers securely."""
    try:
        db_pass = get_vault_password()
        conn = pg8000.dbapi.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=db_pass
        )
        cursor = conn.cursor()
        cache = valkey.Valkey(host=VALKEY_HOST, port=VALKEY_PORT, decode_responses=True)

        # 🪐 SWEEP 1: Extract the top 25 most recently utilized active symbols in the ledger
        cursor.execute("""
            SELECT i.id, i.ticker 
            FROM instrument i
            JOIN trade_execution te ON i.id = te.instrument_id
            GROUP BY i.id, i.ticker
            ORDER BY MAX(te.executed_at) DESC
            LIMIT 25;
        """)
        hot_symbols = cursor.fetchall()

        # 🪐 SWEEP 2: Extract the top 25 most starved/stale symbols from the catalog
        cursor.execute("""
            SELECT id, ticker 
            FROM instrument
            ORDER BY last_synced_at ASC
            LIMIT 25;
        """)
        stale_symbols = cursor.fetchall()

        # Deduplicate overlapping rows into a clean lookup container map
        target_universe = {}
        for row in hot_symbols + stale_symbols:
            inst_id, ticker = row
            # Filter out non-cloud cash assets from hitting external Fauxnance network gateways
            if ticker in ("CASHGBP", "CASHUSD"): 
                continue
            target_universe[inst_id] = ticker

        if not target_universe:
            cursor.close()
            conn.close()
            return

        ticker_list = list(target_universe.values())
        
        # Segment the unified target array into clean 25-item query chunks to protect Fauxnance quotas
        chunks = [ticker_list[i:i + 25] for i in range(0, len(ticker_list), 25)]

        for chunk in chunks:
            response = requests.post(
                FAUXNANCE_URL,
                headers={"X-API-Key": FAUXNANCE_KEY, "Content-Type": "application/json"},
                json={"symbols": chunk},
                timeout=10
            )
            
            if response.status_code == 200:
                market_data = response.json().get("quotes", [])
                
                cursor.execute("BEGIN;")
                for quote in market_data:
                    ticker = quote.get("symbol")
                    price = quote.get("price")
                    
                    cursor.execute("SELECT id FROM instrument WHERE ticker = %s", (ticker,))
                    inst_res = cursor.fetchone()
                    if not inst_res: 
                        continue
                    inst_id = inst_res[0]

                    # A. Hydrate local Valkey RAM storage (O(1) runtime caching)
                    cache.setex(f"market_price:{inst_id}", 90, str(price))

                    # B. Update relational database rows and reset the starvation clock
                    cursor.execute("""
                        UPDATE instrument 
                        SET current_price = %s, last_synced_at = CURRENT_TIMESTAMP 
                        WHERE id = %s
                    """, (price, inst_id))
                
                conn.commit()
                print(f"📡 [market-sync] Successfully synchronized batch of {len(market_data)} cloud ticker positions.")
            else:
                print(f"⚠️ [market-sync] Fauxnance API returned an error status code: {response.status_code}")
                
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"⚠️ [market-sync] Dual-query background synchronization run skipped. Details: {e}")
