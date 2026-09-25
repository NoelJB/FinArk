# FinArk Lesson: Stateless Identity Verification & In-Memory Session Revocation

## 🧠 The Architectural Dilemma: Session Revocation vs. Scale
In a modern distributed financial network conforming to the platform's core Business Requirements Specification (BRS), verifying a user's identity and permissions introduces a critical engineering trade-off between stateless horizontal scaling and strict compliance parameters:

1. The Relational Bottleneck: Storing session states inside a database table forces every single inbound microservice request across the entire enterprise grid to execute a synchronous read query against the primary relational disk engine. This quickly chokes database I/O and creates a severe system bottleneck.
2. The Stateless Trust Gap: To maximize performance, architectures often utilize stateless JSON Web Tokens (JWTs). Once a user signs in, the service signs a cryptographic token containing their claims. Downstream microservices validate this token entirely in application memory with zero network round-trips. However, this creates a compliance failure under BR-03: because the token is entirely stateless, it cannot be revoked, killed, or logged out before its natural expiration timer runs down.

---

## 🏗️ The Hybrid Solution: Stateless-First, Cache-Backed Revocation

To satisfy both high-throughput scalability and the strict mandate for immediate administrative session revocation, FinArk standardizes on a **Stateless-First, Cache-Backed Revocation Blueprint**:

```text
[ Client HTTP Request with JWT ] ──> [ API Gateway / Router ]
                                              │
                                              ▼
                                 Locally verifies cryptographic signature (No DB network calls)
                                              │
                                              ▼
                                 Checks Valkey Memory: EXISTS blacklist:<jti_or_sig>
                                        /           \
                     (If key exists)   /             \ (If key absent / Miss)
                                      ▼               ▼
                        [ ❌ 401 REVOKED ]       [ ✅ 200 AUTHORIZED ]
```

### 1. The Unique Token Identifier (`jti` claim)
When a client authenticates via the `/login` endpoint, the Identity Provider signs an `HS256` JWT. Crucially, it injects a cryptographically unique **JSON Web Token ID (`jti`)** UUID claim block directly into the payload. This `jti` acts as an unalterable tracking fingerprint for that specific user session instance.

### 2. Microsecond Memory Filtering via Valkey
Downstream microservices or API gateways process incoming requests by verifying the cryptographic signature of the token locally in memory. 

To handle revocation checks without hitting a heavy database disk, the service pings our high-speed **Valkey** in-memory cluster layer via a highly optimized command: `EXISTS blacklist:<jti_uuid>`. Valkey evaluates RAM metrics at O(1) complexity, returning a response in microseconds. If the key is absent, the token is safe and authorized.

### 3. Automatic Cache Pruning via Time-To-Live (TTL)
When a user executes a `/logout` command or an administrator revokes a compromised session, the Identity Provider extracts the token's remaining lifespan by calculating the delta between the current timestamp and the token's internal expiration (`exp`) claim. 

The service registers the `jti` into Valkey memory and assigns a strict **TTL (Time-To-Live)** window matching that remaining duration exactly. The moment the JWT naturally expires across the network, Valkey automatically drops the signature from RAM. This prevents memory bloat entirely without requiring cron cleanup jobs or database vacuuming scripts.

---

## 🛡️ Context Propagation & Downstream Claim Validation (BR-02 Enforced)

### Mitigating the "Eggshell Architecture" Vulnerability
A common architectural pitfall in microservices security is verifying and stripping tokens entirely at the API Gateway perimeter, leaving the internal network completely "soft" and unauthenticated. If an attacker breaches the gateway perimeter, or if an internal service container is compromised, the attacker can spoof traffic horizontally across internal systems with zero structural resistance.

To satisfy **BR-02 (Horizontal Tenant Isolation)**, the platform mandates a strict **Pass-Through Trust Topology**:

```text
                  [ Signed JWT Token Header ]
                              │
                              ▼
                       [ API Gateway ] 
                              │ (Terminates TLS, checks blacklist, forwards token)
                              ▼
                  [ Internal Network Mesh ]
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
   [ Portfolio Service ]               [ Execution Service ]
   - Unpacks JWT locally               - Unpacks JWT locally
   - Asserts: client_id == 1           - Asserts: role == 'MISSION_OPERATOR'
```

### 1. Perimeter Sanitization
The API Gateway acts as the external gatekeeper. It terminates external secure connections, validates the structural integrity of the token's cryptographic signature, and checks our Valkey memory pool to ensure the token's unique `jti` is not blacklisted.

### 2. Pass-Through Trust Propagation
The Gateway does *not* consume or strip the identity packet. It forwards the raw, original unsigned JWT string completely intact inside the standard HTTP `Authorization: Bearer <token>` header down to the target internal microservice threads.

### 3. Decentralized Claim Assertions
When the token header reaches its internal destination service, that specific service unpacks the payload and evaluates claims tailored explicitly to its own business logic domain:
* **The Data Boundary Check:** The Portfolio Service inspects the embedded `client_id` claim, comparing it directly to the requesting account parameter to prevent a client from viewing another client's asset balances.
* **The Role RBAC Gate:** The Execution engine reads the `roles` array claim to ensure a user holding a `GUEST` profile cannot execute a write transaction.

Because the token is signed cryptographically by our Identity Provider using the shared secret, internal microservices can trust these claims implicitly without needing to query a centralized database or ping back to the Auth service, preserving our high-velocity horizontal scalability.

## 🛡️ Decoupled Identity Warehousing vs. Accounting Normalization

### The Structural Principle of Separation of Concerns (BR-01 Enforced)
A severe architectural mistake frequently observed in primitive microservice layouts is merging user authentication parameters (such as usernames, password hashes, salts, and multi-factor validation data blocks) directly into the primary client transactional registry tables (`client`). 

FinArk strictly isolates these domains at the relational data tier to preserve enterprise-grade normalization and defense-in-depth security:

```text
  [ Identity Tier (Auth Service) ]               [ Core Accounting Ledger ]
   ┌──────────────────────────┐                   ┌───────────────────────┐
   │    client_credentials    │                   │        client         │
   ├──────────────────────────┤                   ├───────────────────────┤
   │ client_id (PK/FK)        │ ──(References)──> │ id (PK)               │
   │ username (Unique)        │                   │ name                  │
   │ password_hash            │                   │ model_id              │
   └──────────────────────────┘                   └───────────────────────┘
```

### 1. Hardening the Blast Radius
The primary `client` table functions as the operational core of our wealth management machine. It handles multi-table accounting joins, ledger balances, and portfolio drift monitoring arrays. This table undergoes continuous read-write actions. 

Conversely, security credentials represent high-risk, highly static tracking indices. Separating credentials into a dedicated, isolated partition (`client_credentials`) ensures that a data leak, an over-privileged query exploit, or an unexpected SQL injection exposure over the core ledger tier cannot expose the system's underlying authentication hashes.

### 2. Eliminating Index Fragmentation & Vacuum Overheads
Password management operations—such as token renewals, registration enrollment updates, and lockouts—generate high-churn row metadata modifications. Storing these transient security update markers inside the same table partition layout as long-term financial client reference records causes aggressive database table bloat. 

In a PostgreSQL engine tier, this breaks performance by forcing continuous autovacuum loops and fragmenting index B-Trees. Keeping the credentials table uncoupled allows the core engine to process ledger sweeps at maximum disk efficiency.

### 3. Least Privilege Role Based Access Bounds (OWASP A05)
Under our established least-privilege security matrix, the application runtime connector user (`paysprint_app`) is structurally banned from querying core client account listings or ledger balances. By isolating credentials into a standalone entity, we can explicitly grant the Identity Microservice direct `SELECT` and `INSERT` privileges over *only* the `client_credentials` mapping structure. 

The auth engine can process sign-ins and register new user accounts natively, while remaining completely blinded to the underlying trading account assets and multi-million-dollar transaction records, enforcing clean architectural zero-trust walls.
