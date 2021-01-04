FROM cern/cc7-base:20201201-1.x86_64

MAINTAINER Enrico Bocchi <enrico.bocchi@cern.ch>


RUN yum -y install \
       yum-plugin-priorities && \
    yum clean all && \
    rm -rf /var/cache/yum

ARG CVMFS_VERSION

ADD ./repos.d/*.repo /etc/yum.repos.d/
RUN yum -y install \
      cvmfs$CVMFS_VERSION \
      cvmfs-config-default && \
    yum clean all && \
    rm -rf /var/cache/yum

