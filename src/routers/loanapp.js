const express = require("express");
const router = new express.Router();
const auth = require("../middleware/auth");
const Loanapp = require('../model/loanapp');
const passwordGenerator = require('../utils/codegenerator');

// GET obtiene el LoansApp por id
router.get('/loanapps', auth, async(req, res) => {

    const match = {};
    match.apply_by = req.user._id;
    try {
        if (req.query.id) {
            match._id = req.query.id;
        }

        const loan = await Loanapp.find(match);
        for( let i=0; i < loan.length; i++){
            await loan[i].populate('product').execPopulate();
            const d1 = await loan[i].populate('apply_by').execPopulate();
            await d1.apply_by.populate('client_id').execPopulate();
        }

        res.status(200).send(loan);
    } catch (e) {
        console.log(e);
        res.status(400).send(e + "");
    }

});

router.post('/loanapps', auth, async (req, res)=>{
    try {
        const loan_app_code = passwordGenerator(6)
        const newLoanApp = new Loanapp({
            ...req.body,
            status: [1,'Pendiente'],
            apply_by: req.user._id,
            apply_at: new Date(),
            loan_app_code
        })
        await newLoanApp.save();
        res.send(newLoanApp);

    }
    catch(error){
        console.log(error);
        res.status(400).send(error);
    }
})

router.get('/loanapps/getInfoLoan', async (req, res) => {
    try {
        const {idLoan, idOffice} = req.query;
        const result = await Loanapp.getInfoLoan(idLoan, idOffice);

        res.status(200).send(result);
    } catch (error) {
        res.status(400).send(error.message);
    }
})


module.exports = router