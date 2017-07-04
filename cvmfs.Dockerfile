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

# ----- Use CERN cc7 as base image for CVMFS ----- #
FROM cern/cc7-base:20170113

MAINTAINER Enrico Bocchi <enrico.bocchi@cern.ch>


# ----- Set environment and language ----- #
ENV DEBIAN_FRONTEND noninteractive
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


RUN yum -y install yum-plugin-ovl # See http://unix.stackexchange.com/questions/348941/rpmdb-checksum-is-invalid-trying-to-install-gcc-in-a-centos-7-2-docker-image

# ----- Install  Squid proxy and CVMFS software ----- #
RUN yum -y update
RUN yum -y install \
	squid \
	cvmfs \
	cvmfs-config-default \
	wget


# ----- Copy configuration files ----- #
COPY cvmfs.d/squid.conf_cvmfs /etc/squid/squid.conf_cvmfs
COPY cvmfs.d/cvmfs_default.local /etc/cvmfs/default.local
COPY cvmfs.d/cvmfs_start.sh /root/cvmfs_start.sh

# ----- Copy the list of URIs to be pre-fetched when starting squid/CVMFS ----- #
COPY cvmfs.d/prefetch_cvmfs.sh /root/prefetch_cvmfs.sh
COPY cvmfs.d/prefetch_uri_files/* /root/prefetch_uri_files/


# ----- Run the setup script in the container ----- #
CMD ["bash", "/root/cvmfs_start.sh"]
