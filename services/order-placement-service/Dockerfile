# syntax=docker/dockerfile:1
# ============================================================================
# FINARK PLATFORM - ORDER PLACEMENT ENGINE DYNAMIC COMPILER BLUEPRINT
# Target File: services/order-placement-service/Dockerfile
# BRS Mapping: BR-14 High-Performance Containerization
# ============================================================================

# STAGE 1: THE EPHEMERAL JAVA 25 COMPILER BUILDER
FROM eclipse-temurin:25-jdk-alpine AS code_builder

WORKDIR /build

# Provision Maven dynamically into the native Java 25 Alpine workspace
RUN apk add --no-cache maven bash

# BuildKit Dependency Link: Mount the shared Java Core Chassis SDK source code context
WORKDIR /build-sdk
COPY --from=finark_core_java_src . .

# Compile and local-install the shared Chassis SDK into the container's private local repository cache
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean install -DskipTests -B

# Shift focus back to the hot trading microservice workspace
WORKDIR /build-app

# Copy the POM file first to establish a separate dependency layer cache
COPY pom.xml ./

# Force Maven to pre-fetch test dependencies AND test plugins offline using the shared cache
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline de.qaware.maven:go-offline-maven-plugin:resolve-dependencies -B

# Copy remaining project source code structures
COPY src/ ./src

# Execute complete compilation pass AND run unit/integration tests natively using the shared cache
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -B

# STAGE 2: THE HARDENED IMMUTABLE JRE 25 PRODUCTION RUNTIME
FROM eclipse-temurin:25-jre-alpine

WORKDIR /app

RUN apk add --no-cache bash netcat-openbsd

# Inherit the validated microservice jar from the compilation builder stage
COPY --from=code_builder /build-app/target/*.jar ./order-placement-service.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "order-placement-service.jar"]
