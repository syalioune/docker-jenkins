#! /bin/bash

#===================================================================
#-------------------------------------------------------------------
# Utility script to download a list of jenkins plugins.
#
# The parameter specification file has the format (plugin:version\n)+
# Blank lines and comments are allowed.
#
# This script is largely inspired by :
#  https://github.com/jenkinsci/docker/blob/master/plugins.sh
#  https://gist.github.com/rpetti/292d8bdd9e45659e6c86
#
#-------------------------------------------------------------------
#===================================================================

set -e

#===================================================================
# Constants declaration
#===================================================================

readonly PLUGINS_REF="/usr/share/jenkins/ref/plugins"

if [[ -z "${JENKINS_UC_DOWNLOAD}" ]]; then
  readonly JENKINS_UC_DOWNLOAD="${JENKINS_UC}/download"
fi

readonly MAX_LOOPS=100

#===================================================================
# Functions declaration
#===================================================================

download_plugin()
{
  local plugin=$1
  local version=$2

  echo "Downloading ${plugin}:${version}"

  curl -sSL -f "${JENKINS_UC_DOWNLOAD}/plugins/${plugin}/${version}/${plugin}.hpi" -o "${PLUGINS_REF}/${plugin}.jpi"
  unzip -qqt "${PLUGINS_REF}/${plugin}.jpi"
}

download_plugins_from_spec()
{
  local spec=$1

  # Parsing the plugins specification file
  while read line || [ -n "${line}" ]; do
    line=(${line//:/ });
    [[ ${line[0]} =~ ^# ]] && continue
    [[ ${line[0]} =~ ^\s*$ ]] && continue
    [[ -z ${line[1]} ]] && line[1]="latest"

    download_plugin ${line[0]} ${line[1]}

  done  < "${spec}"
}

resolve_plugins_dependencies()
{
  local changed=1
  local loops=0

  while [ "${changed}"  == "1" ]; do
    echo "Check for missing dependencies ..."

    if  [[ ${loops} -gt ${MAX_LOOPS} ]] ; then
      echo "Max loop count reached - probably a bug in this script: $0"
      exit 1
    fi

    set +e
    ((loops++))
    set -e

    changed=0

    for plugin in ${PLUGINS_REF}/*.jpi ; do

      echo "Resolving the dependencies of ${plugin}"
      echo "------------------------------------------"

      local dependencies=$(unzip -p "${plugin}" META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | awk -F ':' '{ print $1 }' | tr '\n' ' ' )

      for dependency in ${dependencies}; do

        if [[ ! -f ${PLUGINS_REF}/${dependency}.jpi ]]; then
          changed=1

          # The latest version of the dependency is downloaded / incompatibilities should be handled in GUI
          download_plugin "${dependency}" "latest"
        fi

      done

      echo "------------------------------------------"

    done
  done
}

#===================================================================
# Main
#===================================================================

mkdir -p "${PLUGINS_REF}"

if [[  -f "${1}" ]]; then
    download_plugins_from_spec "${1}"
    resolve_plugins_dependencies
fi
