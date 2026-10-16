#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - TIED CANOPY END-TO-END SMOKE TEST (DRIFT-PROOF EDITION)
# Target File: test/api/02-canopy-integration-test.py | Milestone 3 Integration
# BRS Mapping: BR-14 Context-Aware Host Resolution Matrix
# ============================================================================

import os
import sys
import socket
import time
import requests
import jwt

print("======================================================")
print("🚀 LAUNCHING TIED CANOPY END-TO-END SMOKE TEST")
print("======================================================")

def resolve_target_hosts():
    """🟢 Native Container Hostname Discovery.
    Inspects the machine's local system hostname string bytes. If it matches 
    our explicit container name tag or includes standard isolated container IDs, 
    it routes traffic over the mesh. On a developer workstation, it hooks loopbacks.
    """
    local_hostname = socket.gethostname()
    
    # Check if we are running inside the test-runner container workspace
    if "test-runner" in local_hostname or os.path.exists("/.dockerenv"):
        print("🪐 Context Discovery: Headless container network context verified.")
        return "api-gateway", "paysprint-auth"
    else:
        print("💻 Context Discovery: Live developer workstation host context verified.")
        return "localhost", "localhost"

# Execute dynamic path resolution
GATEWAY_HOST, AUTH_HOST = resolve_target_hosts()
GATEWAY_URL = f"http://{GATEWAY_HOST}:3000"
AUTH_DIRECT_URL = f"http://{AUTH_HOST}:4000"
DB_HOST = os.getenv("DB_HOST", "paysprint-postgres") # 🟢 FIXED: Define DB_HOST global baseline property

print(f"👉 Target Edge Canopy URL: {GATEWAY_URL}")
print(f"👉 Target Identity Provider URL: {AUTH_DIRECT_URL}")
print("------------------------------------------------------")

# Phase 1: Obtain a cryptographically secure session JWT directly from the identity warehouse
print("⏳ Phase 1: Requesting authentication token for user 'alice'...")
try:
    login_response = requests.post(
        f"{AUTH_DIRECT_URL}/login",
        json={"username": "alice", "password": "mission123"},
        timeout=5
    )
    if login_response.status_code != 200 or "token" not in login_response.json():
        print(f"❌ Phase 1 Failed: Status {login_response.status_code}. Response: {login_response.text}")
        sys.exit(1)
        
    alice_token = login_response.json()["token"]
    print("   ✅ Secure session token generated successfully.")
    print(f"   🔍 RAW ALICE JWT WIRE EMBED: {alice_token}\n", flush=True)
except Exception as e:
    print(f"❌ Phase 1 Connection Error: {e}")
    sys.exit(1)

# ============================================================================
# 🟢 TARGET CORRECTION HOOK: DYNAMIC CLAIM EXTRACTION
# ============================================================================
try:
    # Safely unpack the unverified token claims locally to intercept Alice's real runtime client ID
    unverified_claims = jwt.decode(alice_token, options={"verify_signature": False})
    dynamic_alice_client_id = int(unverified_claims.get("sub"))
    print(f"   👉 Discovery Success: Alice's true runtime primary key resolved to [{dynamic_alice_client_id}]")
except Exception as parse_err:
    print(f"❌ Telemetry Alert: Unable to parse identity claims off wire token: {parse_err}")
    sys.exit(1)

# Phase 2: Execute an authenticated order submit payload via the NestJS public port gateway
print("\n⏳ Phase 2: Dispatched multi-tenant trade order via NestJS Microgateway Perimeter (Port 3000)...")

# Seed Valkey directly within the testing canopy to satisfy read-through requirements
try:
    import pg8000.dbapi
    from contextlib import closing
    
    # 1. Mount database secret key to execute high-fidelity metadata discovery
    with open("/secrets/pg_master_pass.txt", "r", encoding="utf-8") as f:
        DB_PASSWORD = f.read().strip()
        
    # 2. Query the relational database to find the true, runtime primary key index of 'AAPL'
    with pg8000.dbapi.connect(host=DB_HOST, database="paysprint", user="postgres", password=DB_PASSWORD) as conn:
        with closing(conn.cursor()) as cursor:
            cursor.execute("SELECT id FROM instrument WHERE UPPER(ticker) = 'AAPL';")
            resolved_instrument_row = cursor.fetchone()
            if not resolved_instrument_row:
                print("❌ Pre-Warm Failure: Asset ticker 'AAPL' missing from reference schema catalog.")
                sys.exit(1)
            target_instrument_id = int(resolved_instrument_row[0])
            print(f"   👉 Discovery Success: Asset 'AAPL' located at database index [{target_instrument_id}]")
            
    # 3. Hydrate the volatile memory grid cache matching Java's exact key layout
    from finark_core.session_grid import SecurityGrid
    test_grid = SecurityGrid(valkey_host=os.getenv("VALKEY_HOST", "paysprint-cache"), valkey_port=6379, jwt_secret="")
    test_grid.cache.setex(f"market_price:{target_instrument_id}", 3600, "180.5000")
    print(f"   ⚡ [Harness Override] Volatile memory cache pre-warmed for Instrument ID {target_instrument_id} (AAPL) -> 180.5000")
except Exception as db_err:
    print(f"❌ Harness Pre-Warm Critical Failure: {db_err}")
    sys.exit(1)

headers = {
    "Authorization": f"Bearer {alice_token}",
    "Content-Type": "application/json"
}

# Payload features dynamically synchronized multi-tenant trade metrics for Alice
valid_trade_payload = {
    "clientId": dynamic_alice_client_id, # 🟢 FIXED: Binds the dynamic resolved runtime ID context
    "ticker": "AAPL",
    "side": "BUY",
    "quantity": 3.0000,
    "price": 180.5000
}

try:
    proxy_response = requests.post(
        f"{GATEWAY_URL}/order-placement/api/v1/submit",
        headers=headers,
        json=valid_trade_payload,
        timeout=5
    )
    
    if proxy_response.status_code == 200:
        print("   ✅ NestJS Edge Firewall: Signature verified & token session matched.")
        print(f"\n🎉 FULL PERIMETER CANOPY PASSED: {proxy_response.json()}")
    else:
        print("======================================================")
        print(f"❌ Phase 2 Gateway Proxy Failed: Status {proxy_response.status_code}.")
        print(f"👉 Raw Gateway Response Message: {proxy_response.text}")
        
        local_test_runner_time = int(time.time())
        print(f"👉 Current test-runner Container Clock: {local_test_runner_time}")
        
        try:
            claims = jwt.decode(alice_token, options={"verify_signature": False})
            print(f"👉 Token Payload signed by Python: {claims}")
            print(f"👉 Verification Delta (test-runner clock minus token iat): {local_test_runner_time - claims.get('iat', 0)}s")
        except Exception as json_err:
            print(f"❌ Telemetry Alert: Unable to parse token values locally: {json_err}")
        print("======================================================")
        sys.exit(1)
        
except Exception as e:
    print(f"❌ Phase 2 Proxy Connection Error: {e}")
    sys.exit(1)

print("\n⏳ Phase 3: Asserting Broken Access Control (OWASP A01) multi-tenant isolation defenses...")
attacker_payload = {
    "clientId": dynamic_alice_client_id + 1, # Spoof next increment index to trigger security failure
    "ticker": "AAPL",
    "side": "BUY",
    "quantity": 10.0000,
    "price": 180.5000
}

try:
    blocked_response = requests.post(
        f"{GATEWAY_URL}/order-placement/api/v1/submit",
        headers=headers,
        json=attacker_payload,
        timeout=5
    )
    
    if blocked_response.status_code == 400 and "Security Violation" in blocked_response.json().get("error", ""):
        print(f"   ✅ Java 25 Business Invariant: ContextUserId ({dynamic_alice_client_id}) != Payload ClientId ({dynamic_alice_client_id + 1}).")
        print("\n🏆 ALL PLATFORM CANOPY INTEGRITY CHECKS COMPLETED 100% SUCCESSFUL.")
    else:
        print(f"❌ Vulnerability Exposed! Gateway or business logic allowed parameter spoofing: Status {blocked_response.status_code}. Response: {blocked_response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ Phase 3 Connection Error: {e}")
    sys.exit(1)
