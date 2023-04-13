#!/bin/bash
# Build, run, and attach to Dockerfile in current directory
set +e


# export DOCKER_REPO_NAME="docker-cron-example"

# set the repo name as the current directory's name
export DOCKER_REPO_NAME=${PWD##*/}

##############################################################################
#		FUNCTION DEFINITIONS
##############################################################################
THIS_SCRIPT_NAME="build_docker"

friendlier_date () {
	date +"%Y-%m-%d %I:%M:%S %p %Z"
}

log () {
    echo -e "[$THIS_SCRIPT_NAME] $(friendlier_date)\t $*"
}

##############################################################################
#		MAIN
##############################################################################
log "Start of script for image $DOCKER_REPO_NAME"
export CONTAINER_RUNTIME_NAME="$DOCKER_REPO_NAME-runtime"

log "Checking syntax/lint issues before proceeding..."
set -e
shellcheck --severity=error ./*.sh
pycodestyle ./*.py
hadolint   --failure-threshold=warning Dockerfile
log "Successfully passed syntax/lint checks..."

# exit 1

# stop and kill any related containers
log "Removing old versions..."
docker stop "$CONTAINER_RUNTIME_NAME" && docker rm $_  &> /dev/null
docker container prune --force &> /dev/null
docker rmi $(docker images "$DOCKER_REPO_NAME" -a -q)  &> /dev/null
docker rmi $(docker images -f "dangling=true" -q) &> /dev/null
log "Finished removing old versions."

# build it
set -e
log "Starting build..."
docker build -t "$DOCKER_REPO_NAME" .
log "Build finished successfully."

# start it
set -e
log "Starting image $DOCKER_REPO_NAME as detached..."
NEW_CONTAINER_ID=$(docker run -d --name "$CONTAINER_RUNTIME_NAME" -t "$DOCKER_REPO_NAME")

# list running containers
log "Listing running containers..."
docker ps

# SEPARATELY attach to it
# don't use attach command in this particular case
log "Attaching to $CONTAINER_RUNTIME_NAME with ID = $NEW_CONTAINER_ID"
set -e
docker exec -it "$NEW_CONTAINER_ID" /bin/bash
log "Exited running container $CONTAINER_RUNTIME_NAME"

# clean up various temp files that could screw up next run
log "Cleaning up containers and images..."
set +e
docker container prune --force &> /dev/null
docker images clean --quiet &> /dev/null
docker builder prune --all --force &> /dev/null

log "$THIS_SCRIPT_NAME finished successfully!"
