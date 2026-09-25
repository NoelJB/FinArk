#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - PHASE 3: REVOCABLE STATELESS IDENTITY PROVIDER
# Target File: services/auth-service/auth_service.py | BRS: BR-01 / BR-03
# ============================================================================

import os
import sys
import uuid
import time
from flask import Flask, request, jsonify
import jwt
import valkey

app = Flask(__name__)

# 1. SECURITY CONFIGURATION & VAULT SECRET INJECTION
SECRET_FILE_PATH = "/run/secrets/jwt_shared_secret"
VALKEY_HOST = os.getenv("VALKEY_HOST", "localhost")
VALKEY_PORT = int(os.getenv("VALKEY_PORT", 6379))

def load_jwt_secret():
    """Extracts the shared cryptographic key from the mounted secrets engine path."""
    if os.path.exists(SECRET_FILE_PATH):
        try:
            with open(SECRET_FILE_PATH, "r", encoding="utf-8") as f:
                return f.read().strip()
        except Exception as e:
            print(f"⚠️ Vault Read Warning: Unable to parse mounted file. Details: {e}")
    return os.getenv("JWT_SECRET", "developer-fallback-secret-key-32-bytes-min")

JWT_SECRET = load_jwt_secret()

# Establish connection handle to our fast, in-memory Valkey layer
try:
    cache = valkey.Valkey(host=VALKEY_HOST, port=VALKEY_PORT, decode_responses=True)
except Exception as e:
    print(f"❌ Cache Connectivity Failure: Valkey unreachable at {VALKEY_HOST}:{VALKEY_PORT}. Details: {e}")
    sys.exit(1)

# Hardcoded educational user store matching the original curriculum stub profile
USERS = {
    "alice": {"password": "mission123", "roles": ["MISSION_OPERATOR"], "client_id": 1},
    "bob": {"password": "wrongpermissions", "roles": ["GUEST"], "client_id": 2}
}

def extract_token_from_header(header_string):
    """Safely isolates the raw string JWT from standard Bearer headers."""
    if not header_string or ' ' not in header_string:
        return None
    parts = header_string.split(' ')
    if len(parts) == 2 and parts[0].lower() == 'bearer':
        return parts[1]
    return None

# ----------------------------------------------------------------------------
# 🔐 ENDPOINT: /login (BR-01 SECURE SIGN-IN)
# ----------------------------------------------------------------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    
    user = USERS.get(username)
    if not user or user['password'] != password:
        return jsonify({"error": "invalid username or password"}), 401
        
    token_uuid = str(uuid.uuid4())
    now = int(time.time())
    lifespan_seconds = 3600 # 1 hour
    
    payload = {
        "sub": username,
        "client_id": user['client_id'],
        "roles": user['roles'],
        "jti": token_uuid,
        "iat": now,
        "exp": now + lifespan_seconds
    }
    
    token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
    return jsonify({"token": token})

# ----------------------------------------------------------------------------
# 🔐 ENDPOINT: /logout (BR-03 ADMINISTRATIVE REVOCATION CONTROL)
# ----------------------------------------------------------------------------
@app.route('/logout', methods=['POST'])
def logout():
    auth_header = request.headers.get('Authorization', '')
    raw_jwt = extract_token_from_header(auth_header)
    
    if not raw_jwt:
        return jsonify({"error": "missing or malformed access token"}), 400
        
    try:
        # Decode without verification to read claims of tokens flagged for exit
        payload = jwt.decode(raw_jwt, JWT_SECRET, algorithms=['HS256'], options={"verify_exp": False})
        token_uuid = payload.get('jti')
        expiration_time = payload.get('exp', 0)
        
        now = int(time.time())
        remaining_lifespan = expiration_time - now
        
        if remaining_lifespan > 0 and token_uuid:
            cache_key = f"blacklist:{token_uuid}"
            cache.setex(cache_key, remaining_lifespan, "revoked")
            
        return jsonify({"status": "successfully logged out and session destroyed"})
        
    except Exception as e:
        return jsonify({"error": f"failed to process session revocation: {str(e)}"}), 400

# ----------------------------------------------------------------------------
# 🔐 ENDPOINT: /verify (CROSS-SERVICE GATEKEEPER VALIDATION LOOP)
# ----------------------------------------------------------------------------
@app.route('/verify', methods=['GET'])
def verify():
    auth_header = request.headers.get('Authorization', '')
    raw_jwt = extract_token_from_header(auth_header)
    
    if not raw_jwt:
        return jsonify({"valid": False, "error": "missing token"}), 401
        
    try:
        payload = jwt.decode(raw_jwt, JWT_SECRET, algorithms=['HS256'])
        token_uuid = payload.get('jti')
        
        if token_uuid and cache.exists(f"blacklist:{token_uuid}"):
            return jsonify({"valid": False, "error": "token has been explicitly revoked"}), 401
            
        return jsonify({"valid": True, "claims": payload}), 200
        
    except jwt.ExpiredSignatureError:
        return jsonify({"valid": False, "error": "token signature has naturally expired"}), 401
    except jwt.InvalidTokenError:
        return jsonify({"valid": False, "error": "corrupted or invalid token signature pattern"}), 401

if __name__ == '__main__':
    port = int(os.getenv("PORT", 4000))
    print(f"🚀 FinArk Revocable Auth Microservice active on port {port}")
    app.run(host='0.0.0.0', port=port)
