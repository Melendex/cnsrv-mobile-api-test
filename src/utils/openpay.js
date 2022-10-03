const Openpay = require('openpay');

const openpay = new Openpay(process.env.OPENPAY_ID, process.env.OPENPAY_SECRET_KEY, false);

const axios = require('axios');

const str = `${process.env.OPENPAY_SECRET_KEY}:`
var secretBase64 = Buffer.from(str).toString('base64')

const openpayStoreAxios = axios.create({
    baseURL: "https://api.openpay.mx",
    headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${secretBase64}`
    }
});

module.exports = { openpay, openpayStoreAxios };