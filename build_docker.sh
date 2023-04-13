#!/bin/bash
# Build
set -e

## shellcheck ./*.sh
# pycodestyle ./*.py
# hadolint Dockerfile

# set +e
# docker image purge cron-example
# set -e

docker build -t cron-example .

docker run cron-example
