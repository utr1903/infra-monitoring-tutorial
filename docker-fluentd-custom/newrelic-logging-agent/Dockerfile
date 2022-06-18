FROM fluent/fluentd:v1.9.2-1.0

ARG licenseKey
ARG logLevel
ARG baseUri

ENV API_KEY=$licenseKey
ENV LOG_LEVEL=$logLevel
ENV BASE_URI=$baseUri

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
