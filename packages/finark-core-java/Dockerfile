# syntax=docker/dockerfile:1
# ============================================================================
# FINARK CORE PLATFORM CHASSIS SDK - JAVA MULTI-STAGE ENGINE COMPILER
# Target File: packages/finark-core-java/Dockerfile
# BRS Mapping: BR-14 Isolated Cross-Language Compilation Gates
# ============================================================================

# STAGE 1: THE EPHEMERAL MAVEN COMPILATION BUILDER
FROM maven:3.9.9-eclipse-temurin-25-alpine AS sdk_builder

WORKDIR /build

# Mount an anonymous container cache volume to prevent polluting host storage arrays
RUN --mount=type=cache,target=/root/.m2 \
    --mount=type=bind,source=pom.xml,target=pom.xml \
    mvn dependency:go-offline -B

# Copy the aligned Java 25 source files and test suites into the build container
COPY src/ ./src/
COPY pom.xml ./

# Execute the complete compilation tree pass and fire the JUnit 5 test matrix
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -B

# STAGE 2: THE HARDENED PRODUCTION ARTIFACT CONTAINER
FROM alpine:3.19

WORKDIR /app

# Inherit ONLY the final, pre-compiled compiled .jar binary from Stage 1
COPY --from=sdk_builder /build/target/*.jar ./finark-core-java.jar

CMD ["echo", "FinArk Java Core SDK Component Compiled Successfully"]
