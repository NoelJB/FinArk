# 🏛️ PLATFORM CHASSIS ENGINE DISTRIBUTED TRUST SPECIFICATIONS
### Stateless Token Verification, O(1) Memory Revocation, & Multi-Tenant Invariants

This document establishes the official reference specifications for perimeter admission control, context-path service routing, stateless cross-language claim propagation, and data tier multi-tenant ownership boundaries.

---

## 🧭 1. Bounded Context Perimeter Firewall (The Edge Node)
To protect internal cluster network contexts from public surface area exposure, all perimeter traffic routes exclusively through a single centralized Node.js NestJS Microgateway entry point. This pattern decouples public interface pathways entirely from internal private container URLs.

```text
[ External HTTP Request ] ───> [ NestJS api-gateway Perimeter Boundary ]
                                          │
                                          ├── 1. auth.middleware (OPTIONS bypass, check JWT signature)
                                          └── 2. dynamic-proxy (Extract sub_id, inject X-User-Id header)
                                                       │
                                                       ▼ Forwards plain TCP stream:
                                       [ Private Microservice Network Mesh ]
                                          └── http://order-placement-service:8080/
```

### A. Perimeter Admission Policy
* **Target Subsystem Module:** `services/api-gateway/src/middleware/auth.middleware.ts`
* **Operational Invariant:** Intercepts incoming network traffic matching the versioned namespace prefix (`api/v1/*`). If the request utilizes an unauthenticated pre-flight handshake packet (`req.method === 'OPTIONS'`), it routes an immediate passthrough `next()` clearance, ensuring seamless CORS verification for browser clients.
* **Fail-Secure Mitigation:** All non-preflight methods mandate a valid token signed via the cluster's secure shared secret. It isolates the token string, unpacks the cryptographic signature locally in application memory, and extracts its unique token identifier (`jti` UUID) claim to filter out unauthenticated payloads.

### B. High-Speed Memory Blacklisting Filter
* **Target Subsystem Module:** `services/api-gateway/src/security/session-grid.ts`
* **Operational Invariant:** To handle instant, real-time administrative session revocation or user logout sequences without executing slow relational database disk queries, the gateway runs an O(1) query check against our high-speed Valkey cache grid keyspace:
  `EXISTS auth_session:<jti_uuid>`
* **Resource Cleanup Lifecycle:** If the token signature has been evicted from Valkey, the gate terminates the connection instantly with an HTTP `401 Unauthorized` response. Internal microservice container layers never ingest a single network packet from a blacklisted or stale session envelope.

---

## 🔗 2. Pass-Through Trust Context Propagation (The Mesh Canopy)
To eliminate the "Eggshell Architecture" vulnerability—where internal network microservices remain unprotected and unauthenticated behind a gateway perimeter—the platform mandates a strict decentralized pass-through trust pipeline.

* **Perimeter Pass-Through:** The API Gateway does not consume or strip the identity claims permanently. It forwards the raw, original unsigned JWT token string completely intact inside the standard HTTP `Authorization: Bearer <token>` header down to internal container targets.
* **X-User-Id Context Inversion:** To maximize network performance, the gateway's proxy middleware translates the validated session metadata claims into a primitive, compressed tracking header named **`X-User-Id`**, passing the verified user surrogate ID parameter natively into the internal private network switch mesh (`paysprint-network`).
* **Dynamic Service Port Locators:** The reverse proxy middlewarecapitalizes incoming targeted context paths, replaces hyphens with underscores, and looks up environment variables dynamically at runtime to resolve internal port configurations (e.g., parsing `ORDER_PLACEMENT_SERVICE_PORT`), defaulting to standard internal port `8080` if no override is found.

---

## 🔒 3. Business Tier Multi-Tenant Ownership Invariant (The Ingestion Node)
Downstream microservices (such as the Java JRE 25 Spring Boot order placement application) receive the passthrough tracking context. Before compiling any low-level parameterized MyBatis XML data mappers or modifying database rows, the business service layer programmatically evaluates an absolute data ownership check boundary.

```java
@Transactional
public void processPreTradeOrderPlacement(int verifiedContextUserId, OrderSubmitRequest order) {
    
    // 🔒 GUARD 1: Multi-Tenant Ownership Invariant Assertion (OWASP Top 10: A01 Check)
    if (verifiedContextUserId != order.clientId()) {
        throw new IllegalArgumentException("Security Violation: Resource ownership mismatch. Operation aborted.");
    }

    // 🔍 GUARD 2: Surrender Surrogate Primary Key String Translation
    Integer internalInstrumentId = mapper.getInstrumentIdByTicker(order.ticker());
    if (internalInstrumentId == null) {
        throw new IllegalArgumentException("Pre-Trade Violation: Targeted asset ticker '" + order.ticker() + "' not recognized.");
    }
}
```

### Strategic System Isolation Design Decisions
* **Broken Access Control Mitigation (OWASP Top 10):** Passing an implicit Role-Based Access Control (RBAC) role evaluation alone is rejected as insufficient to run a database mutation. Entity parameters *must* match user parameters (`Context(X-User-Id) == Payload(client_id)`). This completely blocks attackers from manipulating another client's portfolio records via cross-tenant ID spoofing.
* **Surrogate Key Abstraction:** Front-end clients route order payloads utilizing human-readable, user-friendly **`ticker` asset strings** rather than exposing internal database integer primary keys. The database engine resolves surrogate identifier fields entirely behind the security perimeter, abstracting data blueprints away from public boundaries.
* **Decoupled Identity Warehousing:** To prevent a data leak from exposing the system's underlying authentication credentials, password hashes and salts are strictly isolated into a separate table partition (`client_credentials`) away from core financial client reference tables, minimizing our architectural blast radius.
