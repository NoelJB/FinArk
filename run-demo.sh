#!/usr/bin/env bash
# ============================================================================
# FINARK ORCHESTRATION PIPELINE COORDINATOR (THREE-TIER INFRASTRUCTURE SUITE)
# Target File: run-demo.sh | Usage: ./run-demo.sh [--tests | --demo | --serve]
# BRS Mapping: BR-14 Unified Sandbox Cluster Management
# ============================================================================

set -euo pipefail

# Parse command line argument with automated fallback to regression testing loop
MODE="${1:---tests}"

echo "======================================================"
echo "⚡ FINARK FABRIC INITIALIZATION ENGINE"
echo "======================================================"

# 1. EST_SAFE SECRETS STORE INTEGRITY VAULT
mkdir -p secrets

if [ ! -f secrets/pg_master_pass.txt ]; then
    openssl rand -base64 24 | tr -d '\n' > secrets/pg_master_pass.txt
fi

if [ ! -f secrets/jwt_shared_secret.txt ]; then
    openssl rand -base64 32 | tr -d '\n' > secrets/jwt_shared_secret.txt
fi

# Hard cleanup of stale tracking indices and lingering volumes
docker compose --profile db_tests down -v --remove-orphans > /dev/null 2>&1

# ----------------------------------------------------------------------------
# BRANCH 1: --demo (serving mode with pre-seeded demo accounts)
# ----------------------------------------------------------------------------
if [ "$MODE" = "--demo" ]; then
    echo "🌐 Mode: Persistent Serving Layer with Seeded Demo Accounts"
    echo "------------------------------------------------------"
    
    docker compose up --build -d paysprint-postgres paysprint-cache paysprint-auth orchestrator-sidecar order-placement-service api-gateway
    
    echo "⏳ Waiting for database container TCP port availability..."
    until docker compose exec paysprint-postgres pg_isready -U postgres -d paysprint > /dev/null 2>&1; do
        sleep 1
    done
    
    echo "🧪 Database engine stabilized. Injecting canonical security master instruments..."
    docker compose exec -T paysprint-postgres psql -U postgres -d paysprint -f - < db/fixtures/00-canonical-instruments.sql > /dev/null
    
    echo "🧪 Injecting client portfolio mock transactional data fixtures..."
    docker compose exec -T paysprint-postgres psql -U postgres -d paysprint -f - < db/fixtures/01-test-seed.sql > /dev/null
    
    echo "======================================================"
    echo "🎉 FINARK DEMO ENVIRONMENT UP AND RUNNING!"
    echo "👉 Edge Microgateway listening live on: http://localhost:3000"
    echo "📋 Check sidecar telemetry logs via: docker logs -f orchestrator-sidecar"
    echo "======================================================"

# ----------------------------------------------------------------------------
# BRANCH 2: --serve (clean-room bare virtual production topology)
# ----------------------------------------------------------------------------
elif [ "$MODE" = "--serve" ]; then
    echo "🌐 Mode: Clean-Room Faux Production Topology (No Seed Accounts)"
    echo "------------------------------------------------------"
    
    docker compose up --build -d paysprint-postgres paysprint-cache paysprint-auth orchestrator-sidecar order-placement-service api-gateway
    
    echo "⏳ Waiting for database container TCP port availability..."
    until docker compose exec paysprint-postgres pg_isready -U postgres -d paysprint > /dev/null 2>&1; do
        sleep 1
    done
    
    echo "🧪 Database engine stabilized. Injecting canonical reference instruments catalog..."
    docker compose exec -T paysprint-postgres psql -U postgres -d paysprint -f - < db/fixtures/00-canonical-instruments.sql > /dev/null
    
    echo "======================================================"
    echo "🎉 FINARK PRISTINE SERVING MESH UP AND RUNNING!"
    echo "👉 Edge Microgateway listening live on: http://localhost:3000"
    echo "💡 Populate account data dynamically via enrollment REST endpoints."
    echo "📋 Check sidecar telemetry logs via: docker logs -f orchestrator-sidecar"
    echo "======================================================"

# ----------------------------------------------------------------------------
# BRANCH 3: --tests (ephemeral automated regression loop pass)
# ----------------------------------------------------------------------------
else
    echo "🧪 Mode: Automated Regression Testing Loop (--tests)"
    echo "------------------------------------------------------"
    
    docker compose --profile db_tests up --build --abort-on-container-exit --attach test-runner
fi
