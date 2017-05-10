#!/bin/bash

#RUN_IN_CONTAINER cvmfs

set -o errexit # bail out on all errors immediately
set -x


# Probe CVMFS endpoint
cvmfs_config probe || exit 1

# Try to read a file (same path of software for Jupyter Notebooks)
CVMFS_TEST="/cvmfs/sft.cern.ch/lcg/views/LCG_88/x86_64-slc6-gcc49-opt/setup.sh"
cat $CVMFS_TEST > /dev/null || exit 1

# Ping CVMFS repository
CVMFS_PING=$OUTPUT_DIR"/cvmfs_ping.log"
CVMFS_PROXY=`cat /etc/cvmfs/default.local | grep -v '^#' | grep CVMFS_HTTP_PROXY | cut -d '=' -f 2 | tr '|' '\n' | tr ';' '\n' | grep -v "ca-proxy" | grep -v "DIRECT" | tr '\n' ' ' | sed 's/http:\/\///g' | sed 's/:3128//g' | tr -d "'"`
CVMFS_SERVER=`cat /etc/cvmfs/domain.d/cern.ch.conf | grep -v "^#" | grep CVMFS_SERVER_URL | cut -d '=' -f 2 | sed 's/http:\/\///g' | sed 's/\/cvmfs\/@fqrn@//g' | tr -d '"' | tr ';' ' '`

for i in $CVMFS_PROXY $CVMFS_SERVER ;
do
	ping -c 5 -i 0.2 -w 5 $i || exit 0
done

