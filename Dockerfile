FROM cern/alma9-base:20240501-1

MAINTAINER Enrico Bocchi <enrico.bocchi@cern.ch>

# Install supervisord
#  Note: Can be helpful to mount multiple repositories in foreground
RUN dnf -y install \
       epel-release && \
    dnf clean all && \
    rm -rf /var/cache/dnf
RUN dnf -y install \
       supervisor && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install essential packages for prefetching JupyROOT kernel from LCG views
RUN dnf -y install \
       gcc \
       gcc-c++ \
       util-linux \
       which && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install CVMFS client
ARG CVMFS_VERSION
ADD ./repos.d/*.repo /etc/yum.repos.d/
RUN dnf -y install \
      cvmfs$CVMFS_VERSION \
      cvmfs-config-default && \
    dnf clean all && \
    rm -rf /var/cache/dnf

