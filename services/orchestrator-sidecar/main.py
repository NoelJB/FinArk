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

    # ⏱️ TASK 1: Re-aligned 1-Minute Dual-Query Cloud Quota Protection Loop
    # Runs instantly on boot, and repeats indefinitely every 60 seconds
    cron_pool.add_delayed(
        delay=15, 
        callback=execute_dual_query_sync_pass, 
        repeat=Repeat(delay=60, count=-1), # -1 maps to infinite looping execution
        task_name="market_reference_sync"
    )

    # ⏱️ TASK 2: Asynchronous Transactional Outbox Event Stream Poller
    # 🟢 FIXED: Registered as a single-shot initialization trigger pass (repeat=None)
    # We pass a reschedule function to the service, enabling it to let us know when it is done

    def _resched():
        cron_pool.add_delayed(
            5, # Positional delay
            execute_outbox_stream_relay, # Positional callback entrypoint
            _resched, # Positional vararg packed cleanly into *args tuple mapping
            task_name="transactional_outbox_poller" # Keyword argument target
        )

    # Boot the very first initialization pass 5 seconds after script startup
    cron_pool.add_delayed(
        60, 
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
