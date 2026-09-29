# 🗺️ EDGE MICROGATEWAY ARCHITECTURAL SPECIFICATIONS
### Bounded Context Perimeter Interface & Dynamic Service Locator Model

The FinArk platform utilizes a centralized **Edge Reverse Proxy with an Inline Authentication Guard** running on NestJS to handle perimeter traffic orchestration. This pattern establishes a single, unified origin, completely masking internal container network configurations and eliminating Cross-Origin Resource Sharing (CORS) or Same-Origin Policy (SOP) friction loops at the edge.

---

## 📋 1. Perimeter Admission Control Policy (The Edge Guard)
*   **Component Target:** `services/api-gateway/src/middleware/auth.middleware.ts`
*   **Execution Timing:** Executes at the absolute entry point of the HTTP lifecycle, before any request parsing or routing engines engage.
*   **Operational Mandate:** Intercepts all inbound traffic matching the versioned namespace prefix (`api/v1/*`). It splits the `Authorization: Bearer <JWT>` header using a starred string unpacking pattern, isolates the raw signature, and runs a sub-millisecond local check against the Valkey grid (`active_token:<UUID>`).
*   **Fail-Secure Behavior:** If an identity token is missing, malformed, or administratively revoked, the gate terminates the connection instantly with an HTTP `401 Unauthorized` response. Internal microservice containers never ingest a single network packet from unauthenticated payloads.

---

## 🔗 2. Dynamic Service Locator Router (The Context-Path Broker)
*   **Component Target:** `services/api-gateway/src/middleware/dynamic-proxy.middleware.ts`
*   **Execution Timing:** Executes sequentially immediately following a successful pass through the Perimeter Admission Gate.
*   **Operational Mandate:** Decouples internal container URLs from public paths using an invariant context-path string parsing translation:
```text
Public Request Signature:  /api/v1/trade-gateway/order/submit
                             └── Index 3: Target Service
                             
Dynamic Interpolation:     http://trade-gateway:${TRADE_GATEWAY_PORT}/api/v1/order/submit
```
*   **Variable Port Overrides:** The broker maps internal port configurations dynamically at runtime. It parses the target service identifier string, capitalizes it, replaces hyphens with underscores, and looks up the corresponding environment variable (e.g., `TRADE_GATEWAY_PORT`). If no override flag exists, it defaults to the system-standard internal port `8080`.
*   **Streaming TCP Transmission:** The broker avoids unpacking or allocating memory buffers for incoming JSON payloads. It uses the NestJS `HttpService` module to pipe the raw incoming TCP stream directly to the target downstream microservice container, delivering optimal latency profiles while hiding the cluster network layout from the client.

---

## 🔒 3. Single-Origin Static Asset Baseline
*   **Component Target:** `services/api-gateway/src/app.module.ts`
*   **Operational Mandate:** The root path (`/`) serves static compilation assets (such as a compiled Angular or React single-page application build output tree) from the container's local `public/` directory. If no frontend assets exist, the gateway defaults to returning an HTTP `404 Not Found` for the root path while keeping all functional `/api/v1/*` proxy routing namespaces fully active.
