#!/bin/bash

# Tag name
BASE_TAG='gitlab-registry.cern.ch/sciencebox/docker-images/cvmfs'
REGISTRY_URL='gitlab-registry.cern.ch'

# Specify cvmfs version to be installed (or comment out to use the latest)
CVMFS_VERSION='2.11.2'

# Build the Docker image
if [ -z $CVMFS_VERSION ]; then
  TAG="$BASE_TAG:latest"
  docker build -t $TAG .
else
  TAG="$BASE_TAG:$CVMFS_VERSION"
  docker build --build-arg CVMFS_VERSION=-$CVMFS_VERSION -t $TAG .
fi

# Push the image to the GitLab registry
if [ $? -eq 0 ]; then
  echo
  echo
  echo "Pushing image $TAG to $REGISTRY_URL"
  docker login $REGISTRY_URL
  docker push $TAG
fi
