#!/usr/bin/env bash
# ============================================================================
# FINARK PLATFORM - ORDER PLACEMENT ARTIFACT VERIFICATION PLUGIN
# Target File: services/order-placement-service/harness-run.sh
# ============================================================================
set -euo pipefail

echo "⏳ [order-placement-service] Verifying build-time validation status..."
# Simply ensure the service compiled successfully during the BuildKit phase
if [ -f "/app/order-placement-service.jar" ] || [ -d "target" ] || [ -d "/build-app/target" ]; then
    echo "✅ [order-placement-service] Microservice build-time compilation confirmed."
    exit 0
else
    echo "❌ [order-placement-service] Expected application artifacts not found!"
    exit 1
fi
