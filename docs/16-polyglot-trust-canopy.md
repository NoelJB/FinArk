# 🏛️ Architectural Documentation: Polyglot Distributed Trust & Ingestion Canopy

This document details the architectural design and pedagogical strategy implemented in **Milestone 2** of the platform chassis. It explores the rationale for standardizing a uniform, cross-language state contract, enforcing multi-tenant data boundaries at the business tier, and decoupling edge authentication from internal microservice classpaths.

---

## 🧭 1. The Polyglot Identity Boundary Contract

In multi-language enterprise microservice clusters, a common anti-pattern is allowing each independent language runtime (Python, Node.js, and Java) to handle session state validation using its own native, isolated mechanisms. This creates disjointed authentication loops, duplicate session replication debt, and database I/O bottlenecks.

The platform neutralizes this friction by enforcing a strict **Polyglot Distributed Identity Perimeter** anchored over a single high-speed in-memory data grid.

### 🔌 Multi-Language Runtime Topology

```text
             [ Public Inbound Traffic ]
                         │
                         ▼
        [ api-gateway : Node.js / NestJS ] ───( Validates JWT Signature )
                         │                                │
                         ▼ (On Cache Miss)                ▼ (On Cache Hit)
         [ auth-service : Python / Flask ]       [ Interrogates Valkey RAM Pool ]
                         │                            "auth_session:{tokenUuid}"
                         │                                │
                         ▼                                ▼
                 [ Appends to DB ] ──────────────> [ Propagates Inward ]
                                                          │
                                             ┌────────────┴────────────┐
                                             ▼                         ▼
                                   [ order-placement ]       [ Future Services... ]
                                    (Java 25 / JRE)            (Go, Rust, etc.)
                                   Reads: X-User-Id            Reads: X-User-Id
```

### 🪐 Core Architectural Synchronization Invariant
Every component in the cluster—regardless of whether it runs on top of the V8 JavaScript engine, an interpreted Python runtime, or a Java Virtual Machine—implicitly adheres to a single shared keyspace structure:
`auth_session:{tokenUuid}`

The state lifecycle is coordinated across three distinct tiers:

1. **The Outer Firewall (Edge Node):** The NestJS gateway intercepts public requests, cryptographically validates incoming token signatures, and interrogates the Valkey RAM pool at O(1) complexity. This approach verifies session integrity in microseconds without executing a single slow relational disk query.
2. **The Context Propagation Protocol:** Once verified, the gateway strips the heavy cryptographic processing layers. It converts the validated internal state array into a single, highly compressed tracking parameter and forwards it down into the private network mesh inside the custom HTTP header: `X-User-Id`.
3. **The Business Invariant Gate (Ingestion Node):** The downstream Java 25 microservice inherits this passthrough trust seamlessly. It reads the incoming header value and instantly executes programmatic tenant isolation asserts before running any data mapping transactions.

---

## 🔌 2. Multi-Tenant Data Ownership & Pre-Trade Invariants

### The Invariant Constraint Equation
To protect the append-only ledger from cross-tenant data manipulation exploits (OWASP A01:2021 Broken Access Control), the platform rejects simple Role-Based Access Control (RBAC) validations at the ingestion boundary. Holding a valid `CLIENT` or `MISSION_OPERATOR` role token is insufficient to mutatively modify records.

The business tier programmatically asserts an absolute **Data Ownership Invariant**:

`Context(X-User-Id) == Payload(client_id)`

### ☕ Code Implementation Reference: Invariant Gates

The Java pre-trade domain canopy implements these boundary protections sequentially:

```java
@Transactional
public void processPreTradeOrderPlacement(int verifiedContextUserId, OrderSubmitRequest order) {
    
    // 🔒 GUARD 1: Multi-Tenant Ownership Invariant Assertion
    if (verifiedContextUserId != order.clientId()) {
        throw new IllegalArgumentException("Security Violation: Resource ownership mismatch. Operation aborted.");
    }

    // 🔍 GUARD 2: Surrender Surrogate Primary Key String Translation
    Integer internalInstrumentId = mapper.getInstrumentIdByTicker(order.ticker());
    if (internalInstrumentId == null) {
        throw new IllegalArgumentException("Pre-Trade Violation: Targeted asset ticker '" + order.ticker() + "' not recognized.");
    }

    // 🌐 GUARD 3: Scalable Read-Through Cache Price Variance Filter
    BigDecimal currentMarketPrice = marketDataService.getCurrentPrice(internalInstrumentId, order.ticker());
    BigDecimal variancePct = order.price().subtract(currentMarketPrice).abs()
                                   .divide(currentMarketPrice, 4, RoundingMode.HALF_UP);
                                   
    if (variancePct.compareTo(new BigDecimal("0.05")) > 0) {
        throw new IllegalArgumentException("Pre-Trade Violation: Order price deviance exceeds threshold.");
    }
}
```

### Technical Design Decisions:
* **The Surrogate Key Abstraction:** Front-end clients route order structures utilizing human-readable, user-friendly **`ticker` asset strings** rather than exposing internal database integer primary keys. The Java persistence mapping tier dynamically resolves surrogate identifier keys inline, abstracting database internals away from perimeter boundaries.
* **The Read-Through Scaling Engine:** Market data requests route exclusively through the shared Chassis SDK library. The cache interceptor queries Valkey first; on a cache miss, it issues a synchronous REST call to the cloud provider, auto-populating the Valkey pool with a strict 60-second Time-To-Live (TTL).

---

## 🛠️ 3. DevOps Lifecycle Complete Automation Topology

To maximize development velocity and isolate students from environment-specific configuration debt, the automated regression pipeline is completely decoupled into a **Dynamic Strategy Discovery Mesh**.

### Hardened Multi-Stage Build Context Topology

```text
[ Host Storage Disk ]                      [ BuildKit Isolated Container Context ]
 ├── packages/finark-core-java  ──(Mount)──>  WORKDIR /build-sdk 
 │                                                └── mvn clean install (Writes to private cache)
 │                                                              │
 └── services/order-placement-service ──(Mount)──> WORKDIR /build-app ◄──┘
                                                  └── mvn clean package (Resolves jar locally)
```

To eliminate the connection race condition and ensure local artifacts are shared horizontally across isolated Multi-Stage compilation containers, the orchestration layer relies on two core primitives:

### 1. Anonymous Cache Mount Pools
The `Dockerfile` utilizes BuildKit compiler cache volumes to preserve downloaded artifacts without bloating host storage or polluting the version control workspace:
```dockerfile
RUN --mount=type=cache,target=/root/.m2 mvn clean install -DskipTests -B
```
By local-installing the shared library context to an anonymous container mount cache target *prior* to parsing the microservice application dependencies, the application packaging stage resolves local `.jar` files without attempting to fetch un-published artifacts from public online repositories.

### 2. Sliced Configuration Test Boundaries
To prevent sliced controller testing layers (`@WebMvcTest`) from choking on missing database infrastructure requirements (like data sources, connection pools, or connection locks), the platform separates its bootstrapping classes:
* `OrderPlacementApplication.java`: Houses the clean, standard Spring Boot initializer hook.
* `config/MyBatisConfig.java`: Houses the specialized `@MapperScan` class annotations.

During web-slice testing passes, Maven targets the controller layer in isolation. It skips initializing heavy database driver modules, which prevents context initialization crashes and yields fast, predictable test execution passes inside the virtual test-runner image layer.
