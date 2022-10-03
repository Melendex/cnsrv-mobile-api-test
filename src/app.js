const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const passport = require('passport');
const dsConfig = require('./utils/dsConfig').config;
const session = require('express-session');
const MemoryStore = require('memorystore')(session);
const DocusignStrategy = require('passport-docusign');
const moment = require('moment');
const Encrypt = require('./utils/Encrypt').Encrypt;

// const { rabbitConnection } = require('./rabbitmq/rabbitmq')
require('./db/mongoose');
require('./db/connSQL');

// rabbitConnection()
const userRouter = require('./routers/user')
const loanappRouter = require('./routers/loanapp');
const productRouter = require('./routers/product')
const clientRouter = require('./routers/client');
const neighborhoodRouter = require('./routers/neighborhood');

const openpayStoreRouter = require('./routers/openpay/store')
const personRouter = require('./routers/person')
const catalogRouter = require('./routers/catalog')
const veridocRouter = require('./routers/veridoc');
const branchRouter = require('./routers/branch');
const docuSignRouter = require('./routers/docusign');

const max_session_min = 180;
let hostUrl = 'http://' + process.env.HOST + ':' + process.env.PORT;
if (dsConfig.appUrl != '' && dsConfig.appUrl != '{APP_URL}') { hostUrl = dsConfig.appUrl; console.log(hostUrl) }
const app = express()
// .use(cookieParser())
//     .use(session({
//         secret: dsConfig.sessionSecret,
//         name: 'ds-authexample-session',
//         cookie: { maxAge: max_session_min * 60000 },
//         saveUninitialized: true,
//         resave: true,
//         store: new MemoryStore({
//             checkPeriod: 86400000 // prune expired entries every 24h
//         })
//     }))
//     .use(passport.initialize())
//     .use(passport.session())
//     .use(bodyParser.urlencoded({ extended: true }));


// Configure passport for DocusignStrategy
// let docusignStrategy = new DocusignStrategy({
//     production: dsConfig.production,
//     clientID: dsConfig.dsClientId,
//     clientSecret: dsConfig.dsClientSecret,
//     callbackURL: hostUrl + '/ds/callback',
//     // callbackURL: dsConfig.appUrl,
//     state: true // automatic CSRF protection.
//     // See https://github.com/jaredhanson/passport-oauth2/blob/master/lib/state/session.js
// },
//     function _processDsResult(accessToken, refreshToken, params, profile, done) {
//         // The params arg will be passed additional parameters of the grant.
//         // See https://github.com/jaredhanson/passport-oauth2/pull/84
//         //
//         // Here we're just assigning the tokens to the account object
//         // We store the data in DSAuthCodeGrant.getDefaultAccountInfo
//         let user = profile;
//         // console.log({ user });
//         user.accessToken = accessToken;
//         user.refreshToken = refreshToken;
//         user.expiresIn = params.expires_in;
//         user.tokenExpirationTimestamp = moment().add(user.expiresIn, 's'); // The dateTime when the access token will expire
//         //Save the encrypted refresh token to be used to get a new access token when the current one expires
//         new Encrypt(dsConfig.refreshTokenFile).encrypt(refreshToken);
//         return done(null, user);
//     }
// );

// if (!dsConfig.allowSilentAuthentication) {
//     // See https://stackoverflow.com/a/32877712/64904 
//     docusignStrategy.authorizationParams = function (options) {
//         return { prompt: 'login' };
//     }
// }
// passport.serializeUser(function (user, done) {

//     console.log("In serialize user");
//     done(null, user)
// });
// passport.deserializeUser(function (obj, done) {
//     console.log("In de-serialize user");
//     done(null, obj);

// });

// passport.use(docusignStrategy);

app.use(express.json({ limit: '50mb' }));

app.use(express.json())
app.use(userRouter)
app.use(loanappRouter);
app.use(productRouter)
app.use(openpayStoreRouter)
app.use(catalogRouter)
app.use(clientRouter);
app.use(personRouter);
app.use(docuSignRouter);

app.use(neighborhoodRouter);
app.use(veridocRouter);
app.use(branchRouter);


module.exports = app