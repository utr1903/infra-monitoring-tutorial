# New Relic Infra & Logging Agents

## Intro

This setup creates a simple environment to showcase _"How to monitor a Debian host (e.g. Ubuntu 18.04 LTS) with the New Relic infra and logging agents deployed as Docker containers"_.

## Setup

The script `run_setup.sh` is to be run on the host which is supposed to be monitored. It can also be run as VM initializer (a.k.a. _user-data_).

### Script steps
1. Installs Docker onto host machine.
2. Runs New Relic infra agent within a Docker container.
3. Runs New Relic logging agent within a Docker container.
4. Creates the Dockerfile for the random logger application.
5. Creates the script for the random logger application.
6. Builds & runs the random logger application.

## Result

* The infra agent finds out all of the Docker containers running on the host machine and scrapes not only the host but also the container metrics.
* The logging agent has a built in fluentd. It forwards all of the logs created by the random logger application to New Relic.

## Remarks

* Within the New Relic host UI, the Logs tab will not show any logs since the infra agent is currently not fetching the logs automatically in case it is deployed within a Docker container. That's why the logging agent is deployed on top of it. The logs are to be seen per Query Explorer: `FROM Log SELECT *`.

* In order for the logging agent to forward the logs to New Relic, the application containers should send their logs to fluentd host (flags: `--log-driver="fluentd" --log-opt "fluentd-address=localhost:24224"`).
