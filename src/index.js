const app = require('./app')

const port = process.env.PORT || 8090

app.listen(port, () => {
    console.log('Secure server 🔑 🚀 is up and running...at ' + port + process.env.SQL_SERVER_NAME)
})