#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - MASTER BACKGROUND CRON-SIDECAR ORCHESTRATOR
# Target File: services/orchestrator-sidecar/main.py
# ============================================================================

import os
import sys
import time

# Import your custom high-performance priority-queue scheduler
from TimerManager import TimerManager, Repeat

# 🔌 Import individual decoupled microservice tasks as isolated modules
# This guarantees clear separation of concerns at the source code layer
from tasks.market_sync import execute_dual_query_sync_pass
from tasks.outbox_poller import execute_outbox_stream_relay

def bootstrap_cron_sidecar():
    print("======================================================")
    print("🚀 FINARK CONSOLIDATED AUTOMATION SIDECAR INITIALIZED")
    print("======================================================")

    # Initialize the synchronized heap scheduler thread
    cron_pool = TimerManager()
    cron_pool.start()

    # ⏱️ TASK 1: Balanced 15-Second Startup Buffer
    # Ensures the Valkey grid (paysprint-cache) completes its internal initialization checks before injection passes fire
    cron_pool.add_delayed(
        delay=15, 
        callback=execute_dual_query_sync_pass, 
        repeat=Repeat(delay=60, count=-1), 
        task_name="market_reference_sync"
    )

    def _resched():
        cron_pool.add_delayed(
            5, 
            execute_outbox_stream_relay, 
            _resched, 
            task_name="transactional_outbox_poller" 
        )

    # Boot the very first initialization pass 15 seconds after script startup to trail Task 1 cleanly
    cron_pool.add_delayed(
        15, 
        execute_outbox_stream_relay, 
        _resched, 
        task_name="transactional_outbox_poller"
    )
    cron_pool.show_tasks()

    try:
        # Keep master thread alive while background workers process task items
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("⏳ Administrative shutdown request received. Purging heap pools...")
        cron_pool.stop()
        cron_pool.join()


if __name__ == "__main__":
    bootstrap_cron_sidecar()
