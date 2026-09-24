# FinArk Lesson: Turnkey Automation via Docker Compose Profiles

## 🧠 The Architectural Evolution
In earlier stages of our platform development, executing our regression test suite required a multi-step host-level choreography script (`run-demo.sh` invoking `run-test-container.sh`). The host machine had to manually handle container execution flags, network environment handshakes (`--network="host"`), and local password extraction rules.

To build a professional, platform-independent DevOps pipeline, FinArk completely eliminates external host shell loops. We transition the entire testing layer to execute natively within the container virtualization cluster using **Docker Compose Profiles** and **Service Health Gatekeepers**.

---

## 🏗️ 1. Core Component Isolation: Standard vs. Profile Services

By default, running a standard `docker compose up` command scans a composition file and boots up only long-running, persistent services (like our relational database tier). However, integration testing requires an *ephemeral* container task—one that spins up, runs a sequence of file queries, asserts pass/fail metrics, and instantly vanishes.

We decouple this behavior using the `profiles` directive:

* Long-Running Infrastructure (`paysprint-postgres`): Configured without a profile string. It starts automatically under all conditions to serve data traffic.
* Ephemeral Automation (`test-runner`): Grouped explicitly under the `db_tests` profile. It remains completely dark and inactive during normal execution loops, ignoring standard initialization requests.

### Triggering the Profile Loop
To activate the validation matrix, developers or automated CI/CD servers use a targeted activation flag:
  `docker compose --profile db_tests up --attach test-runner`

This instructs the Docker Compose engine to evaluate the isolated test container, build its environmental images, mount the test modules, and attach the terminal output stream cleanly to the active shell console.

---

## 🚦 2. Race Condition Mitigation: Service Health Gatekeepers

A notorious issue in automated database pipelines is the "Connection Reset Race Condition." When a database container starts, the underlying Linux operating system boots up in milliseconds, making the container appear "online" to Docker. However, the database engine inside the container still needs several seconds to allocate its internal buffer memory pools, initialize user permissions, and compile your sequential `initdb.d` schema files.

If a test framework script fires the microsecond the container shows a running state, it will hit a connection drop or a database-not-ready error, crashing the build.

FinArk eliminates this timing anomaly natively by implementing **Deterministic Service Health Gates**:

```text
1. [ Boot Postgres ] ──> Runs Internal Health Check: "pg_isready"
                                │
                                ▼ (Loops until code completes)
2. [ State: Healthy ]   ──> Unlocks depend_on: condition: service_healthy
                                │
                                ▼
3. [ Launch Runner ]    ──> Ephemeral test-runner executes test matrix safely
```

* The Health Check Gatekeeper: The `paysprint-postgres` container continuously executes an internal system check (`pg_isready -U postgres -d paysprint`).
* The Dependency Chain (`depends_on`): The `test-runner` service is configured with a strict condition block:
  `condition: service_healthy`
  This tells Docker to completely block the initialization of the test container until the underlying database engine has completed compiling every single one of your database files and is actively ready to receive connections.

---

## 🛡️ 3. Maintaining Security in Private Network Topographies

When executing tests inside an isolated Docker profile, the test framework container is booted within a secure, private virtual network mesh (`paysprint-network`) instead of using the host machine's open network ports. This introduces two critical security enhancements:

* Elimination of Exposed Ports: The test runner container connects directly to the database via its internal service domain string mapping (`DB_HOST=paysprint-postgres`). The application layer communicates entirely within the internal network mesh, avoiding port exposure to the host.
* Read-Only Volume Mounted Vaults: To inherit authentication tokens without using leaking environment variables or hardcoded Git strings, the profile container mounts the host machine's local ignored secrets storage vault as a protected, read-only layer:
  `- ./secrets:/secrets:ro`
  The test entrypoint reads the dynamic base64 cryptotoken text out of `/secrets/pg_master_pass.txt` strictly in-memory at execution runtime, maintaining a flawless zero-leak footprint.
