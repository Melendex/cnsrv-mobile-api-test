const express = require("express");
const router = new express.Router();
const auth = require("../middleware/auth");
const Product = require('../model/product');

// GET obtener todos los conceptos Varios
router.get('/products', auth, async(req, res) => {

    const match = {};

    try {

        if (req.query.id) {
            match._id = req.query.id;
        }

        const data = await Product.find(match);
        if (!data) {
            throw new Error("Not able to find the product");
        }

        // console.log(data)
        res.status(200).send(data);

    } catch (e) {
        res.status(400).send(e);
    }

})

module.exports = router