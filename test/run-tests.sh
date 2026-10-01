#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM - MASTER AUTOMATED HYBRID DISCOVERY HARNESS
# Target File: test/run-tests.sh | BRS Mapping: BR-14 Universal Automation
# ============================================================================

set -euo pipefail

# Calculate the base execution paths dynamically
export BASE_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
export REPO_ROOT="$(cd "${BASE_TEST_DIR}/.." && pwd)"
DB_TEST_DIR="${BASE_TEST_DIR}/db"
API_TEST_DIR="${BASE_TEST_DIR}/api"

# 🔐 Establish native database tier connectivity variables using secrets vault mounts
export PGPASSWORD=$(cat /secrets/pg_master_pass.txt)

echo "======================================================"
echo "🚀 FINARK AUTOMATED REGRESSION & DISCOVERY HARNESS"
echo "======================================================"

# 🚦 1. NATIVE CORE DATA TIER STABILIZATION GATES
echo "⏳ Phase 1: Polling database container TCP port availability..."
until pg_isready -h "$DB_HOST" -U postgres -d paysprint > /dev/null 2>&1; do
  sleep 1
done

echo "⏳ Phase 2: Confirming relational catalog structural completion..."
until psql -h "$DB_HOST" -U postgres -d paysprint -t -c "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'advisor');" | grep -q t; do
  sleep 1
done

echo "🧪 Data tier stabilized. Injecting testing fixture dataset..."
psql -h "$DB_HOST" -U postgres -d paysprint -f /fixtures/00-test-seed.sql > /dev/null

# ----------------------------------------------------------------------------
# 🐘 PHASE 1: AUTOMATED DATABASE TIER TESTS (SQL ASSERTION PLUGINS)
# ----------------------------------------------------------------------------
echo ""
echo "🔮 PHASE 1: RUNNING RELATIONAL DATA MODEL VALIDATIONS..."

DB_TEST_FILES=$(find "$DB_TEST_DIR" -maxdepth 1 -type f -name "[0-9][0-9]-*.sql" | sort)

for test_file in $DB_TEST_FILES; do
    file_name=$(basename "$test_file")
    echo "⏳ Executing dynamic database assertion module: ${file_name}..."
    
    BUFFER_FILE=$(mktemp)
    psql -h "$DB_HOST" -U postgres -d paysprint -A -t -F ',' -f "$test_file" > "$BUFFER_FILE" 2>&1 || true

    if grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | grep . > /dev/null; then
        echo "❌ CRITICAL AUTOMATED REGRESSION MISMATCH DETECTED!"
        grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | sed 's/^/  👉 /'
        rm -f "$BUFFER_FILE"
        exit 1
    fi
    rm -f "$BUFFER_FILE"
done
echo "✅ Phase 1 Relational Data Model Assertions passed cleanly."

# ----------------------------------------------------------------------------
# 🐍 PHASE 2: AUTOMATED IDENTITY PLATFORM TESTS (PYTHON CORE INTERFACES)
# ----------------------------------------------------------------------------
echo ""
echo "🔮 PHASE 2: RUNNING IDENTITY PROVIDER CONNECTOR VALIDATIONS..."

echo "⏳ Syncing internal core library source code into local scratch space..."
mkdir -p /tmp/finark-core
cp -R /packages/finark-core/. /tmp/finark-core/

pip install --no-cache-dir --break-system-packages /tmp/finark-core > /dev/null

API_TEST_FILES=$(find "$API_TEST_DIR" -maxdepth 1 -type f -name "[0-9][0-9]-*.py" | sort)

for test_file in $API_TEST_FILES; do
    file_name=$(basename "$test_file")
    echo "⏳ Executing dynamic API test module: ${file_name}..."
    python3 "$test_file"
done
echo "✅ Phase 2 Identity Provider Network Assertions passed cleanly."

# ----------------------------------------------------------------------------
# 🔍 PHASE 3: PLUG-AND-PLAY DYNAMIC TEST SUITE DISCOVERY HARNESS
# ----------------------------------------------------------------------------
echo ""
echo "🔮 PHASE 3: SCANNING PROJECT MICROSERVICES VIA PLUG-AND-PLAY LOOKUPS..."

PASSED_PLUGINS=()
FAILED_PLUGINS=()

# Replace Phase 3 suite discovery harness loop with this context-aware execution block:
while IFS= read -r script_path; do
    CONTEXT_NAME=$(basename "$(dirname "$script_path")")
    echo "------------------------------------------------------"
    echo "🏃 Invoking Discovered Harness Loop: [${CONTEXT_NAME}]"
    echo "👉 Path mapping: ${script_path}"
    
    # Step into the specific microservice subfolder before executing its local script
    pushd "$(dirname "$script_path")" > /dev/null
    if /bin/bash "harness-run.sh"; then
        PASSED_PLUGINS+=("$CONTEXT_NAME")
    else
        FAILED_PLUGINS+=("$CONTEXT_NAME")
    fi
    popd > /dev/null
done < <(find "$REPO_ROOT" -type f -name "harness-run.sh" | sort)

# ----------------------------------------------------------------------------
# 📊 PHASE 4: RECONCILIATION SUMMARY REPORT LOG
# ----------------------------------------------------------------------------
echo ""
echo "======================================================"
echo "📊 FINARK REGRESSION STATE EXECUTION SUMMARY"
echo "======================================================"

if [ ${#PASSED_PLUGINS[@]} -gt 0 ]; then
    echo "✅ Successful Discovered Plugins:"
    for service in "${PASSED_PLUGINS[@]}"; do 
        echo "   • $service"
    done
fi

if [ ${#FAILED_PLUGINS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Defective/Broken Discovered Plugins:"
    for service in "${FAILED_PLUGINS[@]}"; do 
        echo "   • $service"
    done
    echo "======================================================"
    exit 1
fi

echo "======================================================"
echo "🎉 SUCCESS: ALL REPOSITORY CONTEXT SUITES ARE 100% GREEN"
echo "======================================================"
