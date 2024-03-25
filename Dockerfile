FROM cern/cc7-base:20240301-1

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

# Install essential packages for prefetching JupyROOT kernel from LCG views
RUN yum -y install \
       gcc \
       gcc-c++ \
       util-linux \
       which && \
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

