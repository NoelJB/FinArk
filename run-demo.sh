#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM: SYSTEM LIFECYCLE & STACK ORCHESTRATOR
# Target File: run-demo.sh | Requirements: chmod u+x
# ============================================================================

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

echo "======================================================"
echo "🛡️  FINARK PLATFORM: RUNNING VAULT SECURITY INITIALIZATION"
echo "======================================================"

# 1. Turnkey Bootstrap: Dynamically instantiate host storage vault if missing
if [ ! -d "${ROOT_DIR}/secrets" ]; then
    echo "📁 Creating local ignored secrets vault container..."
    mkdir -p "${ROOT_DIR}/secrets"
fi

# 2. Key Generation: Create random cryptotoken sequence if missing
if [ ! -f "${ROOT_DIR}/secrets/pg_master_pass.txt" ]; then
    echo "🔑 Generating secure random instance keys..."
    openssl rand -base64 16 | tr -d '\n' > "${ROOT_DIR}/secrets/pg_master_pass.txt"
    chmod 600 "${ROOT_DIR}/secrets/pg_master_pass.txt"
    echo "✅ Encryption keys locked in vault storage."
else
    echo "ℹ️  Existing vault key tokens detected. Preserving credentials."
fi

echo "======================================================"
echo "🚀 FINARK PLATFORM: BOOTING DOCKER INFRASTRUCTURE STACK"
echo "======================================================"

# 3. Execution: Down current states and boot the stack layers safely
docker compose down -v
docker compose up -d

echo "======================================================"
echo "✅ INFRASTRUCTURE SUCCESS: INFRASTRUCTURE STACK INITIALIZED GREEN"
echo "👉 Execute validation tests via: ./test/run-test-container.sh"
echo "======================================================"

./test/run-test-container.sh
