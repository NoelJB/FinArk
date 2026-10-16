#!/usr/bin/env bash
# ============================================================================
# FINARK HARNESS - STATE-DESTRUCTIVE COLD DATABASE UNIT ASSERTIONS ENGINE
# Target File: test/run-db-tests.sh
# ============================================================================
set -eo pipefail

echo "======================================================"
echo "🚀 FINARK AUTOMATED REGRESSION & COLD DATABASE SUITE"
echo "======================================================"

# Step 1: Programmatically confirm relational data warehouse port availability
echo "⏳ Phase 1: Polling database container TCP port availability..."
until nc -z -v -w5 "${DB_HOST:-paysprint-postgres}" 5432; do
    echo "  👉 Waiting for relational storage engine socket connection... Retry in 1s"
    sleep 1
done

# Step 2: Confirm structural catalog DDL completion
echo "⏳ Phase 2: Confirming relational catalog structural completion..."
until psql -h "${DB_HOST:-paysprint-postgres}" -U postgres -d paysprint -c "SELECT 1 FROM instrument LIMIT 1;" > /dev/null 2>&1; do
    echo "  👉 Waiting for baseline schema migrations to compile... Retry in 1s"
    sleep 1
done

# Step 3: Run static constraint validations and alphanumeric assertion scans
echo "🔮 PHASE 1: RUNNING RELATIONAL DATA MODEL VALIDATIONS..."
for assert_script in $(ls /test/database/??-*-test.sql | sort); do
    echo "⏳ Executing dynamic database assertion module: $(basename "$assert_script")..."
    
    # Pipes the static test file straight into the PostgreSQL interactive terminal handler
    # Captures explicit notices and aborts immediately if a threshold checks drops
    PGPASSWORD="${DB_PASSWORD:-postgres}" psql -h "${DB_HOST:-paysprint-postgres}" -U postgres -d paysprint -f "$assert_script" || exit 1
done

echo "🎉 ALL STATIC RELATION CONSTRAINT SCHEMAS VERIFIED GREEN"
