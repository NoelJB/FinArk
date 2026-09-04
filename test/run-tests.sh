#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM: ULTRA-SIMPLIFIED POLYMORPHIC TEST ENGINE
# Target File: test/run-tests.sh | Requirements: chmod u+x
# ============================================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
export PGPASSWORD="n3u3d4!"

echo "======================================================"
echo "🚀 FINARK AUTOMATED REGRESSION HARNESS"
echo "======================================================"

# Automatically scan and sort all NN-*.sql files
TEST_FILES=$(find "$TEST_DIR" -maxdepth 1 -type f -name "[0-9][0-9]-*.sql" | sort)

for test_file in $TEST_FILES; do
    file_name=$(basename "$test_file")
    echo "⏳ Executing: ${file_name}..."
    
    BUFFER_FILE=$(mktemp)
    
    # Run the test, combining standard output and notice blocks
    psql -h localhost -U postgres -d paysprint -A -t -F ',' -f "$test_file" > "$BUFFER_FILE" 2>&1
    
    # The Global Assertion Engine: Scan output for any failed assertions
    # Checks if any line containing 'ASSERT' has mismatched columns 3 and 4
    if grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | grep . > /dev/null; then
        echo "❌ CRITICAL ARITHMETIC MISMATCH DETECTED!"
        grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | sed 's/^/  👉 /'
        rm -f "$BUFFER_FILE"
        exit 1
    fi

    rm -f "$BUFFER_FILE"
    echo "✅ Module ${file_name} passed."
done

echo "======================================================"
echo "🎉 SUCCESS: ALL DYNAMIC SYSTEM ASSERTIONS ARE GREEN"
echo "======================================================"
exit 0
