const express = require('express');
const router = new express.Router();
const auth = require("../middleware/auth");
const User = require("./../model/user");
const tbl = require("./../utils/TablesSQL");

const sql = require('mssql');
const { sqlConfig } = require("./../db/connSQL");

router.get('/person', auth, (req, res) => {
    try {
        res.status(200).send('OK')
    } catch (error) {
        res.status(401).send(error.message)
    }
})

router.post('/persons/create', async(req, res) => {
    try {
        const result = await User.createPersonHF(req.body)

        res.status(201).send(result);
    } catch (error) {
        res.status(401).send(error.message)
    }
});

module.exports = router;