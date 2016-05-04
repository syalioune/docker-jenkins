#=======================================================================
#-----------------------------------------------------------------------
#
# Dockerfile for an opinionated Jenkins installation
#
#-----------------------------------------------------------------------
#=======================================================================

FROM jenkinsci/jenkins

MAINTAINER syalioune<sy_alioune@yahoo.fr>

#=======================================================================
# Tools installation
#=======================================================================

USER root

RUN mkdir -p /opt/java \
    && chown jenkins:jenkins /opt/java \
    && mkdir -p /opt/maven \
    && chown jenkins:jenkins /opt/maven

COPY scripts/*.sh /usr/local/bin/

USER jenkins

# Oracle JDK 7 & 8 installation

ARG ORACLE_JDK8_PATCH_VERSION=8u91-b14
ARG ORACLE_JDK8_MD5=3f3d7d0cd70bfe0feab382ed4b0e45c0

RUN cd /opt/java \
    && wget --no-check-certificate \
            --no-cookies \
            --header "Cookie: oraclelicense=accept-securebackup-cookie" \
            http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz \
    && echo "9222e097e624800fdd9bfb568169ccad jdk-7u79-linux-x64.tar.gz" | md5sum -c - \
    && tar xzvf jdk-7u79-linux-x64.tar.gz \
    && mv jdk1.7.0_79 jdk7 \
    && rm -f jdk-7u79-linux-x64.tar.gz \
    && PATCH=${ORACLE_JDK8_PATCH_VERSION%-*} \
    && wget --no-check-certificate \
            --no-cookies \
            --header "Cookie: oraclelicense=accept-securebackup-cookie" \
            http://download.oracle.com/otn-pub/java/jdk/${ORACLE_JDK8_PATCH_VERSION}/jdk-${PATCH}-linux-x64.tar.gz \
    && echo "${ORACLE_JDK8_MD5} jdk-${PATCH}-linux-x64.tar.gz" | md5sum -c - \
    && tar xzvf jdk-${PATCH}-linux-x64.tar.gz \
    && mv jdk1.8.0_${PATCH#*u} jdk8 \
    && rm -f jdk-${PATCH}-linux-x64.tar.gz

# Maven 3 installation

ARG MAVEN_VERSION=3.3.9
ARG MAVEN_MD5=516923b3955b6035ba6b0a5b031fbd8b

RUN cd /opt/maven \
    && wget http://www-eu.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${MAVEN_MD5} apache-maven-${MAVEN_VERSION}-bin.tar.gz" | md5sum -c - \
    && tar xzvf apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && mv apache-maven-${MAVEN_VERSION} maven3 \
    && rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz

#=======================================================================
# Jenkins plugins installation and reference configuration copy
#=======================================================================

COPY ref/* /usr/share/jenkins/ref/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

#=======================================================================
# Jenkins runtime setup
#=======================================================================

ARG RUN_SETUP_WIZARD=false

ARG JENKINS_ADMIN_USER=admin

ARG JENKINS_ADMIN_PASSWORD=admin

RUN echo -n "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}" > /tmp/iapf

COPY init/*.groovy /usr/share/jenkins/ref/init.groovy.d/

ENV SETUP_OPTS -Djenkins.install.runSetupWizard=${RUN_SETUP_WIZARD}
