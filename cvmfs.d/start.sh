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


### Deprecated ###
: '''
# Configure local Squid proxy
echo "Starting Squid..."
cat /etc/squid/squid.conf_cvmfs >> /etc/squid/squid.conf
squid -z # Init the cache space on disk
sleep 3
squid
sleep 3
'''

# Configure CVMFS 
echo "Mounting CVMFS repositories..."

# Define mount points according to the list of desired repositories
echo "#<cvmfs_repo> <mnt_dir> <fs_type> <options> <dump> <fsck>" > fstab_temp
for i in `cat /etc/cvmfs/default.local | grep -v '^#' | grep CVMFS_REPOSITORIES | cut -d = -f 2- | tr -d "'" | tr "," " "`; 
do
	echo $i /cvmfs/$i cvmfs defaults,_netdev,nodev 0 0 >> fstab_temp
done
cat fstab_temp | column -t > /etc/fstab
/bin/rm fstab_temp

# Make the directories required for the CVMFS mount
mkdir -p `tail -n+2 /etc/fstab | tr -s ' ' | cut -d ' ' -f 2`

# Mount CVMFS repositories and set the mount points as shared
mount -a #&& mount --make-shared /cvmfs

# Probe the CVMFS endpoints for acknowledgement
echo "Probing CVMFS endpoints..."
cvmfs_config probe

### Deprecated ###
: '''
# Pre-fetch resources from CVMFS Stratum 1
STRAT1_ENDPOINT="http://cvmfs-stratum-one.cern.ch/"
USER_SPAWN="/root/prefetch_uri_files/user_spawn_LCG88.uri" # Spawn user container
# PYTHON2="/root/prefetch_uri_files/python2.uri"           # Python 2 Notebook
# ROOT_CPP="/root/prefetch_uri_files/root_cpp.uri"         # ROOT C++ Notebook
# R="/root/prefetch_uri_files/r.uri"                       # R Notebook
bash /root/prefetch_cvmfs.sh $STRAT1_ENDPOINT $USER_SPAWN
'''

# Done
echo ""
echo "Ready!"
sleep infinity

