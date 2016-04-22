/**
 * Jenkins security initial configuration.
 */

import jenkins.model.*
import hudson.security.*


def instance = Jenkins.getInstance()

// Configure security - Jenkins administrator creation

def iapf = new File(instance.getRootPath().child("secrets/iapf").toString())

if(iapf.exists()) {

  String credentials = iapf.text

  if (null != credentials && ! "".equals(credentials)) {

    String[] parts = credentials.split(":")

    if(parts.length == 2) {

      String login = parts[0]
      String password = parts[1]

      def hudsonRealm = new HudsonPrivateSecurityRealm(false, false, null);

      hudsonRealm.createAccount(login, password);

      instance.setSecurityRealm(hudsonRealm)

      def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
      strategy.setAllowAnonymousRead(false);
      instance.setAuthorizationStrategy(strategy)

      iapf.delete()

    }

  }

}

// Configure security - Jenkins CSP for javadoc and HTML publisher plugin to work
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "default-src 'none'; img-src 'self'; style-src 'self' 'unsafe inline'; child-src 'self'; frame-src 'self'; script-src 'unsafe-inline'")

instance.save()
