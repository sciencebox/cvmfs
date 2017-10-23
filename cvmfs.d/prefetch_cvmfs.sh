#!/bin/bash

# Pre-fetch resources from CVMFS Stratum 1
echo "Pre-fetching resources from CVMFS..."

if [ "$#" -ne 2 ]; then
        echo "Illegal number of parameters. Cannor prefetch resources."
        echo "Syntax: prefetch_cvmfs.sh <STRATUM1_ENDPOINT> <URI_FILE>"
	return 1;
fi

for uri in `cat $2`
do
        wget -q --delete-after $1$uri -e use_proxy=yes -e http_proxy=127.0.0.1:3128
done

