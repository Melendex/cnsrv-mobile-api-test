const express = require("express");
const router = new express.Router();
const auth = require("../middleware/auth");
const Identityimg = require('../model/identityimg');
const axios = require('axios');
const url = require('url');

// GET obtiene todas las IdentityImgs del usuario
router.get('/veridoc', auth, async(req, res) => {

    try {

        await req.user.populate('veridoc').execPopulate();
        res.status(200).send(req.user.veridoc);

    } catch (e) {
        res.status(400).send(e);
    }

});

router.post('/veridoc', auth, async (req, res)=>{
    try {
        const newIdentityimg = new Identityimg({
            ...req.body,
            status: [1,'Pending'],
            user_id: req.user._id
        })
        
        await newIdentityimg.save();
        req.user.veridoc = newIdentityimg._id
        await req.user.save();

        res.send('Identity Images Created...');

    }
    catch(error){
        console.log(error);
        res.status(400).send(error);
    }
})

router.get('/veridoc/token', auth, async (req, res )=>{
try{
    const api = axios.create({
        method: 'post',
        url: '/auth/token',
        baseURL: process.env.VERIDOC_URL,
        headers: { 'content-type': 'application/x-www-form-urlencoded' }
    })
    const params = new url.URLSearchParams({
        grant_type: 'client_credentials',
        client_id: process.env.VERIDOC_CLIENT_ID,
        client_secret: process.env.VERIDOC_CLIENT_SECRET,
        audience: 'veridocid'
    });
    const veridocRes = await api.post('/auth/token', params);
    const veridoc_token = veridocRes.data.access_token;
    res.send( { veridoc_token }     )

    }
    catch(error){
        res.status(400).send(error);
    }
})

module.exports = router