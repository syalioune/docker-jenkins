#!/bin/bash

# check dependencies
(
    type docker &>/dev/null || ( echo "docker is not available"; exit 1 )
    type curl &>/dev/null || ( echo "curl is not available"; exit 1 )
)>&2

function assert {
  local expected=$1
  shift
  local real=$1
  real=${real//[$'\t\r\n']}
  [ "${expected}" = "${real}" ]
}

# Retry a command $1 times until it succeeds. Wait $2 seconds between retries.
function retry {
    local attempts=$1
    shift
    local delay=$1
    shift
    local i

    for ((i=0; i < attempts; i++)); do
        run "$@"
        if [ "$status" -eq 0 ]; then
            return 0
        fi
        sleep $delay
    done

    echo "Command \"$*\" failed $attempts times. Status: $status. Output: $output" >&2
    false
}

function get_jenkins_url {
    if [ -z "${DOCKER_HOST}" ]; then
        if [ "$(uname)" == "Darwin" ]; then
            DOCKER_IP=docker.local
        else
            DOCKER_IP=localhost
        fi
    else
        DOCKER_IP=$(echo "$DOCKER_HOST" | sed -e 's|tcp://\(.*\):[0-9]*|\1|')
    fi
    echo "http://$DOCKER_IP:$(docker port "${CONTAINER_NAME}" 8080 | cut -d: -f2)"
}

function test_url {
    run curl --user "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}" --output /dev/null --silent --head --fail --connect-timeout 30 --max-time 60 "$(get_jenkins_url)$1"
    if [ "$status" -eq 0 ]; then
        true
    else
        echo "URL $(get_jenkins_url)$1 failed" >&2
        echo "output: $output" >&2
        false
    fi
}

function cleanup {
    docker kill "$1" &>/dev/null ||:
    docker rm -fv "$1" &>/dev/null ||:
    if [[ -n "$2" ]]; then
      docker rmi -f "$2" &>/dev/null ||:
    fi
}
