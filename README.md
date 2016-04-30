## Opinionated Docker image for fast jenkins setup

This docker image will setup a running instance of CI server [Jenkins](http://jenkins-ci.org/).
It is derived from [Jenkins official image](https://github.com/jenkinsci/docker) and personal biases on plugins/tools/configuration. Please see [below](#4) for the description of differences regarding the offical image.

## Usage

### Basic usage

* Jenkins launch

  ```
  docker run -d -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:HOST_DIRECTORY asy/jenkins
  ```

The port 5000 is used to attach build slaves on the master host. Make sure that **HOST_DIRECTORY** is accessible to the jenkins user on container (uid : 1000 & gid : 1000).

* Jenkins launch with parameters

  ```
  docker run -d -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:HOST_DIRECTORY asy/jenkins PARAMETERS
  ```

  The **PARAMETERS** should start with double dash (--).
  Please note that those parameters can also be passed through the **JENKINS_OPTS** environment variable

  ```
  docker run -d -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:HOST_DIRECTORY asy/jenkins --env JENKINS_OPTS=PARAMETERS
  ```

* Arbitrary command execution

  ```
  docker run -d -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:HOST_DIRECTORY asy/jenkins COMMAND
  ```

### JVM parameters setup

You can pass some parameters to Jenkins JVM through the **JAVA_OPTS** environment variable.

```
docker run -d -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:HOST_DIRECTORY asy/jenkins --env JAVA_OPTS=PARAMETERS
```

If not explicitly set on Jenkins launch, the JVM heap size is automatically constrained by the entrypoint script in order to limit the jenkins memory footprint on the host. The default limits are

```
-Xms512M -Xmx1024M
```

## Differences with official version

### Tools

The jenkins instance built upon this image is bundled with the following tools (installed on **/opt**)

* JDK 1.7 [7u79](http://www.oracle.com/technetwork/java/javase/7u79-relnotes-2494161.html)
* JDK 1.8 [8u91](http://www.oracle.com/technetwork/java/javase/8u91-relnotes-2949462.html)
* Maven [3.3.9](https://maven.apache.org/docs/3.3.9/release-notes.html)

Those tools are already configured within Jenkins.

### Plugins

This image is built using a *personal* list of must have plugins. Those plugins can be found [here](https://github.com/asy/docker-jenkins/ref/plugins.txt).
Plugins dependencies are also automatically downloaded with the latest version and finally the downloaded plugins are not [pinned](https://wiki.jenkins-ci.org/display/JENKINS/Pinned+Plugins) allowing for easier updates.

### Administration & security

By default, Jenkins fresh instances are not configured for authentication and anyone can do whatever they want. The instance built by this image is automatically configured to only authorize logged-in users to perform any actions. An administrative account is setup for initial access, the default credentials are :

```
login=admin
password=admin
```

**Those credentials must be changed** for a secure installation.

Starting from [Jenkins 2.0](https://jenkins.io/2.0/), the users are now presented with a setup wizard on first run to ease the customization of Jenkins. The main purposes of this setup is to help with plugins selection and security configuration. Since those are already automatically covered, the setup wizard is bypassed (this default can be overrided).

Jenkins CSP is also setup as below in [security.groovy](https://github.com/asy/docker-jenkins/init/security.groovy)

```
default-src 'none'; img-src 'self'; style-src 'self' 'unsafe inline'; child-src 'self'; frame-src 'self'; script-src 'unsafe-inline'
```


### Logging

Jenkins is configured to output logs in `/var/jenkins_home/logs/jenkins.log`
The logging configuration can be found in `/var/jenkins_home/logging.properties`

## Update the tools version & configuration

### Update JDK 8 version

You must override the dockerfile variables ORACLE\_JDK8\_PATCH\_VERSION and ORACLE\_JDK8\_MD5 in order to update JDK 8 version.

```
mkdir -p #workdir#
cd #workdir#
git clone https://github.com/asy/docker-jenkins.git
cd docker-jenkins
docker build --build-arg ORACLE_JDK8_PATCH_VERSION=#PATCH_VERSION# --build-arg ORACLE_JDK8_MD5=#PATCH_VERSION_MD5# -t #TAG_NAME# .
```

### Update maven version

You must override the dockerfile variables MAVEN\_VERSION and MAVEN\_MD5 in order to update maven version.

```
mkdir -p #workdir#
cd #workdir#
git clone https://github.com/asy/docker-jenkins.git
cd docker-jenkins
docker build --build-arg MAVEN_VERSION=#MAVEN_VERSION# --build-arg MAVEN_MD5=#MAVEN_MD5# -t #TAG_NAME# .
```

### Update jenkins administration configuration

You must override the dockerfile variables RUN\_SETUP\_WIZARD, JENKINS\_ADMIN\_USER and JENKINS\_ADMIN\_PASSWORD in order to update jenkins administration configuration.

```
mkdir -p #workdir#
cd #workdir#
git clone https://github.com/asy/docker-jenkins.git
cd docker-jenkins
docker build --build-arg RUN_SETUP_WIZARD=#true|false# --build-arg JENKINS_ADMIN_USER=#USER# --build-arg JENKINS_ADMIN_PASSWORD=#PASSWORD# -t #TAG_NAME# .
```

## Tests

TODO
