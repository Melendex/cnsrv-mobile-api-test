exports.config = {
    dsClientId: process.env.INTEGRATION_KEY,
    dsClientSecret: process.env.INTEGRATION_SECRET,
    appUrl: 'hhtp://localhost:8090',
    production: false,
    debug: true,
    sessionSecret: process.env.SESSION_SECRET || '1a2b33dd',
    tokenSecret: process.env.TOKEN_SECRET || 'Q1W2E3R4T5Y6',
    allowSilentAuthentication: true,
    targetAccountId: null
}

exports.config.dsOauthServer = exports.config.production ? 'https://account.docusign.com' : 'https://account-d.docusign.com';

exports.config.refreshTokenFile =  require('path').resolve(__dirname,'./refreshTokenFile');
