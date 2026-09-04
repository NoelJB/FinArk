# FinArk Architecture: Understanding the Turnkey Container Sandbox

## 🧠 The Pedagogical Goal
When you execute the master orchestrator script (`./run-demo.sh`), the FinArk Platform initializes its entire relational database layout, compiles advanced analytical window views, seeds mock client transaction blocks, hardens user permissions, and runs an automated matrix test suite completely green in a matter of seconds. 

This document pulls back the curtain on this automation, explaining the native container architecture and file routing mechanisms that drive this turnkey environment.

---

## 🏗️ 1. How PostgreSQL Automatically Loads the Database Tree

If you inspect the `docker-compose.yaml` configuration file, you will discover this specific entry under the database service block:

volumes:
  - ./db:/docker-entrypoint-initdb.d

This single line leverages Docker's native volume-mounting engine to hook your local computer's file system directly into the virtual environment of the container. 

The official PostgreSQL Docker container image is pre-engineered with a brilliant initialization workflow. The very first time a container boots up, its internal entrypoint startup script automatically looks inside the specific internal folder directory `/docker-entrypoint-initdb.d/`. 

If it finds any files ending with the `.sql`, `.sql.gz`, or `.sh` extension tokens, it automatically reads them and executes them sequentially.

### Enforcing the Chronological Boot Sequence
To ensure our database layers compile without structural dependency collisions, FinArk uses a strict alphanumeric naming convention inside the `db/` folder:
* db/00-init.sql: Sets up the raw multi-tenant system database context.
* db/01-schema.sql: Builds the core relational tables.
* db/02-seed.sql: Loads initial advisor, model portfolio, and client assets.
* db/03-compliance-validation.sql: Compiles the static compliance analytical views.
* db/04-portfolio-audit.sql: Formats the append-only history log window views.
* db/05-eod-regulatory.sql: Physicalizes data caching via Materialized Views.
* db/06-drift-view.sql: Registers the complex live asset drift calculations.
* db/07-outbox-infrastructure.sql: Deploys the shared event bus outbox and limited application user roles.
* db/08-execution-ledger.sql: Builds the immutable append-only execution ledger and clearing trigger.
* db/09-portfolio-monitoring.sql: Binds the reactive post-settlement drift breach monitoring alert trigger.

The database engine reads these files in strict alphabetical order. This guarantees that tables are created before data is seeded, data is seeded before views are compiled, and views are compiled before triggers attempt to look them up.

---

## 🔒 2. Understanding the Shared Host Network Topology

The automation testing harness requires our isolated containers to speak to one another seamlessly. FinArk configures this using a dual network layer design:

### A. The Container-Private Network Bridge (`paysprint-network`)
Inside `docker-compose.yaml`, we define a dedicated, isolated private virtual network. This allows services running inside the Docker cluster to discover and communicate with one another using their container name strings as raw web address pointers (e.g., connection links mapping directly to `paysprint-postgres:5432`).

### B. Host Network Share Integration (`--network="host"`)
When our isolated container runner fires off via `test/run-test-container.sh`, it uses a unique directive:
docker run --rm --network="host" ...

Instead of placing our ephemeral test runner container inside its own standalone virtual network box, `--network="host"` tells the Docker engine to let the container share your computer's native network ports directly. 

Because the main PostgreSQL service maps its database out to the host system via port `5432` (`ports: - "5432:5432"`), the test container can look at its own local environment network (`-h localhost`) to securely connect, execute SQL modules, and scan assertion streams instantly with zero complex IP configuration overhead.
