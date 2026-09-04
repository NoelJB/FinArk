#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM: ISOLATED CONTAINER INTEGRATION TEST RUNNER
# Target File: test/run-test-container.sh | Requirements: chmod u+x
# ============================================================================

set -euo pipefail

# Establish location-independent file pathing based on this file's position
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================"
echo "🐳 SPINNING UP ISOLATED FINARK TEST CONTAINER"
echo "======================================================"

# Run an ephemeral alpine instance sharing the host network topology
# Mounts the test folder directly into the container context
docker run --rm \
  --network="host" \
  -v "${TEST_DIR}:/test" \
  alpine:3.19 sh -c "
    echo '⏳ Provisioning container with bash and postgresql-client...' && \
    apk add --no-cache bash postgresql-client > /dev/null && \
    echo '⏳ Transferring execution routing to regression suite...' && \
    /test/run-tests.sh
  "

echo "======================================================"
echo "🐳 CONTAINER SUITE EXECUTION COMPLETE"
echo "======================================================"
