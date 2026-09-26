#!/usr/bin/env bash
# ============================================================================
# FINARK ORCHESTRATION PIPELINE COORDINDATOR
# Target File: run-demo.sh | Usage: ./run-demo.sh [--serve]
# ============================================================================

set -euo pipefail

# 1. READ CONFIGURATION PARAMETERS
MODE="${1:-test}"

echo "======================================================"
echo "⚡ FINARK FABRIC INITIALIZATION ENGINE"
echo "======================================================"

# ============================================================================
# 🔐 RESTORED: HIGH-FIDELITY VAULT SECRET GENERATION
# ============================================================================
mkdir -p secrets

# Generate a strong, unique administrative credential file if missing
if [ ! -f secrets/pg_master_pass.txt ]; then
    openssl rand -base64 24 | tr -d '\n' > secrets/pg_master_pass.txt
fi

# Generate an ephemeral, structurally secure JWT signing token matrix if missing
if [ ! -f secrets/jwt_shared_secret.txt ]; then
    openssl rand -base64 32 | tr -d '\n' > secrets/jwt_shared_secret.txt
fi

# Hard cleanup of stale layers and dead network components
docker compose --profile db_tests down -v --remove-orphans > /dev/null 2>&1

if [ "$MODE" = "--serve" ]; then
    echo "🌐 Mode: Persistent Serving (Detached Container Mesh)"
    echo "------------------------------------------------------"
    
    # Fire up core dependencies in the background
    docker compose up -d paysprint-postgres paysprint-cache paysprint-auth
    
    echo "⏳ Waiting for database container TCP port availability..."
    until docker compose exec paysprint-postgres pg_isready -U postgres -d paysprint > /dev/null 2>&1; do
        sleep 1
    done
    
    echo "🧪 Database engine stabilized. Injecting testing data fixtures..."
    docker compose exec -T paysprint-postgres psql -U postgres -d paysprint -f - < db/fixtures/00-test-seed.sql > /dev/null
    
    echo "======================================================"
    echo "🎉 FINARK RUNTIME MESH UP AND RUNNING!"
    echo "👉 Auth API endpoint listening live on: http://localhost:4000"
    echo "💡 Run your curl tests now. Terminate stack using: docker compose down -v"
    echo "======================================================"

else
    echo "🧪 Mode: Automated Regression Testing Loop"
    echo "------------------------------------------------------"
    
    # Run the standard integration harness with automated exit triggers
    docker compose --profile db_tests up --build --abort-on-container-exit --attach test-runner
fi
