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
  ###
  "squid")
    if [ -z "$CVMFS_SQUID_ENDPOINT" ]; then
      CVMFS_SQUID_ENDPOINT="http://cvmfssquid.boxed.svc.cluster.local:3128"
      echo "WARNING: Squid proxy URL not defined."
      echo "WARNING: Defaulting to $CVMFS_SQUID_ENDPOINT"
    fi
    sed "s#%%%CVMFS_HTTP_PROXY%%%#${CVMFS_SQUID_ENDPOINT}#" /root/cvmfs_default.local > /etc/cvmfs/default.local
  ;;
  ###
  "cern")
    sed "s#%%%CVMFS_HTTP_PROXY%%%#http://ca-proxy.cern.ch:3128;http://ca-proxy-meyrin.cern.ch:3128;http://ca01.cern.ch:3128|http://ca02.cern.ch:3128|http://ca03.cern.ch:3128|http://ca04.cern.ch:3128|http://ca05.cern.ch:3128|http://ca06.cern.ch:3128#" /root/cvmfs_default.local > /etc/cvmfs/default.local
  ;;
  ###
  *)
    echo "WARNING: Connection method to upstram source not defined."
    echo "WARNING: Defaulting to 'direct'"
    sed "s#%%%CVMFS_HTTP_PROXY%%%#DIRECT#" /root/cvmfs_default.local > /etc/cvmfs/default.local
esac

# Define mount points according to the list of desired repositories
echo "Mounting CVMFS repositories..."
echo "#<cvmfs_repo> <mnt_dir> <fs_type> <options> <dump> <fsck>" > /tmp/fstab_temp
for i in `cat /etc/cvmfs/default.local | grep -v '^#' | grep CVMFS_REPOSITORIES | cut -d = -f 2- | tr -d "'" | tr "," " "`; 
do
	echo $i /cvmfs/$i cvmfs defaults,_netdev,nodev 0 0 >> /tmp/fstab_temp
done
cat /tmp/fstab_temp | column -t > /etc/fstab
/bin/rm /tmp/fstab_temp

# Make the directories required for the CVMFS mount
mkdir -p `tail -n+2 /etc/fstab | tr -s ' ' | cut -d ' ' -f 2`

# Mount CVMFS repositories and set the mount points as shared
mount -a

# Probe the CVMFS endpoints for acknowledgement
echo "Probing CVMFS endpoints..."
cvmfs_config probe

# Done
echo ""
echo "Ready!"

# Pre-fetch packages and keep the container running forever
SLEEP_TIME=15m
while true;
do
  echo "`date +%D' '%T` -- Prefetching packages for $SOFTWARE_STACK $PLATFORM..."
  source /cvmfs/sft.cern.ch/lcg/views/$SOFTWARE_STACK/$PLATFORM/setup.sh 
  timeout 60s python -m ipykernel > /dev/null 2>&1
  timeout 60s python -m JupyROOT.kernel.rootkernel > /dev/null 2>&1

  echo "`date +%D' '%T` -- Sleeping for $SLEEP_TIME..."
  sleep $SLEEP_TIME
done

