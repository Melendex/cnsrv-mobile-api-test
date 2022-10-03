const mongoose = require("mongoose");
const sqlConfig = require("./../db/connSQL");
const sql = require('mssql');
const tbl = require('./../utils/TablesSQL');

const loanappSchema = new mongoose.Schema({
    product: {
       type: mongoose.Schema.Types.ObjectId,
       ref: 'Product',
       required: true
    },
    loan_app_code: {
        type: String,
        required: true  
    },
    status: [],
    apply_by: { type: mongoose.Schema.Types.ObjectId, ref: 'User'},
    apply_at: { type: Date, required: true },
    approved_at: { type: Date, required: false },
    approved_by: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false},
    apply_amount: { type: String,required: true },
    approved_amount: { type: String,required: false },
    term: { type: Number, required: true },
    frequency: [],
    schedule: [{
        number: { type: Number, required: true},
        balance: { type: Number, required: true},
        principal: { type: Number, required: true},
        interest: { type: Number, required: true},
        tax: { type: Number, required: true},
        insurance: { type: Number, required: true},
        due_date: { type: Date, required: false}
    }]
});

loanappSchema.statics.getInfoLoan = async(idLoan, idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('id_solicitud', sql.Int, idLoan)
            .input('id_oficina', sql.Int, idOffice)
            .execute('MOV_ObtenerSolicitudClienteServicioFinanciero_V2');

        return result.recordsets;
    } catch (err){
        throw new Error(err)
    }

}

const Loanapp = mongoose.model("Loanapp", loanappSchema);
module.exports = Loanapp;