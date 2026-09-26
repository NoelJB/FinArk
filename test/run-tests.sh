#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM - MASTER AUTOMATED REGRESSION HARNESS
# Target File: test/run-tests.sh | BRS Mapping: BR-14 Universal Automation
# ============================================================================

set -euo pipefail

# Calculate the base execution path dynamically
BASE_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
DB_TEST_DIR="${BASE_TEST_DIR}/db"
API_TEST_DIR="${BASE_TEST_DIR}/api"

echo "======================================================"
echo "🚀 FINARK AUTOMATED REGRESSION HARNESS"
echo "======================================================"

# ----------------------------------------------------------------------------
# PHASE 1: AUTOMATED DATABASE TIER TESTS (SQL MODULES)
# ----------------------------------------------------------------------------
echo "🔮 PHASE 1: RUNNING RELATIONAL DATA MODEL VALIDATIONS..."

DB_TEST_FILES=$(find "$DB_TEST_DIR" -maxdepth 1 -type f -name "[0-9][0-9]-*.sql" | sort)

for test_file in $DB_TEST_FILES; do
    file_name=$(basename "$test_file")
    echo "⏳ Executing dynamic test module: ${file_name}..."
    
    BUFFER_FILE=$(mktemp)
    
    # Run quietly but preserve output fields for evaluation
    psql -h "$DB_HOST" -U postgres -d paysprint -A -t -F ',' -f "$test_file" > "$BUFFER_FILE" 2>&1

    # 🔐 Fix: Enforce actual vs expected validation checks
    if grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | grep . > /dev/null; then
        echo "❌ CRITICAL AUTOMATED REGRESSION MISMATCH DETECTED!"
        grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | sed 's/^/  👉 /'
        rm -f "$BUFFER_FILE"
        exit 1
    fi
    rm -f "$BUFFER_FILE"
done

# ----------------------------------------------------------------------------
# PHASE 2: AUTOMATED MICROSERVICE API TESTS (PYTHON MODULES)
# ----------------------------------------------------------------------------
echo ""
echo "🔮 PHASE 2: RUNNING CONTAINER NETWORK API VALIDATIONS..."

# Provision the environment with required network testing utilities dynamically
echo "⏳ Initializing runtime testing dependencies (python3-requests)..."
apk add --no-cache python3 py3-requests > /dev/null 2>&1

API_TEST_FILES=$(find "$API_TEST_DIR" -maxdepth 1 -type f -name "[0-9][0-9]-*.py" | sort)

for test_file in $API_TEST_FILES; do
    file_name=$(basename "$test_file")
    echo "⏳ Executing dynamic API test module: ${file_name}..."
    
    # Execute the python requests automation module natively
    python3 "$test_file"
done

echo "======================================================"
echo "🎉 SUCCESS: ALL DYNAMIC PLATFORM SYSTEM ASSERTIONS ARE GREEN"
echo "======================================================"
