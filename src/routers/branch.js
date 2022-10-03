const express = require("express");
const router = new express.Router();
const auth = require("../middleware/auth");
const Branch = require('../model/branch');

// GET obtener todos los conceptos Varios
router.get('/branches', auth, async(req, res) => {
    const match = {
        enabled: true
    };
    try {

        const data = await Branch.find(match);
        
        if (!data) {
            throw new Error("Not able to find branches");
        }
        console.log(data);
        res.status(200).send(data);

    } catch (e) {
        res.status(400).send(e);
    }

})

module.exports = router