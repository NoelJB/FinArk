#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM - MULTI-PROFILE INTEGRATION CONTROLLER (BUILD-AWARE)
# Target File: ./run-manual-tests.sh
# ============================================================================
set -eo pipefail

PROFILE_TARGET=${1:-"--api-only"}

if [ "$PROFILE_TARGET" == "--db-only" ]; then
    echo "⚙️  Verifying database harness image compilation layers..."
    docker compose build db-test-runner
    
    echo "⚠️  Booting State-Destructive Cold Database Unit Suite..."
    docker compose --profile db_tests run --rm --no-deps db-test-runner
    
elif [ "$PROFILE_TARGET" == "--api-only" ]; then
    echo "⚙️  Verifying API validation harness image compilation layers..."
    # 🟢 FIXED: Forces an incremental build check to bake fresh Dockerfile wheels instantly
    docker compose build api-test-runner
    
    echo "🌐 Booting Stateful Hot Microservice API Canopy Suite..."
    docker compose --profile api_tests run --rm --no-deps api-test-runner
    
else
    echo "❌ Unknown testing execution boundary profile: $PROFILE_TARGET"
    echo "👉 Usage Options: ./run-manual-tests.sh [--api-only | --db-only]"
    exit 1
fi
