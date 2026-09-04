# FinArk Security Audit: Relational Layer Vulnerability Report

## 📋 Audit Overview
A comprehensive vulnerability assessment was executed against the baseline architecture of the FinArk sandbox platform. The assessment evaluated table design, configuration schemas, testing scripts, and container deployment wrappers. The objective was to verify alignment with the OWASP Top 10 Enterprise Framework and standard banking data security guidelines.

The audit uncovered three distinct compliance and operational vulnerabilities. This report formally defines each finding, maps its strategic impact, and logs the technical risk vectors to establish the educational baseline for our remediation sprint.

---

## 🔍 Finding 01: Plain-Text Master Credential Exposure
* Classification: Critical Cryptographic Failure (OWASP A02:2021)
* Target Assets: root/docker-compose.yaml, test/run-tests.sh

### 1. Technical Vulnerability Definition
The database master superuser access credential was permanently hardcoded as a plain-text string ("POSTGRES_PASSWORD: n3u3d4!") inside the core orchestration file and duplicate shell execution variables. 

### 2. Operational Threat Vector
If this codebase configuration is committed and pushed to a public or shared Git repository network, the access keys are exposed to automated text scrapers. Malicious entities continuously crawl repository logs for recognizable variable strings. Exposure of the root administrator string grants full ownership of the data tier to any actor on the network, leading to catastrophic database manipulation or total extortion events.

---

## 🔍 Finding 02: Excessive Application Role Privileges
* Classification: High Security Misconfiguration (OWASP A05:2021)
* Target Assets: db/01-schema.sql, Custom Python Background Workers

### 1. Technical Vulnerability Definition
The platform context was designed to let external data consumer workers (like the background Python outbox polling script) log directly into the PostgreSQL engine using the root 'postgres' superuser administrative account. 

### 2. Operational Threat Vector
This violates the core Principle of Least Privilege. Background scripts only require narrow access to check and update outbound event log queues. If a Remote Code Execution (RCE) vulnerability is discovered within the Python consumer script or its third-party package dependencies, an intruder instantly inherits full database superuser rights. The attacker can then bypass all isolation walls, drop primary tables, extract customer profiles, or execute shell commands on the host machine using PostgreSQL system commands.

---

## 🔍 Finding 03: Lack of Input Parameter Boundary Protection
* Classification: Medium Injection Vulnerability (OWASP A03:2021)
* Target Assets: Conceptual Application Integration Layer

### 1. Technical Vulnerability Definition
The application connection guidelines lacks formal interface constraints blocking raw data string concatenation when inserting variables (such as client names or instrument updates) into dynamic queries.

### 2. Operational Threat Vector
If user input strings from front-end applications are directly joined onto SQL query structures without parameterized binding, the interface is completely exposed to SQL Injection. An attacker can craft a payload containing characters like quotes and semicolons (e.g., "Alice'; DROP TABLE client; --") to trick the relational parser into executing destructive database commands, resulting in severe data loss or total account takeover.
