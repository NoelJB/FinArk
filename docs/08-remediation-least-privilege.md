# FinArk Security Remediation: Role-Based Access Control & Least Privilege Hardening

## 🧠 The Architectural Solution: Application Layer Sandbox
To completely eliminate Finding 02 (Excessive Application Role Privileges) from the platform runtime environment, FinArk transitions away from letting external automation services connect to the relational engine via the master 'postgres' superuser administrative account. 

Instead, the platform implements a strict model of Role-Based Access Control (RBAC) to enforce the Principle of Least Privilege at the database layer.

---

## 🏗️ How the Privilege Boundary Works

1. User and Schema Isolation
Inside db/07-outbox-infrastructure.sql, we declare a dedicated, non-superuser role specifically named paysprint_app. 

To ensure a defensive configuration, the script completely strips away all default permissions inherited from the public database schema using an explicit truncation query:
REVOKE ALL ON SCHEMA public FROM paysprint_app;

This means the application role initializes as a blank canvas—it is locked completely out of viewing, inserting, or modifying any tables or data records within the entire system by default. Even if an attacker gains control of this user account, they cannot view customer balances, read advisor details, or alter system setups.

2. Strict Least Privilege Allocation
To allow our external background scripts (like the Python event poller) to process events safely, we carve out a hyper-targeted data pipeline window:
* CONNECT & USAGE: The role is granted entry to route onto the paysprint cluster network.
* SELECT & UPDATE: The user is exclusively authorized to query pending records and toggle execution flags (status = 'SENT' or 'FAILED') strictly within the outbox table alone.
* SEQUENCE USAGE: The account is granted permission to mutate the outbox identity counters to prevent execution crashes during high-throughput ingestion.

---

## 🛡️ Operational Impact Against Application Exploits
By isolating the external application worker into this hardened database layer sandbox, we completely decouple our core relational financial ledger from the network-facing consumer application layer:

* Attack Containment: If a major Remote Code Execution (RCE) flaw is exploited inside the Python runtime container or its third-party package dependencies, the intruder inherits only the permissions of the paysprint_app user.
* Zero Horizontal Data Exposure: The attacker remains trapped entirely inside the polymorphic outbox log. They cannot drop tables, extract sensitive client personal information, or access core banking transaction registries, satisfying modern fintech corporate compliance audits.
