# Finark Paysprint Platform: Architectural Blueprint

Welcome to the **Finark Paysprint Platform** educational sandbox repository. This project serves as an end-to-end, production-grade reference architecture designed to demonstrate how enterprise systems transition seamlessly from standard data-tier queries to scalable, asynchronous, **Event-Driven Architectures (EDA)**.

---

## 🏗️ Architectural Vision

Most bootcamps teach software development layers in strict isolation. This platform bridges that gap by demonstrating the full lifecycle of a financial transaction. The system is designed to evolve across three pedagogical milestones:

* **1. Relational Layer:** Advanced SQL Queries & Portfolio Analytics
* **2. Reactive Data Layer:** Transactional Outbox & Automated Triggers
* **3. Streaming Infrastructure:** Apache Kafka (KRaft) & Decoupled Microservices

### Milestone Progression Diagram
* [ 1. Relational Layer ] ───> [ 2. Reactive Data Layer ] ───> [ 3. Streaming Infrastructure ]

1. **The Analytical Layer:** How to construct relational database schemas, inject defensive boundaries (check constraints), and write complex window analytics to measure portfolio compliance and drift.
2. **The Reactive Layer:** Overcoming data mutation anti-patterns by shifting to an immutable, ledger-first transactional pipeline using database triggers to handle real-time alerts safely.
3. **The Infrastructure Layer:** Transitioning data changes across system boundaries asynchronously by streaming localized outbox event payloads onto an infrastructure bus without dropping database transactions.

---

## 📌 Currently Initialized Architecture

The following structural building blocks are fully implemented, tested, and locked down within the code repository:

### 1. Database Initialization Engine (`/db`)
The underlying data layer is hosted on a strict lowercase PostgreSQL environment configured as follows:
* **Timezone Standardization:** Locked strictly to `UTC` to enforce uniform, cross-border event tracking.
* **Modern Primary Keys:** All tables utilize modern standard `GENERATED ALWAYS AS IDENTITY` keys rather than legacy `SERIAL` types.
* **Defensive Constraints:** Features six explicit hardening check constraints (guarding against negative asset prices/quantities and protecting string fields from empty or purely whitespace values).
* **The Core Relational Domain:** Implements 7 unified tables representing independent lookup components (`advisor`, `model_portfolio`, `instrument`), primary units (`client`), and relationship logs (`subscription_history`, `client_instrument`, `model_instrument`).

### 2. Automated Regression Suite (`/test`)
To maintain complete deployment integrity across environmental state updates, a strict testing harness is bundled within the system:
* **`test/01-constraints-test.sql`:** Deliberately maps out bad data entries to verify check constraint enforcement.
* **`test/run-tests.sh`:** A location-independent executable wrapper script executing on the runtime host, verifying a 100% green pass criterion across all validation scenarios before codebase modifications are merged.