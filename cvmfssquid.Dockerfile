### DOCKER FILE FOR cvmfssquid IMAGE ###

###
# export RELEASE_VERSION=":v0"
# docker build -t gitlab-registry.cern.ch/cernbox/boxedhub/cvmfssquid${RELEASE_VERSION} -f cvmfssquid.Dockerfile .
# docker login gitlab-registry.cern.ch
# docker push gitlab-registry.cern.ch/cernbox/boxedhub/cvmfssquid${RELEASE_VERSION}
###


FROM cern/cc7-base:20170920

MAINTAINER Enrico Bocchi <enrico.bocchi@cern.ch>


# ----- Set environment and language ----- #
ENV DEBIAN_FRONTEND noninteractive
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


# ----- Install Squid proxy and CVMFS software ----- #
RUN yum -y install \
	squid \
	cvmfs \
        cvmfs-config-default \
	wget


# ----- Install supervisord and base configuration file ----- #
RUN yum -y install supervisor
ADD ./supervisord.d/supervisord.conf /etc/supervisord.conf


# ----- Copy configuration files for squid ----- #
ADD ./cvmfssquid.d/squid.conf_cvmfs /root/squid.conf_cvmfs


# ----- Start SQUID proxy ----- #
ADD ./cvmfssquid.d/start.sh /root/
ADD ./supervisord.d/squid.ini /etc/supervisord.d

CMD ["bash", "/root/start.sh"]



