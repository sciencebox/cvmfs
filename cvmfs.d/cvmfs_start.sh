#!/bin/bash

# Configure local Squid proxy
echo "Starting Squid..."
cat /etc/squid/squid.conf_cvmfs >> /etc/squid/squid.conf
squid -z # Init the cache space on disk
sleep 3
squid
sleep 3


# Configure CVMFS 
echo "Mounting CVMFS repositories..."

# Define mount points according to the list of desired repositories
echo "#<cvmfs_repo> <mnt_dir> <fs_type> <options> <dump> <fsck>" > fstab_temp
for i in `cat /etc/cvmfs/default.local | grep -v '^#' | grep CVMFS_REPOSITORIES | cut -d = -f 2- | tr -d "'" | tr "," " "`; 
do
	echo $i /cvmfs/$i cvmfs defaults 0 0 >> fstab_temp
done
cat fstab_temp | column -t > /etc/fstab
rm fstab_temp

# Make the directories required for the CVMFS mount
# NOTE: Not possible to make directories before as they would be wiped by the --volume command when running the container
mkdir -p `tail -n+2 /etc/fstab | tr -s ' ' | cut -d ' ' -f 2`

# Mount CVMFS repositories and set the mount points as shared
mount -a && mount --make-shared /cvmfs

# Probe the CVMFS endpoints for acknowledgement
cvmfs_config probe

# Pre-fetch resources from CVMFS Stratum 1
STRAT1_ENDPOINT="http://cvmfs-stratum-one.cern.ch/"
USER_SPAWN='/root/prefetch_uri_files/user_spawn_LCG88.uri' # Spawn user container
# PYTHON2='/root/prefetch_uri_files/python2.uri'           # Python 2 Notebook
# ROOT_CPP='/root/prefetch_uri_files/root_cpp.uri'         # ROOT C++ Notebook
# R='/root/prefetch_uri_files/r.uri'                       # R Notebook
./root/prefetch_cvmfs.sh $STRAT1_ENDPOINT $USER_SPAWN

# Done
echo 'Ready...' && tail -f /dev/null

