#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - PHASE 3: IDENTITY PROVIDER (DECENTRALIZED MEMORY GRID)
# Target File: services/auth-service/auth_service.py | BRS: BR-01 / BR-02 / BR-03
# ============================================================================

import os
import sys
import uuid
import time
from datetime import datetime, timezone
from flask import Flask, request, jsonify
import jwt
import pg8000.dbapi

# 🔌 Import the custom internal shared platform sdk module chassis
from finark_core.session_grid import SecurityGrid

app = Flask(__name__)

# 1. SECURITY CONFIGURATION & VAULT SECRET INJECTION
SECRET_FILE_PATH = "/run/secrets/jwt_shared_secret"
PG_PASSWORD_FILE = "/run/secrets/pg_master_pass"
VALKEY_HOST = os.getenv("VALKEY_HOST", "localhost")
VALKEY_PORT = int(os.getenv("VALKEY_PORT", 6379))
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "paysprint")
DB_USER = os.getenv("DB_USER", "postgres")

def load_vault_secret(file_path, env_fallback):
    """Extracts sensitive key material from mounted secret paths securely."""
    if os.path.exists(file_path):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read().strip()
        except Exception as e:
            print(f"⚠️ Vault Read Warning: Unable to parse {file_path}. Details: {e}")
    return os.getenv(env_fallback, "developer-fallback-secret-key-32-bytes-min")

JWT_SECRET = load_vault_secret(SECRET_FILE_PATH, "JWT_SECRET")
print(f"[auth_service] JWT_SECRET (len is {len(JWT_SECRET)}): {JWT_SECRET[:4]}..{JWT_SECRET[-4:]}")
DB_PASSWORD = load_vault_secret(PG_PASSWORD_FILE, "DB_PASSWORD")

# 🔌 Initialize our shared platform decentralized state layer connection
try:
    security_grid = SecurityGrid(
        valkey_host=VALKEY_HOST,
        valkey_port=VALKEY_PORT,
        jwt_secret=JWT_SECRET
    )
except Exception as e:
    print(f"❌ Core Platform Failure: Shared Security Grid unreachable. Details: {e}")
    sys.exit(1)

def get_db_connection():
    """Establishes an isolated thread-level connector handle to the database."""
    return pg8000.dbapi.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

def extract_token_from_header(header_string):
    """Safely isolates the raw string JWT from standard Bearer headers using idiomatic tuple unpacking."""
    if not header_string:
        return None
        
    try:
        # 🔐 Hardened: Idiomatic unpacking catches trailing padding via starred discard
        schema, value, *_ = header_string.split(" ")
        
        if schema.lower() == 'bearer':
            return value
    except ValueError:
        # Catches cases where split doesn't yield at least two distinct variables
        return None
        
    return None

# ----------------------------------------------------------------------------
# 🔐 ENDPOINT: /login (BR-01 SECURE SIGN-IN VIA DATABASE VERIFICATION)
# ----------------------------------------------------------------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({"error": "missing credentials"}), 400
        
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        query = """
            SELECT cc.client_id, string_agg(pr.role_name, ',') as roles
            FROM client_credentials cc
            LEFT JOIN client_role_mappings crm ON cc.client_id = crm.client_id
            LEFT JOIN platform_roles pr ON crm.role_id = pr.role_id
            WHERE cc.username = %s AND cc.password_hash = crypt(%s, cc.password_hash)
            GROUP BY cc.client_id;
        """
        
        cursor.execute(query, (username, password))
        result = cursor.fetchone()
        
        if not result:
            return jsonify({"error": "invalid username or password"}), 401
            
        client_id, raw_roles_string = result
        
        if raw_roles_string:
            assigned_roles = raw_roles_string.split(',')
        else:
            assigned_roles = ["GUEST"]
            
        token_uuid = str(uuid.uuid4())
        
        # 🟢 GREENFIELD UTC ALIGNMENT & PRECISION ENTROPY FIXED:
        # Force the calculations to use standard timezone-blind UTC timelines.
        # Inject fractional milliseconds as a private claim to enforce unique signature entropy.
        now_utc = datetime.now(timezone.utc)
        now_epoch = int(now_utc.timestamp())
        fractional_ms = int(now_utc.microsecond / 1000)
        lifespan_seconds = 3600  # 1 hour
        
        # 🪐 RFC 7519 STANDARD PAYLOAD MAPPING
        payload = {
            "sub": str(client_id),
            "username": username,       # 🟢 RESTORED: Explicit username context identification
            "roles": assigned_roles,
            "jti": token_uuid,
            "iat": now_epoch,
            "ms_offset": fractional_ms, # Private claim isolates signatures from sub-second collisions
            "exp": now_epoch + lifespan_seconds
        }
        
        token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
        
        # 🟢 WHITE-BOX DIAGNOSTICS INJECTED:
        print(f"📡 [auth-service DIAGNOSTIC] Login Successful for user: {username}", flush=True)
        print(f"📡 [auth-service DIAGNOSTIC] Generated JTI tracking UUID: {token_uuid}", flush=True)
        print(f"📡 [auth-service DIAGNOSTIC] Core Payload mapping object: {payload}", flush=True)
        
        # Pass tracking parameters straight down to the platform SDK
        granted = security_grid.grant(
            token_uuid=token_uuid,
            subject_id=client_id,
            roles=assigned_roles,
            ttl_seconds=lifespan_seconds
        )
        print(f"📡 [auth-service DIAGNOSTIC] security_grid.grant status return value: {granted}", flush=True)
        
        return jsonify({"token": token})
    except Exception as e:
        print(f"❌ [auth-service DIAGNOSTIC] Login Exception Trapped: {e}", file=sys.stderr, flush=True)
        return jsonify({"error": f"Internal authentication database failure: {str(e)}"}), 500

# ----------------------------------------------------------------------------
# 🔐 ENDPOINT: /register (BR-01 USER ENROLLMENT & STORAGE ROUTINE)
# ----------------------------------------------------------------------------
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    client_id = data.get('client_id')
    
    if not username or not password or not client_id:
        return jsonify({"error": "missing registration requirements"}), 400
        
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        query = """
            INSERT INTO client_credentials (client_id, username, password_hash)
            VALUES (%s, %s, crypt(%s, gen_salt('bf', 8)));
        """
        cursor.execute(query, (int(client_id), username, password))
        conn.commit()
        
        cursor.close()
        conn.close()
        
        return jsonify({"status": "user account successfully enrolled and encrypted"}), 201
        
    except pg8000.dbapi.IntegrityError:
        return jsonify({"error": "registration collision: username or client ID already managed"}), 409
    except Exception as e:
        return jsonify({"error": f"Internal identity store enrollment failure: {str(e)}"}), 500

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
        payload = jwt.decode(raw_jwt, JWT_SECRET, algorithms=['HS256'], options={"verify_exp": False})
        token_uuid = payload.get('jti')
        
        if token_uuid:
            # 🔌 Route eviction commands cleanly through our internal SDK layer
            security_grid.revoke(token_uuid=token_uuid)
            
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
        
    # 🔌 Route verification passes directly through our core SDK logic block
    session_claims = security_grid.is_valid(raw_token=raw_jwt)
    
    if not session_claims:
        return jsonify({"valid": False, "error": "token has expired or been revoked"}), 401
        
    return jsonify({"valid": True, "claims": session_claims}), 200

if __name__ == '__main__':
    port = int(os.getenv("PORT", 4000))
    print(f"🚀 FinArk Revocable Auth Microservice active on port {port}")
    app.run(host='0.0.0.0', port=port)
