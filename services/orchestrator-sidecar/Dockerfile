# syntax=docker/dockerfile:1
# ============================================================================
# FINARK PLATFORM - BACKGROUND ORCHESTRATOR SIDECAR MULTI-STAGE COMPILER
# Target File: services/orchestrator-sidecar/Dockerfile
# BRS Mapping: BR-16 Hardened Multi-Paradigm Toolchain Architecture
# ============================================================================

# ----------------------------------------------------------------------------
# STAGE 1: THE EPHEMERAL COMPILATION BUILDER
# ----------------------------------------------------------------------------
FROM python:3.14-alpine AS builder

WORKDIR /build

# Provision complete native development toolchains required to compile asyncpg C extensions
RUN apk add --no-cache gcc musl-dev postgresql-dev libffi-dev zlib-dev

# Execute an inline installation pass targeting the absolute cumulative requirements pool.
# We direct pip to target a standalone, isolated home path directory (--user) inside volatile RAM memory.
RUN pip install --no-cache-dir --user requests valkey pg8000 asyncpg aiokafka

# ----------------------------------------------------------------------------
# STAGE 2: THE HARDENED PRODUCTION RUNTIME
# ----------------------------------------------------------------------------
FROM python:3.14-alpine

WORKDIR /app

# Provision netcat and the bare minimum runtime shared client library (libpq) required by Postgres clients
RUN apk add --no-cache bash netcat-openbsd libpq

# 🪐 THE TRANSITIVE TRUST PROPAGATION INVARIANT
# Inherit EXCLUSIVELY the final pre-compiled static wheels and libraries from Stage 1
COPY --from=builder /root/.local /root/.local

# Update system environments to expose our localized python wheel execution paths natively
ENV PATH=/root/.local/bin:$PATH

# Copy our priority-queue engine and task modules cleanly into the workspace
COPY TimerManager.py .
COPY main.py .
COPY tasks/ ./tasks/

ENTRYPOINT ["python3", "main.py"]
