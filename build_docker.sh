#!/bin/bash
# Build, run, and attach to Dockerfile in current directory
set +e

# set the repo name as the current directory's name
export DOCKER_REPO_NAME=${PWD##*/}

##############################################################################
#		FUNCTION DEFINITIONS
##############################################################################
# OSX and Linux friendly version, but it keeps the filename suffix
THIS_SCRIPT_NAME="$(basename $0)"
log () {
    echo -e "[$THIS_SCRIPT_NAME] $(date +"%Y-%m-%d %I:%M:%S %p %Z")\t $*"
}

##############################################################################
#		MAIN
##############################################################################
log "Start of script for image $DOCKER_REPO_NAME"
export CONTAINER_RUNTIME_NAME="$DOCKER_REPO_NAME-runtime"

set -e
log "Checking syntax/lint issues before proceeding..."
shellcheck --severity=error ./*.sh
pycodestyle ./*.py
# ignore APT version specification
hadolint   --failure-threshold=warning --ignore DL3008 Dockerfile
log "Successfully passed syntax/lint checks..."

# stop and kill any related containers
set +e
log "Removing old versions..."
docker stop "$CONTAINER_RUNTIME_NAME" && docker rm $_  &> /dev/null
docker container prune --force &> /dev/null
docker rmi $(docker images "$DOCKER_REPO_NAME" -a -q)  &> /dev/null
docker rmi $(docker images -f "dangling=true" -q) &> /dev/null
log "Finished removing old versions."

# build the image
set -e
log "Starting build..."
docker build -t "$DOCKER_REPO_NAME" .
log "Build finished successfully."

# start the image as new container
set -e
log "Starting image $DOCKER_REPO_NAME as detached..."
NEW_CONTAINER_ID=$(docker run -d --name "$CONTAINER_RUNTIME_NAME" -t "$DOCKER_REPO_NAME")

# list running containers
# set -e
# log "Listing running containers..."
# docker ps

# SEPARATELY attach to running container
# this fixes an issue where if you try to launch it and attach at the same time
# that it will kill the CMD in the Dockerfile, which kills the cron.
# don't use attach command in this particular case
set -e
log "Attaching to $CONTAINER_RUNTIME_NAME with ID = $NEW_CONTAINER_ID"
docker exec -it "$NEW_CONTAINER_ID" /bin/bash
log "Exited running container $CONTAINER_RUNTIME_NAME"

# clean up various temp files that could screw up next run
set +e
log "Cleaning up containers and images..."
docker container prune --force &> /dev/null
docker images clean --quiet &> /dev/null
docker builder prune --all --force &> /dev/null


log "$THIS_SCRIPT_NAME finished successfully!"
