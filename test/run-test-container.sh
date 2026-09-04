#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM: HOST WRAPPER CONTAINER INITIALIZATION RUNNER
# Target File: test/run-test-container.sh | Requirements: chmod u+x
# ============================================================================

set -euo pipefail

# Establish location-independent file pathing based on this file's position on the host
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
ROOT_DIR="$(cd "${TEST_DIR}/.." && pwd)"

# Securely extract the active token from the host secrets store mapping vault
export HOST_PGPASSWORD=$(cat "${ROOT_DIR}/secrets/pg_master_pass.txt")

echo "======================================================"
echo "🐳 SPINNING UP ISOLATED FINARK TEST CONTAINER"
echo "======================================================"

# Run an ephemeral alpine instance sharing the host network topology
# Pass the secret token value cleanly into the container's environment context
docker run --rm \
  --network="host" \
  -e PGPASSWORD="${HOST_PGPASSWORD}" \
  -v "${TEST_DIR}:/test" \
  alpine:3.19 sh -c "
    apk add --no-cache bash postgresql-client > /dev/null && \
    /test/run-tests.sh
  "
