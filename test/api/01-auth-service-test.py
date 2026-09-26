#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - TEST 15: AUTH SERVICE HTTP ENDPOINT INTEGRATION TESTS
# Target File: test/api/01_auth_service_test.py | BRS Mapping: BR-01 / BR-02
# ============================================================================

import sys
import requests

AUTH_URL = "http://paysprint-auth:4000"

print("------------------------------------------------------")
print(f"🌐 TARGETING AUTH API SUITE: {AUTH_URL}")
print("------------------------------------------------------")

# ============================================================================
# TEST BLOCK A: VALIDATE SUCCESSFUL SIGN-IN (BR-01)
# ============================================================================
# Change this block inside test/api/01-auth-service-test.py:
print("⏳ Test A: Executing valid login attempt for user 'alice'...")
try:
    response = requests.post(
        f"{AUTH_URL}/login",
        json={"username": "alice", "password": "mission123"}, # 🔐 Matches Test 14's data state
        timeout=5
    )
    if response.status_code == 200 and "token" in response.json():
        print("✅ Test A Passed: Token generated successfully.")
    else:
        print(f"❌ Test A Failed: Status {response.status_code}. Response: {response.text}")
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
        print("✅ Test B Passed: User successfully enrolled into relational data table.")
    else:
        print(f"❌ Test B Failed: Status {response.status_code}. Response: {response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ Test B Connection Error: {e}")
    sys.exit(1)

# ============================================================================
# TEST BLOCK C: VALIDATE NEWLY ENROLLED SIGN-IN DATA LOOP
# ============================================================================
print("⏳ Test C: Verifying sign-in capacity for newly enrolled user 'noel'...")
try:
    response = requests.post(
        f"{AUTH_URL}/login",
        json={"username": "noel", "password": "securepassword2026"},
        timeout=5
    )
    if response.status_code == 200 and "token" in response.json():
        print("✅ Test C Passed: Enrolled user token generated successfully.")
    else:
        print(f"❌ Test C Failed: Status {response.status_code}. Response: {response.text}")
        sys.exit(1)
except Exception as e:
    print(f"❌ Test C Connection Error: {e}")
    sys.exit(1)

print("\n🎉 ALL AUTH REST API GATEWAY CONNECTIONS FUNCTIONAL")
