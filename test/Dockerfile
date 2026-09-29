FROM alpine:3.19

# 🔐 Pre-bake all heavy system dependencies into the immutable image layer
RUN apk add --no-cache \
    bash \
    python3 \
    py3-requests \
    py3-pip \
    py3-setuptools \
    netcat-openbsd \
    postgresql16-client

WORKDIR /test

ENTRYPOINT ["/test/run-tests.sh"]
