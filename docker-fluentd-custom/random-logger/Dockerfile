FROM ubuntu:latest

RUN mkdir /app
COPY random_logger.sh /app

RUN apt-get update
RUN apt-get install -y openssl

ENTRYPOINT ["bash", "/app/random_logger.sh"]
