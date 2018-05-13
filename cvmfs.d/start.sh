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

    echo "Checking to have a clean environment (mountpoints and folders)..."
    mounted_folders=`mount -l | grep "${CVMFS_FOLDER}/" | cut -d ' ' -f 3 | tr '\n' ' '`
    if [[ -z $mounted_folders ]];
    then
      echo "Nothing to cleanup."
    else
      echo "Cleaning up: $mounted_folders"
      for i in $mounted_folders
      do
        umount $i
        rmdir $i        # It might fail if user's containers are running
      done
    fi
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


# Configure CVMFS Upstream Connection according to the context
case $CVMFS_UPSTREAM_CONNECTION in
  "direct")
    sed "s#%%%CVMFS_HTTP_PROXY%%%#DIRECT#" /root/cvmfs_default.local > /etc/cvmfs/default.local
  ;;

  "squid")
    if [ -z "$CVMFS_SQUID_HOSTNAME" ] || [ -z "$CVMFS_SQUID_PORT" ];
    then
      CVMFS_SQUID_HOSTNAME="cvmfssquid.boxed.svc.cluster.local"
      CVMFS_SQUID_PORT="3128"
      echo "WARNING: Squid proxy hostname or port not defined."
      echo "WARNING: Defaulting to $CVMFS_SQUID_HOSTNAME on port $CVMFS_SQUID_PORT"
    fi
    CVMFS_HTTP_PROXY="http://"$CVMFS_SQUID_HOSTNAME":"$CVMFS_SQUID_PORT
    sed "s#%%%CVMFS_HTTP_PROXY%%%#${CVMFS_HTTP_PROXY}#" /root/cvmfs_default.local > /etc/cvmfs/default.local

    # Make sure the squid proxy is there before proceeding or bail out
    sleep_time=10
    timeout=600
    timer=0
    result=-1
    while [ $result -ne 0 ] && [ $timer -lt $timeout ];
    do
      ncat -4 -z -w 3 $CVMFS_SQUID_HOSTNAME $CVMFS_SQUID_PORT
      result=`echo $?`
      timer=$((timer+sleep_time))
      echo "Waiting for the squid proxy to be available... $timer/$timeout sec"
      sleep $sleep_time
    done
    if [ $timer -eq $timeout ];
    then
      echo "ERROR: Squid proxy unavailable after $timeout sec"
      echo "Cannot continue."
      exit -1
    fi
  ;;

  "cern")
    sed "s#%%%CVMFS_HTTP_PROXY%%%#http://ca-proxy.cern.ch:3128;http://ca-proxy-meyrin.cern.ch:3128;http://ca01.cern.ch:3128|http://ca02.cern.ch:3128|http://ca03.cern.ch:3128|http://ca04.cern.ch:3128|http://ca05.cern.ch:3128|http://ca06.cern.ch:3128#" /root/cvmfs_default.local > /etc/cvmfs/default.local
  ;;

  *)
    echo "WARNING: Connection method to upstram source not defined."
    echo "WARNING: Defaulting to 'direct'"
    sed "s#%%%CVMFS_HTTP_PROXY%%%#DIRECT#" /root/cvmfs_default.local > /etc/cvmfs/default.local
esac

# Define mount points, create directories, and mount the repositories 
echo "Mounting CVMFS repositories..."
echo "#<cvmfs_repo> <mnt_dir> <fs_type> <options> <dump> <fsck>" > /tmp/fstab_temp
for i in `cat /etc/cvmfs/default.local | grep -v '^#' | grep CVMFS_REPOSITORIES | cut -d = -f 2- | tr -d "'" | tr "," " "`; 
do
  echo $i /cvmfs/$i cvmfs defaults,_netdev,nodev 0 0 >> /tmp/fstab_temp
done
cat /tmp/fstab_temp | column -t > /etc/fstab
rm -f /tmp/fstab_temp
mkdir -p `tail -n+2 /etc/fstab | tr -s ' ' | cut -d ' ' -f 2`
mount -a

# Probe the CVMFS endpoints for acknowledgement
echo "Probing CVMFS repositories..."
cvmfs_config probe

# Give control to supercronic to handle prefetching from CVMFS
echo "Starting supercronic to keep the local cache warm..."
/usr/bin/supercronic /etc/supercronic.d/cvmfs_prefetch.cronjob

