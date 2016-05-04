node('docker-jenkins-slave') {
  stage 'Build and unit tests'
    checkout scm
    sh 'bats tests'

  stage 'Static code analysis'
    sh 'shellcheck -f checkstyle scripts/plugins.sh scripts/jenkins.sh > ${WORKSPACE}/checkstyle.xml || true'
    step([$class: 'CheckStylePublisher', canComputeNew: false, defaultEncoding: '', failedTotalAll: '4', healthy: '3', pattern: 'checkstyle.xml', unHealthy: '4', unstableTotalAll: '3'])

  stage 'Deploy'
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', passwordVariable: 'password', usernameVariable: 'username']]) {
      sh 'docker login --username ${username} --password ${password} --email sy_alioune@yahoo.fr'
    }
    sh 'IMAGE_ID=$(docker images -q syalioune-jenkins) && [ -n "${IMAGE_ID}" ] && docker tag ${IMAGE_ID} syalioune/jenkins:latest'
    sh 'docker push syalioune/jenkins:latest'
}

