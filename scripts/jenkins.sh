#! /bin/bash

#===================================================================
#-------------------------------------------------------------------
# Entrypoint of docker image.
#
# Starts jenkins when launcher parameters (--*) or none are provided
# Execute the given command otherwise.
#
# When starting Jenkins, the following steps are followed :
#  1. Copy configuration reference file from /usr/share/jenkins/ref
#  2. Move Jenkins initial admin password file (iapf) into home folder
#  3. Start jenkins instance with provided launcher parameters
#
# This script is largely inspired by :
#  https://github.com/jenkinsci/docker/blob/master/jenkins.sh
#
#-------------------------------------------------------------------
#===================================================================

set -e

#===================================================================
# Constants declaration
#===================================================================

readonly DEFAULT_JVM_XMX="1024"

#===================================================================
# Functions declaration
#===================================================================

# Copy files from /usr/share/jenkins/ref into $JENKINS_HOME
# So the initial JENKINS-HOME is set with expected content.
# Don't override, as this is just a reference setup, and use from UI
# can then change this, upgrade plugins, etc.
copy_reference_file()
{
    f="${1%/}"
    b="${f%.override}"
    echo "$f" >> "$COPY_REFERENCE_FILE_LOG"
    rel="${b:23}"
    dir=$(dirname "${b}")
    echo " $f -> $rel" >> "$COPY_REFERENCE_FILE_LOG"
    if [[ ! -e $JENKINS_HOME/${rel} || $f = *.override ]]
    then
        echo "copy $rel to JENKINS_HOME" >> "$COPY_REFERENCE_FILE_LOG"
        mkdir -p "$JENKINS_HOME/${dir:23}"
        cp -r "${f}" "$JENKINS_HOME/${rel}";
    fi;
}


# Update iapf (initial admin password file) in case of first setup
update_iapf()
{
  if [[ -e /tmp/iapf ]]; then
    mkdir -p "${JENKINS_HOME}/secrets"
    mv /tmp/iapf "${JENKINS_HOME}/secrets/iapf"
  fi
}

copy_reference_configuration()
{
  touch "${COPY_REFERENCE_FILE_LOG}" || (echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?" && exit 1)
  echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
  find /usr/share/jenkins/ref/ -type f -exec bash -c "copy_reference_file '{}'" \;
}

# Limit the maximum heap size of jenkins JVM if not directly set through launch args
limit_jvm_memory()
{
  if [[ "${JAVA_OPTS}" != *"-Xmx"* ]]; then
    export JAVA_OPTS="${JAVA_OPTS} -Xms$((DEFAULT_JVM_XMX/2))M -Xmx${DEFAULT_JVM_XMX}M"
  fi
}


#===================================================================
# Main part
#===================================================================

: ${JENKINS_HOME:="/var/jenkins_home"}

export -f copy_reference_file

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  copy_reference_configuration
  update_iapf
  limit_jvm_memory
  export JAVA_OPTS="${JAVA_OPTS} -Djava.util.logging.config.file=/var/jenkins_home/logging.properties"
  echo $JAVA_OPTS
  eval "exec java ${JAVA_OPTS} ${SETUP_OPTS} -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS \"\$@\""
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
