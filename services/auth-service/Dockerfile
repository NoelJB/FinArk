# syntax=docker/dockerfile:1
FROM python:3.14-alpine

WORKDIR /app

# 🔐 Hardened: Provision netcat to support native Docker daemon healthcheck commands
RUN apk add --no-cache bash netcat-openbsd

# 1. Copy the requirements file first to build a stable baseline
COPY requirements.txt .

# 2. Copy ONLY the setup configuration metadata to define package bounds
COPY --from=finark_core_src setup.py /packages/finark-core/setup.py

# 3. Compile and lock down your third-party dependency wheel layer
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt

# 4. Copy the changing library source code LATER in the layering sequence
COPY --from=finark_core_src finark_core/ /packages/finark-core/finark_core/

# 5. Copy your local web server logic
COPY auth_service.py .

EXPOSE 4000

ENTRYPOINT ["python3", "auth_service.py"]
