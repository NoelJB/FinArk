#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM - CHASSIS JAVA SDK LOCAL VALIDATION HARNESS
# Target File: packages/finark-core-java/harness-run.sh
# ============================================================================

#!/usr/bin/env bash
set -euo pipefail

WRITABLE_WORKSPACE="/tmp/finark-core-java-scratch"

echo "⏳ [finark-core-java] Initializing transient writable JVM scratch space..."
rm -rf "$WRITABLE_WORKSPACE"
mkdir -p "$WRITABLE_WORKSPACE"

cp -R /packages/finark-core-java/. "$WRITABLE_WORKSPACE/"
cd "$WRITABLE_WORKSPACE"

echo "⏳ [finark-core-java] Launching BuildKit Maven unit test matrices..."
mvn test -B -Dmaven.repo.local=/root/.m2

rm -rf "$WRITABLE_WORKSPACE"
echo "✅ [finark-core-java] All core shared JVM assertions passed successfully!"
