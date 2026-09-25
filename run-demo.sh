#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM: COMPOSER PROFILE LIFECYCLE MANAGEMENT
# Target File: run-demo.sh | Requirements: chmod u+x
# ============================================================================

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

echo "======================================================"
echo "🛡️  FINARK PLATFORM: RUNNING VAULT SECURITY INITIALIZATION"
echo "======================================================"

if [ ! -d "${ROOT_DIR}/secrets" ]; then
    echo "📁 Creating local ignored secrets vault container..."
    mkdir -p "${ROOT_DIR}/secrets"
fi

# 1. Relational Database Encryption Key Guard
if [ ! -f "${ROOT_DIR}/secrets/pg_master_pass.txt" ]; then
    echo "🔑 Generating secure random instance keys for PostgreSQL..."
    openssl rand -base64 16 | tr -d '\n' > "${ROOT_DIR}/secrets/pg_master_pass.txt"
    chmod 600 "${ROOT_DIR}/secrets/pg_master_pass.txt"
    echo "✅ Encryption keys locked in vault storage."
fi

# 2. Shared JWT Cryptographic Signature Key Guard (BR-14 Automated)
if [ ! -f "${ROOT_DIR}/secrets/jwt_shared_secret.txt" ]; then
    echo "🔐 Generating 32-byte shared cryptographic key for microservice JWT signatures..."
    openssl rand -base64 32 | tr -d '\n' > "${ROOT_DIR}/secrets/jwt_shared_secret.txt"
    chmod 600 "${ROOT_DIR}/secrets/jwt_shared_secret.txt"
    echo "✅ Shared signature secret locked in vault storage."
fi

echo "======================================================"
echo "🚀 FINARK PLATFORM: EXECUTING TARGET PROFILES PIPELINE"
echo "======================================================"

# Clean out old data volume caches to guarantee a pristine test baseline state
docker compose --profile db_tests down -v

# Boot infrastructure, wait for health check success gates, and attach output streaming
docker compose --profile db_tests up --build --abort-on-container-exit --attach test-runner
