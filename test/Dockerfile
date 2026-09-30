# syntax=docker/dockerfile:1
# ============================================================================
# FINARK PLATFORM - AUTOMATED REGRESSION HARNESS ENVIRONMENT BluePrint
# Target File: test/Dockerfile | BRS Mapping: BR-14 Unified DevOps Engine
# ============================================================================

FROM alpine:3.19

# 🔐 Hardened: Bundled Node.js & npm natively to support Phase 3 edge gateway validations
RUN apk add --no-cache \
    bash \
    python3 \
    py3-requests \
    py3-pip \
    py3-setuptools \
    netcat-openbsd \
    postgresql16-client \
    nodejs \
    npm

WORKDIR /test

ENTRYPOINT ["/test/run-tests.sh"]
