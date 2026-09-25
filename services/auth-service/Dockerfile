# Use the official stable Python 3.14 Alpine footprint to maximize platform modernization
FROM python:3.14-alpine

WORKDIR /app

# Install native system build utilities
RUN apk add --no-cache bash

# Copy and install python library dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy our active microservice application code
COPY auth_service.py .

EXPOSE 4000

# Run the application unbuffered to stream logs directly to the docker console
CMD ["python", "-u", "auth_service.py"]
