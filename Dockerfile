FROM cern/cc7-base:20211001-1.x86_64

MAINTAINER Enrico Bocchi <enrico.bocchi@cern.ch>

# Install yum priorities plugin
RUN yum -y install \
       yum-plugin-priorities && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install supervisord
#  Note: Can be helpful to mount multiple repositories in foreground
RUN yum -y install \
       supervisor && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install CVMFS client
ARG CVMFS_VERSION
ADD ./repos.d/*.repo /etc/yum.repos.d/
RUN yum -y install \
      cvmfs$CVMFS_VERSION \
      cvmfs-config-default && \
    yum clean all && \
    rm -rf /var/cache/yum

