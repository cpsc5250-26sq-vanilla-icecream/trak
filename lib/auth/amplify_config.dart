const amplifyConfig = '''{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/2.0",
        "Version": "1.0",
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "us-east-1lfsu0wzmv.auth.us-east-1.amazoncognito.com",
              "AppClientId": "54k55f1soa74c6if86mvnq5nsi",
              "SignInRedirectURI": "trak://callback",
              "SignOutRedirectURI": "trak://signout",
              "Scopes": ["openid", "email", "profile"]
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_LFSu0wZmV",
            "AppClientId": "54k55f1soa74c6if86mvnq5nsi",
            "Region": "us-east-1"
          }
        }
      }
    }
  }
}''';
