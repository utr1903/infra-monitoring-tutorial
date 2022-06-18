#!/bin/bash

# Build New Relic logging image
docker build \
  --platform linux/arm64 \
  --tag "newrelic-logging-agent" ./newrelic-logging-agent

# Start New Relic logging agent
docker run \
  -d \
  --name "newrelic-logging-agent" \
  "newrelic-logging-agent"

# Build random logger image
sudo docker build \
  --platform linux/arm64 \
  --tag "random-logger" ./random-logger

# Start random logger
sudo docker run \
  -d \
  --name "random-logger" \
  --log-driver="fluentd" \
  --log-opt "fluentd-address=localhost:24224" \
  "random-logger"