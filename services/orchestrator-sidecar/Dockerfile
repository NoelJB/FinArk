# syntax=docker/dockerfile:1
# ============================================================================
# FINARK PLATFORM - BACKGROUND ORCHESTRATOR SIDECAR ENVIRONMENT BLUEPRINT
# Target File: services/orchestrator-sidecar/Dockerfile
# BRS Mapping: BR-16 Long-Running Multi-Task Thread Orchestration
# ============================================================================

FROM python:3.14-alpine

WORKDIR /app

# Provision netcat to support core cluster container network handshake validations
RUN apk add --no-cache bash netcat-openbsd

# Provision type-safe database, cache, and network packages cleanly inside the JRE layer
RUN pip install --no-cache-dir --break-system-packages requests valkey pg8000

# Copy our priority-queue engine and task modules cleanly into the workspace
COPY TimerManager.py .
COPY main.py .
COPY tasks/ ./tasks/

ENTRYPOINT ["python3", "main.py"]
