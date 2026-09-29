# ============================================================================
# FINARK CORE PLATFORM CHASSIS SDK - DISTRIBUTED SESSION GRID MANAGEMENT
# Target File: packages/finark-core/finark_core/session_grid.py | BRS: BR-14
# ============================================================================

import json
import logging
import valkey
import jwt

logger = logging.getLogger("finark.core.session_grid")

class SecurityGrid:
    """Manages decentralized high-performance security sessions over a shared Valkey grid."""
    
    def __init__(self, valkey_host: str, valkey_port: int, jwt_secret: str):
        self.jwt_secret = jwt_secret
        try:
            self.cache = valkey.Valkey(
                host=valkey_host, 
                port=valkey_port, 
                decode_responses=True,
                socket_timeout=2.0
            )
        except Exception as e:
            logger.critical(f"❌ Security Grid initialization dropped connection. Details: {e}")
            raise

    def grant(self, token_uuid: str, subject_id: int, roles: list, ttl_seconds: int, metadata: dict = None) -> bool:
        """Registers a fresh authenticated session security envelope into the shared grid."""
        try:
            envelope = {
                "sub_id": int(subject_id),
                "roles": list(roles),
                "metadata": dict(metadata) if metadata else {}
            }
            cache_key = f"auth_session:{token_uuid}"
            serialized_payload = json.dumps(envelope)
            return bool(self.cache.setex(cache_key, ttl_seconds, serialized_payload))
        except Exception as e:
            logger.error(f"❌ Security Grid failed to grant session token {token_uuid}: {e}")
            return False

    def is_valid(self, raw_token: str) -> dict | None:
        """Decodes the raw token string and verifies its active state against the Valkey grid."""
        try:
            payload = jwt.decode(raw_token, self.jwt_secret, algorithms=['HS256'])
            token_uuid = payload.get("jti")
            if not token_uuid:
                return None
                
            cache_key = f"auth_session:{token_uuid}"
            raw_session = self.cache.get(cache_key)
            if not raw_session:
                return None
                
            return json.loads(raw_session)
        except (jwt.InvalidTokenError, jwt.ExpiredSignatureError):
            return None
        except Exception as e:
            logger.error(f"⚠️ Fail-Secure Override: Cache communication drop encountered: {e}")
            return None

    def revoke(self, token_uuid: str) -> bool:
        """Evicts a session identifier from the grid, triggering instant global token lockout."""
        try:
            cache_key = f"auth_session:{token_uuid}"
            return bool(self.cache.delete(cache_key))
        except Exception as e:
            logger.error(f"❌ Security Grid failed to revoke session token {token_uuid}: {e}")
            return False
