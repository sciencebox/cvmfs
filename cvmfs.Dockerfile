### DOCKER FILE FOR cvmfs IMAGE ###

###
# export RELEASE_VERSION=":v0"
# docker build -t gitlab-registry.cern.ch/cernbox/boxedhub/cvmfs${RELEASE_VERSION} -f cvmfs.Dockerfile .
# docker login gitlab-registry.cern.ch
# docker push gitlab-registry.cern.ch/cernbox/boxedhub/cvmfs${RELEASE_VERSION}
###

# Dockerfile to create the container for CMVFS
# NOTE: The container needs SYS_ADMIN capabilities (--cap-add SYS_ADMIN) and access to /dev/fuse on the host machine (--device /dev/fuse)
#
#	-->	To run the container WITHOUT CVMFS access from the outside of the container: 
#			1. docker build -t cvmfs -f cvmfs.Dockerfile .
#			2. docker run --name cvmfs_mount --cap-add SYS_ADMIN --device /dev/fuse -t cvmfs
#
#	-->	To run the container WITH CVMFS access from the outside of the container: 
#			1. mkdir -p /deploy_docker/cvmfs_mount
#				==> MAKE SURE THE DIRECTORY IS EMPTY! <==
#			2. docker build -t cvmfs -f cvmfs.Dockerfile .
#			3. docker run --name cvmfs_mount --cap-add SYS_ADMIN --device /dev/fuse --volume /deploy_docker/cvmfs_mount:/cvmfs:shared -t cvmfs
#		-->	If you then need to access the CVMFS mount from another docker container, 
#			run the latter as, e.g., :
#			docker run -it --volume /deploy_docker/cvmfs_mount:/cvmfs ubuntu bash
#		--> To remove the /deploy_docker/cvmfs_mount subfolders when the CVMFS container is gone run
#				fusermount -u /deploy_docker/cvmfs_mount/<folder_to_be_removed>, or
#				sudo umount -l /deploy_docker/cvmfs_mount/<folder_to_be_removed>
#			and the proceed with the typical rmdir <folder_to_be_removed>
#
# See also: https://github.com/docker/docker/pull/17034
# and some random searches on google for 'mount propagation in docker'


FROM cern/cc7-base:20180316

MAINTAINER Enrico Bocchi <enrico.bocchi@cern.ch>


# ----- Set environment and language ----- #
ENV DEBIAN_FRONTEND noninteractive
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


# NOTE: Since cvmfs:v0.1 (2017/11/06), local squid proxy has been disasbled 
# 	as CVMFS itself has a better cache handling.
# 	Previous code has been kept in the need of reverting modifications.

# ----- Install Squid proxy and CVMFS software ----- #
#RUN yum -y install \
#	squid \
#	cvmfs \
#	cvmfs-config-default \
#	wget
#
# Copy configuration files for squid
#ADD ./cvmfs.d/squid.conf_cvmfs /etc/squid/squid.conf_cvmfs
#
# Copy the list of URIs to be pre-fetched when starting squid/CVMFS
#ADD ./cvmfs.d/prefetch_cvmfs.sh /root/prefetch_cvmfs.sh
#ADD ./cvmfs.d/prefetch_uri_files/* /root/prefetch_uri_files/
#


# ----- Install CVMFS ----- #
RUN yum -y install \
	cvmfs \
	cvmfs-config-default

# Copy configuration files
ADD ./cvmfs.d/cvmfs_default.local /root/cvmfs_default.local


# ----- Install supercronic and the cronjob to prefetch from CVMFS ----- #
RUN yum -y install wget
RUN wget -q https://github.com/aptible/supercronic/releases/download/v0.1.5/supercronic-linux-amd64 -O /usr/bin/supercronic
RUN chmod +x /usr/bin/supercronic
ADD ./cvmfs.d/cvmfs_prefetch.cronjob /etc/supercronic.d/cvmfs_prefetch.cronjob
ADD ./cvmfs.d/cvmfs_prefetch.sh /etc/supercronic.d/cvmfs_prefetch.sh


# ----- Start the CVMFS client ----- #
ADD ./cvmfs.d/start.sh /root/start.sh
ADD ./cvmfs.d/stop.sh /root/stop.sh
CMD ["/bin/bash", "/root/start.sh"]

