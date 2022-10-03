

class dsMiddles {

    dsLoginCB1 (req, res, next) {
        passport.authenticate('docusign', { failureRedirect: '/ds/login' })(req, res, next);
    }

    dsLoginCB2 (req, res, next) {
    
        console.log(`Received access_token: |${req.user.accessToken}|`);
        console.log(`Expires at ${req.user.tokenExpirationTimestamp.format("dddd, MMMM Do YYYY, h:mm:ss a")}`);
        console.log('Auth Successful');
        console.log(`Received access_token: |${req.user.accessToken}|`);
        console.log(`Expires at ${req.user.tokenExpirationTimestamp.format("dddd, MMMM Do YYYY, h:mm:ss a")}`);
    
        // Most Docusign api calls require an account id. This is where you can fetch the default account id for the user 
        // and store in the session.
    
        res.redirect('/');
    }

    _processDsResult(accessToken, refreshToken, params, profile, done) {
    // The params arg will be passed additional parameters of the grant.
    // See https://github.com/jaredhanson/passport-oauth2/pull/84
    //
    // Here we're just assigning the tokens to the account object
    // We store the data in DSAuthCodeGrant.getDefaultAccountInfo
    let user = profile;
    console.log({user});
    user.accessToken = accessToken;
    user.refreshToken = refreshToken;
    user.expiresIn = params.expires_in;
    user.tokenExpirationTimestamp = moment().add(user.expiresIn, 's'); // The dateTime when the access token will expire
    //Save the encrypted refresh token to be used to get a new access token when the current one expires
    new Encrypt(dsConfig.refreshTokenFile).encrypt(refreshToken);
    return done(null, user);
  }
}

module.exports = dsMiddles;