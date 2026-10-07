# 🛡️ EDGE MICROGATEWAY PERIMETER SECURITY SPECIFICATIONS
### Stateless Token Verification, O(1) Memory Revocation, & Trust Context Propagation

This design specification maps out the edge validation perimeter, distributed token blacklisting lifecycles, and cross-language trust context translation parameters.

---

## 🌐 1. The Polyglot Identity Boundary Contract
To eliminate connection bottlenecks over primary relational disks, our single-origin Node.js NestJS Edge Proxy intercepts perimeter traffic and coordinates session tracking parameters by referencing a shared, uniform in-memory keyspace schema:
`auth_session:{tokenUuid}`

```text
[ External API Request ] -> [ api-gateway Perimeter Boundary ]
                                       │
                                       ├─► A. Cryptographically verifies JWT signature
                                       └─► B. Interrogates Valkey RAM: EXISTS auth_session:<uuid>
                                                   /           \
                                (If key present)  /             \ (If key absent / Miss)
                                                 ▼               ▼
                                   [ ❌ 401 Unauthorized ]  [ ✅ 200 Authorized Pass ]
                                                                 │
                                                                 ▼ Forwards:
                                                           Sets Header 'X-User-Id'
```

### Perimeter Verification Directives
* **OPTIONS Verb Bypass:** The gatewayadmission control middleware interceptor monitors the incoming HTTP verb signature. If it detects a pre-flight optimization request (`req.method === 'OPTIONS'`), it routes an immediate passthrough `next()` clearance, ensuring seamless CORS handshakes for frontend clients while protecting functional pathways.
* **Low-Latency Session Verification:** The gateway uses its high-speed client driver to run a sub-millisecond check against the volatile memory pool. If the authenticated token’s matching UUID string has been deleted from Valkey via an out-of-band `/logout` command, the session is treated as revoked, throwing an HTTP `401` block.

---

## 🔗 2. Pass-Through Trust Context Propagation
To mitigate the **"Eggshell Architecture" vulnerability**—where internal network microservices remain unprotected and unauthenticated—the platform standardizes on a decentralized pass-through trust pipeline.

* **Perimeter Pass-Through:** The API Gateway does *not* strip or consume the authorization context permanently. It forwards the raw, unsigned JWT token string intact inside the standard `Authorization: Bearer <token>` header down to internal container targets.
* **X-User-Id Header Inversion:** The proxy middleware translates the validated session metadata claims into a primitive, compressed tracking header named **`X-User-Id`**, passing the verified user surrogate ID parameter natively into the internal private network mesh network (`paysprint-network`).

---

## 🔒 3. Business Tier Multi-Tenant Ownership Invariant
Downstream microservices (such as your Java JRE 25 Spring Boot order placements system) accept this tracking header natively. Before compiling any low-level parameterized MyBatis XML data mappers or modifying database rows, the business tier programmatically evaluates an absolute **Ownership Invariant Constraint**:

```java
// Enforces programmatic multi-tenant isolation boundaries at the business tier (OWASP A01)
if (verifiedContextUserId != order.clientId()) {
    throw new IllegalArgumentException("Security Violation: Resource ownership mismatch. Operation aborted.");
}
```

### Core Security Protections
* **Broken Access Control Mitigation (OWASP Top 10):** Holding a valid token or passing an RBAC role assertion gate is rejected as insufficient. Entity metrics *must* match user tracking parameters. This completely blocks attackers from manipulating another client's trading parameters via cross-tenant ID spoofing.
* **Surrogate Key Abstraction:** Front-end clients route order payloads utilizing human-readable, user-friendly **`ticker` asset strings** rather than exposing internal relational primary keys. The database engine resolves surrogate identifier fields entirely behind the security perimeter, abstracting data blueprints away from public boundaries.
