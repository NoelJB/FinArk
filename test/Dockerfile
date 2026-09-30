# syntax=docker/dockerfile:1
# ============================================================================
# FINARK PLATFORM - AUTOMATED REGRESSION HARNESS ENVIRONMENT BLUEPRINT
# Target File: test/Dockerfile | BRS Mapping: BR-14 Unified DevOps Engine
# ============================================================================

# ☕ Hardened: Locked strictly to the official Eclipse Temurin Java 25 LTS alpine container base
FROM eclipse-temurin:25-jdk-alpine

# 🔐 Hardened: Provision complete native compiler engines for Node, Python, and Maven
RUN apk add --no-cache \
    bash \
    python3 \
    py3-requests \
    py3-pip \
    py3-setuptools \
    netcat-openbsd \
    postgresql16-client \
    nodejs \
    npm \
    maven

WORKDIR /test

ENTRYPOINT ["/test/run-tests.sh"]
