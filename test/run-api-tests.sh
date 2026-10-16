#!/usr/bin/env bash
# ============================================================================
# FINARK HARNESS - STATEFUL Rest API HANDSHAKE DISCOVERY LAYER
# Target File: test/run-api-tests.sh
# ============================================================================
set -eo pipefail

echo "======================================================"
echo "🔮 FINARK STATEFUL API INTEGRATION DISCOVERY HARNESS"
echo "======================================================"

# Automatically detect, sort, and sequentially run live python integrations
for test_script in $(ls /test/api/??-*-test.py | sort); do
    echo "⏳ Executing dynamic API test module: $(basename "$test_script")..."
    python3 "$test_script"
done

echo "🎉 ALL STATEFUL NETWORK INVARIANTS VERIFIED GREEN"
