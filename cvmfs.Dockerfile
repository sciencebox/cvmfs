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

# ----- Install the basics for CVMFS ----- #
RUN yum -y update && \
	yum -y install cvmfs cvmfs-config-default


# ----- Define the configuration for CVMFS ----- #
# Note: Only one of the two following configurations can be selected at a time.
#		Please comment the undesired one.

# 1. Set bindings to all the repos (See: https://cernvm.cern.ch/portal/cvmfs/examples)
#RUN echo -e \
#"CVMFS_QUOTA_LIMIT=20000\n\
#CVMFS_CACHE_BASE=/var/cache/cvmfs\n\
#CVMFS_HTTP_PROXY='http://ca-proxy.cern.ch:3128;http://ca-proxy-meyrin.cern.ch:3128;http://ca01.cern.ch:3128|http://ca02.cern.ch:3128|http://ca03.cern.ch:3128|http://ca04.cern.ch:3128|http://ca05.cern.ch:3128|http://ca06.cern.ch:3128'\n\
#CVMFS_REPOSITORIES='alice.cern.ch,alice-ocdb.cern.ch,atlas.cern.ch,atlas-condb.cern.ch,boss.cern.ch,cms.cern.ch,geant4.cern.ch,grid.cern.ch,lhcb.cern.ch,na61.cern.ch,sft.cern.ch'" \
#		> /etc/cvmfs/default.local

# 2. Set bindings to the SFT repo only
RUN echo -e \
"CVMFS_QUOTA_LIMIT=20000\n\
CVMFS_CACHE_BASE=/var/cache/cvmfs\n\
CVMFS_HTTP_PROXY='http://ca-proxy.cern.ch:3128;http://ca-proxy-meyrin.cern.ch:3128;http://ca01.cern.ch:3128|http://ca02.cern.ch:3128|http://ca03.cern.ch:3128|http://ca04.cern.ch:3128|http://ca05.cern.ch:3128|http://ca06.cern.ch:3128'\n\
CVMFS_REPOSITORIES='sft.cern.ch'" \
		> /etc/cvmfs/default.local


# ----- Define the mount points in fstab and prepare the directories ----- #
RUN echo "#<cvmfs_repo> <mnt_dir> <fs_type> <options> <dump> <fsck>" > fstab_temp && \
	for i in `cat /etc/cvmfs/default.local | grep CVMFS_REPOSITORIES | cut -d = -f 2- | tr -d "'" | tr "," " "`; do echo $i /cvmfs/$i cvmfs defaults 0 0 >> fstab_temp; done && \
	cat fstab_temp | column -t > /etc/fstab && \
	rm fstab_temp


# ----- Configure the container running CVMFS and setup the mount ----- #
RUN echo -e "#!/bin/bash\n\
\n\
# Make the directories required for the CVMFS mount\n\
# NOTE: Not possible to make directories before as they would be wiped by the --volume command when running the container\n\
mkdir -p `tail -n+2 /etc/fstab | tr -s ' ' | cut -d ' ' -f 2`\n\
\n\
# Mount CVMFS repositories and set the mount points as shared\n\
mount -a && mount --make-shared /cvmfs\n\
\n\
# Probe the CVMFS endpoints for acknowledgement\n\
cvmfs_config probe\n\
echo 'Ready...' && tail -f /dev/null" \
		> /setup_cvmfs.sh


# ----- Run the setup script in the container ----- #
CMD ["bash", "setup_cvmfs.sh"]
