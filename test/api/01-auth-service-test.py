#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - TEST 15: AUTH SERVICE HTTP ENDPOINT & GRID INTEGRATION
# Target File: test/api/01-auth-service-test.py | BRS Mapping: BR-01 / BR-02 / BR-03
# ============================================================================

import os
import sys
import requests

# 🔌 Import our custom shared platform SDK library to execute direct state checks
from finark_core.session_grid import SecurityGrid

AUTH_URL = "http://paysprint-auth:4000"
VALKEY_HOST = os.getenv("VALKEY_HOST", "paysprint-cache")
VALKEY_PORT = int(os.getenv("VALKEY_PORT", 6379))

# ============================================================================
# 🔐 HARDENED: ZERO-TRUST SECRET INJECTION GATEWAY
# ============================================================================
SECRET_PATH = "/secrets/jwt_shared_secret.txt"

if not os.path.exists(SECRET_PATH):
    print(f"❌ CRITICAL CONFIGURATION MISMATCH: Secret file missing at target container volume mount path: {SECRET_PATH}")
    print("👉 Ensure that './secrets/jwt_shared_secret.txt' is properly generated on the host disk canopy.")
    sys.exit(1)

try:
    with open(SECRET_PATH, "r", encoding="utf-8") as f:
        JWT_SECRET = f.read().strip()
except Exception as e:
    print(f"❌ CRITICAL SYSTEM READ FAULT: Unable to parse secret file at {SECRET_PATH}. Details: {e}")
    sys.exit(1)

print("======================================================")
print("🌐 STARTING DUAL-PHASE REST API & MEMORY GRID VALIDATIONS")
print("======================================================")

# Initialize our test-tier connection handle straight to the shared memory fabric
try:
    test_grid = SecurityGrid(valkey_host=VALKEY_HOST, valkey_port=VALKEY_PORT, jwt_secret=JWT_SECRET)
except Exception as e:
    print(f"❌ Test Harness Core Failure: Unable to connect to Valkey grid: {e}")
    sys.exit(1)

# ============================================================================
# TEST BLOCK A: VALIDATE SUCCESSFUL SIGN-IN & CACHE INTERROGATION (BR-01)
# ============================================================================
print("⏳ Test A: Executing valid login attempt for user 'alice'...")
try:
    response = requests.post(
        f"{AUTH_URL}/login",
        json={"username": "alice", "password": "mission123"},
        timeout=5
    )
    if response.status_code == 200 and "token" in response.json():
        print("✅ Test A1 Passed: HTTP Gateway successfully returned token signature.")
        alice_token = response.json().get("token")
        
        # 🧪 CRITICAL WHITE-BOX SECURITY AUDIT: Direct Memory Grid Check
        # Prove the login route actively utilized the shared core library to write to Valkey
        session_envelope = test_grid.is_valid(raw_token=alice_token)
        if session_envelope and session_envelope.get("roles") == ["MISSION_OPERATOR"]:
            print(f"✅ Test A2 Passed: Shared Library confirms session data landed in Valkey grid securely.")
        else:
            print("❌ Test A2 Failed: Token is cryptographically sound, but MISSING from Valkey grid keyspace!")
            sys.exit(1)
    else:
        print(f"❌ Test A1 Failed: Status {response.status_code}. Response: {response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ Test A Connection Error: {e}")
    sys.exit(1)

# ============================================================================
# TEST BLOCK B: VALIDATE LIVE USER ENROLLMENT REGISTRATION (BR-02)
# ============================================================================
print("⏳ Test B: Enrolling brand-new user identity account 'noel'...")
try:
    response = requests.post(
        f"{AUTH_URL}/register",
        json={"username": "noel", "password": "securepassword2026", "client_id": 3},
        timeout=5
    )
    if response.status_code == 201:
        print("✅ Test B Passed: User successfully enrolled into relational database via REST API.")
    else:
        print(f"❌ Test B Failed: Status {response.status_code}. Response: {response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ Test B Connection Error: {e}")
    sys.exit(1)

# ============================================================================
# TEST BLOCK C: VALIDATE NEWLY ENROLLED SIGN-IN DATA LOOP (BR-01)
# ============================================================================
print("⏳ Test C: Verifying sign-in capacity for newly enrolled user 'noel'...")
try:
    response = requests.post(
        f"{AUTH_URL}/login",
        json={"username": "noel", "password": "securepassword2026"},
        timeout=5
    )
    if response.status_code == 200 and "token" in response.json():
        print("✅ Test C1 Passed: Enrolled user token generated successfully.")
        noel_token = response.json().get("token")
        
        # 🧪 Direct Memory Grid Verification for dynamically registered user
        noel_envelope = test_grid.is_valid(raw_token=noel_token)
        if noel_envelope and noel_envelope.get("sub_id") == 3:
            print("✅ Test C2 Passed: Shared Library confirms new user session payload is active in Valkey.")
        else:
            print("❌ Test C2 Failed: New user session envelope failed grid tracking verification.")
            sys.exit(1)
    else:
        print(f"❌ Test C1 Failed: Status {response.status_code}. Response: {response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ Test C Connection Error: {e}")
    sys.exit(1)

# ============================================================================
# TEST BLOCK D: VALIDATE LIVE SESSION REVOCATION VIA EVICTION (BR-03)
# ============================================================================
print("⏳ Test D: Executing user logout and validating Valkey token eviction...")
try:
    # 1. Establish fresh session headers for Alice
    headers = {"Authorization": f"Bearer {alice_token}"}

    # 2. Fire the logout endpoint to clear the tracking identifier from memory
    logout_response = requests.post(f"{AUTH_URL}/logout", headers=headers, timeout=5)
    if logout_response.status_code != 200:
        print(f"❌ Test D Failed: Logout endpoint rejected token. Status: {logout_response.status_code}")
        sys.exit(1)

    # 3. Direct Infrastructure Post-Logout Check
    # Verify that the session identifier was completely evicted from memory grid channels
    post_logout_envelope = test_grid.is_valid(raw_token=alice_token)
    if post_logout_envelope is None:
        print("✅ Test D1 Passed: Shared Library confirms session data permanently dropped from Valkey.")
    else:
        print("❌ Test D1 Failed: Token eviction leaked! Session payload still persists inside the memory grid.")
        sys.exit(1)

    # 4. HTTP Gateway Post-Logout Check
    # Ensure the /verify gatekeeper accurately defaults to fail-secure mode
    verify_response = requests.get(f"{AUTH_URL}/verify", headers=headers, timeout=5)
    if verify_response.status_code == 401:
        print("✅ Test D2 Passed: HTTP Gatekeeper boundary successfully blocks revoked token access.")
    else:
        print(f"❌ Test D2 Failed: HTTP /verify path accepted an evicted token session! Status: {verify_response.status_code}")
        sys.exit(1)

except Exception as e:
    print(f"❌ Test D Exception Encountered: {e}")
    sys.exit(1)

print("\n🎉 ALL AUTH DECENTRALIZED MEMORY GRID HANDSHAKES VERIFIED GREEN")
print("======================================================")
