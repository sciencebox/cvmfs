#!/bin/bash

# Tag name
BASE_TAG='gitlab-registry.cern.ch/sciencebox/docker-images/cvmfs'

# Specify cvmfs version to be installed (or comment out to use the latest)
CVMFS_VERSION='2.8.0'

# Build the Docker image
if [ -z $CVMFS_VERSION ]; then
  TAG="$BASE_TAG:latest"
  docker build -t $TAG .
else
  TAG="$BASE_TAG:$CVMFS_VERSION"
  docker build --build-arg CVMFS_VERSION=-$CVMFS_VERSION -t $TAG .
fi

# Push the image to the GitLab registry
docker login gitlab-registry.cern.ch
docker push $TAG

