#!/bin/bash 
#set -o errexit # Bail out on all errors immediately

case $DEPLOYMENT_TYPE in
  "kubernetes")
    echo "Stopping services on $PODINFO_NAME..."

    for mp in `cat /etc/fstab | grep -v "^\#" | tr -s ' ' | cut -d ' ' -f 2 | tr '\n' ' '`;
    do
      umount -f $mp
    done
    ;;

  ###
  "compose")
    # Not really used
    ;;

  *)
    echo "ERROR: Deployment context is not defined."
    echo "Cannot continue."
    exit -1
esac


