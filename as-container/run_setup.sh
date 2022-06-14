#!/bin/bash

# Set credentials
NEWRELIC_LICENSE_KEY="YOUR NEW RELIC LICENSE KEY"
LOGGING_ENDPOINT="https://log-api.eu.newrelic.com/log/v1"
FLUENTD_LOGGING_LEVEL="info" # values: fatal, error, warn, info, debug, trace.

# Install Docker
sudo apt-get update
echo Y | sudo apt-get upgrade

sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update

echo Y |sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
echo Y | sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start New Relic infra agent
sudo docker run \
  --restart=always \
  -d \
  --name "newrelic-infra-agent" \
  --network=host \
  --cap-add=SYS_PTRACE \
  -v "/:/host:ro" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -e NRIA_LICENSE_KEY=$NEWRELIC_LICENSE_KEY \
  newrelic/infrastructure:latest

# Start New Relic logging agent
sudo docker run \
  --restart=always \
  -d \
  --name="newrelic-logging-agent" \
  -p 24224:24224 \
  -e "API_KEY=$NEWRELIC_LICENSE_KEY" \
  -e "BASE_URI=$LOGGING_ENDPOINT" \
  -e "LOG_LEVEL=$FLUENTD_LOGGING_LEVEL" \
  newrelic/newrelic-fluentd-docker:latest

# Create directory for random logger
sudo mkdir random-logger

# Create Dockerfile
echo 'FROM ubuntu:latest

RUN mkdir /app
COPY random_logger.sh /app

RUN apt-get update
RUN apt-get install -y openssl

ENTRYPOINT ["bash", "/app/random_logger.sh"]' \
> random-logger/Dockerfile

# Create logger script
echo '#!/bin/bash

while true
do
  openssl rand -base64 16
  sleep 2
done' \
> random-logger/random_logger.sh

# Build random logger image
sudo docker build \
  --tag "random-logger" ./random-logger

# Start random logger
sudo docker run \
  -d \
  --name "random-logger" \
  --log-driver="fluentd" \
  --log-opt "fluentd-address=localhost:24224" \
  "random-logger"
