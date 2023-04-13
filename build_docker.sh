#!/bin/bash
# Build
set +e

echo "[build_docker - $(date)] Started"

export DOCKER_REPO_NAME="docker-cron-example"
export CONTAINER_RUNTIME_NAME="$DOCKER_REPO_NAME-runtime"

## shellcheck ./*.sh
# pycodestyle ./*.py
# hadolint Dockerfile

# stop and kill any related containers
docker stop "$CONTAINER_RUNTIME_NAME" && docker rm $_  &> /dev/null
docker container prune --force &> /dev/null

# remove old unused images

docker rmi $(docker images "$DOCKER_REPO_NAME" -a -q)  &> /dev/null
docker rmi $(docker images -f "dangling=true" -q) &> /dev/null


# build it
set -e
docker build -t "$DOCKER_REPO_NAME" .

docker run "$DOCKER_REPO_NAME"

set +e
docker container prune --force &> /dev/null
docker images clean --quiet &> /dev/null
docker builder prune --all --force &> /dev/null

echo "[build_docker - $(date)] Finished successfully"
