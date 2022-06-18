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

# Create directory for New Relic
mkdir newrelic

# New Relic logging Dockerfile
echo 'FROM fluent/fluentd:v1.9.2-1.0

ARG licenseKey
ARG baseUri
ARG logLevel

ENV API_KEY=$licenseKey
ENV BASE_URI=$baseUri
ENV LOG_LEVEL=$logLevel

USER root

RUN apk add --no-cache --update --virtual .build-deps \
  sudo build-base ruby-dev \
 && sudo fluent-gem install fluent-plugin-newrelic \
 && sudo gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /home/fluent/.gem/ruby/*/cache/*.gem

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/
RUN chmod +x /bin/entrypoint.sh

USER fluent
' > ./newrelic/Dockerfile

# New Relic fluentd config
echo '<system>
  log_level "#{ENV['LOG_LEVEL']}"
</system> 

 <source>
   @type forward
   port 24224
   bind 0.0.0.0
</source>

<label @FLUENT_LOG>
  <filter fluent.*>
    @type record_transformer
    <record>
      fluentd_host "#{Socket.gethostname}"
      env "dev"
      attr1 "attr1"
      attr2 "attr2"
      attr3 "attr3"
    </record>
  </filter>
  <match fluent.*>
   @type newrelic
   api_key "#{ENV['API_KEY']}"
   base_uri "#{ENV['BASE_URI']}"
  </match>
</label>

 <match **>
   @type newrelic
   api_key "#{ENV['API_KEY']}"
   base_uri "#{ENV['BASE_URI']}"
</match>' > ./newrelic/fluent.conf

# New Relic entrypoint.sh
echo '#!/bin/sh

#source vars if file exists
DEFAULT=/etc/default/fluentd

if [ -r $DEFAULT ]; then
    set -o allexport
    . $DEFAULT
    set +o allexport
fi

# If the user has supplied only arguments append them to `fluentd` command
if [ "${1#-}" != "$1" ]; then
    set -- fluentd "$@"
fi

# If user does not supply config file or plugins, use the default
if [ "$1" = "fluentd" ]; then
    if ! echo $@ | grep '"' \-c'"' ; then
       set -- "$@" -c /fluentd/etc/${FLUENTD_CONF}
    fi

    if ! echo $@ | grep '"' \-p'"' ; then
       set -- "$@" -p /fluentd/plugins
    fi
fi

exec "$@"' > ./newrelic/entrypoint.sh

# Build New Relic logging image
# sudo docker build \
#   --tag "newrelic-logging-agent" ./newrelic

sudo docker build \
  --build-arg licenseKey=$NEWRELIC_LICENSE_KEY \
  --build-arg baseUri=$LOGGING_ENDPOINT \
  --build-arg logLevel=$FLUENTD_LOGGING_LEVEL \
  --tag "newrelic-logging-agent" ./newrelic

# Start New Relic logging agent
sudo docker run \
  -d \
  --name "newrelic-logging-agent" \
  -p 24224:24224 \
  "newrelic-logging-agent"

# Create directory for random logger
mkdir random-logger

# Create Dockerfile
echo 'FROM ubuntu:latest

RUN mkdir /app
COPY random_logger.sh /app

RUN apt-get update
RUN apt-get install -y openssl
c
ENTRYPOINT ["bash", "/app/random_logger.sh"]' \
> ./random-logger/Dockerfile

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

