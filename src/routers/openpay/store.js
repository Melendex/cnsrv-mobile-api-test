const express = require("express");
const router = new express.Router();
const { openpayStoreAxios } = require("./../../utils/openpay")

router.get('/stores/:lat/:lng/:radio/:amount', async(req, res) => {
    const { lat, lng, radio, amount } = req.params;

    try {
        openpayStoreAxios.get(`/stores?latitud=${lat}&longitud=${lng}&kilometers=${radio}&amount=${amount}`)
            .then((result) => {
                res.status(200).send(result.data)
            }).catch((err) => {
                res.status(400).send(err.message)
            })

        // openpay.stores.list(
        //     location,
        //     function(error, body) {
        //         if (error) res.status(401).send(error.message);

        //         res.status(200).send(body)
        //     });

    } catch (error) {
        res.status(400).send(error.message);
    }



})

module.exports = router;