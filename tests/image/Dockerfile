#=======================================================================
#-----------------------------------------------------------------------
#
# Dockerfile for CI
#
#-----------------------------------------------------------------------
#=======================================================================

FROM tehranian/dind-jenkins-slave

MAINTAINER syalioune<sy_alioune@yahoo.fr>

#=======================================================================
# Tools installation
#=======================================================================

RUN echo "deb http://fr.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    git \
    && apt-get -t trusty-backports install -y --no-install-recommends \
    shellcheck \
    && rm -rf /var/lib/apt/list/*

# Bats installation

RUN mkdir -p /opt/ \
    && cd /opt \
    && git clone https://github.com/sstephenson/bats.git \
    && cd bats \
    && ./install.sh /usr
