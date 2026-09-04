# FinArk Security Remediation: Infrastructure Hardening via Docker Secrets

## 🧠 The Architectural Solution: In-Memory Container Vaults
To completely eliminate Finding 01 (Plain-Text Master Credential Exposure) from the repository, the FinArk Platform transitioned to an automated production-grade orchestration framework leveraging native Docker Secrets. 

Instead of passing passwords via environment variables—which can easily leak into system process tables, crash logs, or third-party monitoring agents—we use secure file-based injection.

---

## 🏗️ How the Architecture Works

1. In-Memory Decoupling
Inside root/docker-compose.yaml, all plain-text password strings are entirely scrubbed. We use the POSTGRES_PASSWORD_FILE environment hook, pointing it directly to the protected container path:
/run/secrets/pg_master_pass

When the stack initializes, the Docker Engine creates a temporary, virtual, highly secure file system mount inside the container's private runtime space. The password text is exposed exclusively to the internal PostgreSQL daemon process and lives strictly within volatile RAM memory. It is never written to the container disk layer, and it disappears completely the moment the container spins down.

2. Turnkey Bootstrap Orchestration (run-demo.sh)
To ensure the sandbox remains completely turnkey for students while enforcing unique cryptographic keys on every developer instance, stack lifecycle control is automated via run-demo.sh:

* Vault Staging: The script dynamically handles generating a local secrets/ folder on the host machine before kicking off Docker.
* Git Protection: The secrets/ folder is explicitly written to the root .gitignore rules, locking local developer keys entirely out of version control arrays.
* Cryptographic Key Rotation: If an instance key file is missing, the bootstrap engine auto-generates a unique token using host cryptographic libraries:
  openssl rand -base64 16 | tr -d '\n' > secrets/pg_master_pass.txt
  The file is instantly locked down on the host system using strict chmod 600 read-only file access permissions.

3. Zero-Leak Automation Testing (test/run-test-container.sh)
The host testing wrapper reads the unique, dynamically generated instance token text off the host disk and securely passes it into the ephemeral test container environment using isolated runtime variables (-e PGPASSWORD). The dynamic test runner (test/run-tests.sh) safely inherits this string to connect and run queries against the active database without storing hardcoded credential blocks anywhere in the file tree.
