# syntax=docker/dockerfile:1
# ============================================================================
# FINARK CORE TESTING RUNTIME FRAMEWORK - MULTI-STAGE PLATFORM HARNESS
# Target File: test/Dockerfile
# ============================================================================
FROM python:3.12-alpine3.20 AS base-harness

WORKDIR /test

# Retain ALL legacy system network tools and compilation extensions
RUN apk add --no-cache \
    bash \
    curl \
    netcat-openbsd \
    gcc \
    musl-dev \
    postgresql-dev \
    postgresql-client \
    make \
    g++

# Pre-compile third-party wheels directly into the image layer
RUN pip install --no-cache-dir --break-system-packages pyjwt requests pg8000 scramp valkey

# ----------------------------------------------------------------------------
# Stage 2: THE TARGET FOR THE STATIC COLD DB UNIT SUITE
# ----------------------------------------------------------------------------
FROM base-harness AS runner-db
ENTRYPOINT ["/bin/bash", "/test/run-db-tests.sh"]

# ----------------------------------------------------------------------------
# Stage 3: THE TARGET FOR THE STATEFUL LIVE API INTEGRATION SUITE
# ----------------------------------------------------------------------------
FROM base-harness AS runner-api
ENV PYTHONPATH="/packages/finark-core:/test/api:${PYTHONPATH}"
ENTRYPOINT ["/bin/bash", "/test/run-api-tests.sh"]
