#!/usr/bin/env bats

#===================================================================
#-------------------------------------------------------------------
# Docker jenkins image unit tests.
#
# It requires bats utility (https://github.com/sstephenson/bats) to
# run properly.
#-------------------------------------------------------------------
#===================================================================

#===================================================================
# Constants declaration
#===================================================================

readonly IMAGE_NAME="asy-jenkins"
readonly CONTAINER_NAME="asy-jenkins"
readonly MAVEN_TEST_VERSION=3.3.3
readonly MAVEN_TEST_MD5=794b3b7961200c542a7292682d21ba36
readonly JENKINS_ADMIN_USER=administrator
readonly JENKINS_ADMIN_PASSWORD=administrator

#===================================================================
# Loading utility functions
#===================================================================

load test_helper

#===================================================================
# Unit tests
#===================================================================

@test "The docker image should be built successfully with the appropriate args" {
  # An older version of maven is purposely set in order to test dockerfile variables
  run docker build --build-arg MAVEN_VERSION=${MAVEN_TEST_VERSION} --build-arg MAVEN_MD5=${MAVEN_TEST_MD5} --build-arg JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER} --build-arg JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD} -t "${IMAGE_NAME}" $(dirname ${BATS_TEST_DIRNAME})
  [ "$status" -eq 0 ]
}

@test "Removing the test container if it exists 1" {
  cleanup ${CONTAINER_NAME}
}

@test "The build tools should be correctly installed" {
  # JDK 1.7
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} /opt/java/jdk7/bin/java -version
  assert "java version \"1.7.0_79\"" "${lines[0]}"
  # JDK 1.8
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} /opt/java/jdk8/bin/java -version
  assert "java version \"1.8.0_91\"" "${lines[0]}"
  # Maven 3.3.3
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} /opt/maven/maven3/bin/mvn --version
  assert "Apache Maven ${MAVEN_TEST_VERSION} " "$(echo ${lines[0]} | cut -d'(' -f1 )"
}

@test "The plugins should be installed along with their dependencies" {
  # Checking that the following dependency pipeline-stage-view.jpi --> workflow-job.jpi --> workflow-support.jpi
  # is resolved
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} ls /usr/share/jenkins/ref/plugins/pipeline-stage-view.jpi
  assert "/usr/share/jenkins/ref/plugins/pipeline-stage-view.jpi" "${lines[0]}"
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} ls /usr/share/jenkins/ref/plugins/workflow-job.jpi
  assert "/usr/share/jenkins/ref/plugins/workflow-job.jpi" "${lines[0]}"
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} ls /usr/share/jenkins/ref/plugins/workflow-support.jpi
  assert "/usr/share/jenkins/ref/plugins/workflow-support.jpi" "${lines[0]}"
}

@test "The iapf file should be filled properly" {
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} cat /tmp/iapf
  assert "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}" "${lines[0]}"
}

@test "The SETUP_OPTS environment variable should be set properly" {
  run docker run --name ${CONTAINER_NAME} --rm -P -it ${IMAGE_NAME} bash -c "env | grep SETUP_OPTS"
  assert "SETUP_OPTS=-Djenkins.install.runSetupWizard=false" "${lines[0]}"
}

@test "Create test container" {
  run docker run --name ${CONTAINER_NAME} -P -d ${IMAGE_NAME}
}

@test "Check that container starts correctly 1" {
  sleep 1  # give time to eventually fail to initialize
  retry 3 1 [ "true" = "$(docker inspect -f {{.State.Running}} ${CONTAINER_NAME})" ]
}

@test "Check that Jenkins starts correctly 1" {
  retry 30 5 test_url /api/json
}

@test "Check JVM heap size constraints 1" {
  run bash -c "docker top ${CONTAINER_NAME} | grep jenkins.war | grep -o \"\-Xms512M \-Xmx1024M\""
  assert "-Xms512M -Xmx1024M" "${lines[0]}"
}

@test "Check that logs are generated in the appropriate location" {
  run docker exec -it ${CONTAINER_NAME} ls /var/jenkins_home/logs/
}

@test "Removing the test container if it exists 2" {
  cleanup ${CONTAINER_NAME}
}

@test "Create test container with explicit heap size constraints" {
  run docker run --name ${CONTAINER_NAME} -P -d -e JAVA_OPTS="-Xms256M -Xmx512M" ${IMAGE_NAME}
}

@test "Check that container starts correctly 2" {
  sleep 1  # give time to eventually fail to initialize
  retry 3 1 [ "true" = "$(docker inspect -f {{.State.Running}} ${CONTAINER_NAME})" ]
}

@test "Check that Jenkins starts correctly 2" {
  retry 30 5 test_url /api/json
}

@test "Check JVM heap size constraints 2" {
  run bash -c "docker top ${CONTAINER_NAME} | grep jenkins.war | grep -o \"\-Xms256M \-Xmx512M\""
  assert "-Xms256M -Xmx512M" "${lines[0]}"
}

@test "Cleanup the test environment" {
  cleanup ${CONTAINER_NAME} ${IMAGE_NAME}
}
