# syntax=docker/dockerfile:1
# ============================================================================
# FINARK PLATFORM - EDGE MICROGATEWAY MULTI-STAGE ENGINE BUILDER
# Target File: services/api-gateway/Dockerfile | BRS Mapping: BR-05 Core
# ============================================================================

# ----------------------------------------------------------------------------
# STAGE 1: THE EPHEMERAL COMPILATION ENGINE
# ----------------------------------------------------------------------------
FROM node:24-alpine AS gateway_builder

WORKDIR /build

COPY package.json ./
RUN npm install

COPY tsconfig.json ./
COPY src/ ./src/

# Compile clean ECMAScript production bundles
RUN npm run build && npm prune --production

# ----------------------------------------------------------------------------
# STAGE 2: THE HARDENED PRODUCTION RUNTIME
# ----------------------------------------------------------------------------
FROM node:24-alpine

WORKDIR /app

# Provision netcat to support native edge container healthcheck sweeps
RUN apk add --no-cache netcat-openbsd bash

# Inherit only the compiled source bundles and production wheels from stage 1
COPY --from=gateway_builder /build/node_modules ./node_modules
COPY --from=gateway_builder /build/dist ./dist
COPY --from=gateway_builder /build/package.json ./

EXPOSE 3000

CMD ["node", "dist/main.js"]
