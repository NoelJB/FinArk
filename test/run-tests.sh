#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM: CONTAINER REGRESSION HARNESS ENGINE LOOP
# Target File: test/run-tests.sh | Requirements: chmod u+x
# ============================================================================

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

echo "======================================================"
echo "🚀 FINARK AUTOMATED REGRESSION HARNESS"
echo "======================================================"

# Automatically scan and sort all NN-*.sql files in numerical order
TEST_FILES=$(find "$TEST_DIR" -maxdepth 1 -type f -name "[0-9][0-9]-*.sql" | sort)

for test_file in $TEST_FILES; do
    file_name=$(basename "$test_file")
    echo "⏳ Executing dynamic test module: ${file_name}..."
    
    BUFFER_FILE=$(mktemp)
    
    # Run the test file using the inherited PGPASSWORD environment context variable
    psql -h localhost -U postgres -d paysprint -A -t -F ',' -f "$test_file" > "$BUFFER_FILE" 2>&1
    
    # The Global Assertion Engine: Scan output matrix lines for failed validations
    if grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | grep . > /dev/null; then
        echo "❌ CRITICAL AUTOMATED REGRESSION MISMATCH DETECTED!"
        grep -E "ASSERT" "$BUFFER_FILE" | awk -F ',' '$3 != $4' | sed 's/^/  👉 /'
        rm -f "$BUFFER_FILE"
        exit 1
    fi

    rm -f "$BUFFER_FILE"
    echo "✅ Module ${file_name} successfully passed verification checks."
done

echo "======================================================"
echo "🎉 SUCCESS: ALL DYNAMIC PLATFORM SYSTEM ASSERTIONS ARE GREEN"
echo "======================================================"
exit 0
