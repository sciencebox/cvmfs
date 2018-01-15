#!/bin/bash
#set -o errexit	# Bail out on all errors immediately

echo "---${THIS_CONTAINER}---"

case $DEPLOYMENT_TYPE in
  "kubernetes")
    # Print PodInfo
    echo ""
    echo "%%%--- PodInfo ---%%%"
    echo "Pod namespace: ${PODINFO_NAMESPACE}"
    echo "Pod name: ${PODINFO_NAME}"
    echo "Pod IP: ${PODINFO_IP}"
    echo "Node name (of the host where the pod is running): ${PODINFO_NODE_NAME}" 
    echo "Node IP (of the host where the pod is running): ${PODINFO_NODE_IP}"
  
    echo "Deploying with configuration for Kubernetes..."
    ;;
  ###
  "compose")
    echo "Deploying with configuration for Docker Compose..."
    ;;

  *)
    echo "ERROR: Deployment context is not defined."
    echo "Cannot continue."
    exit -1
esac

# Configure local Squid proxy
echo "Initializing Squid proxy..."
ulimit -n 8192
cat /root/squid.conf_cvmfs >> /etc/squid/squid.conf
squid -z	# Init the cache space on disk
sleep 3

# Start squid proxy
echo "Starting squid..." 
/usr/bin/supervisord -c /etc/supervisord.conf

