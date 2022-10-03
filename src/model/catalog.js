const mongoose = require("mongoose");
const sql = require("mssql");
const sqlConfig = require("../db/connSQL");

/*
CATA_asentamiento
CATA_ciudad_localidad
CATA_municipio
CATA_estado
*/

const catalogSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true,
    },
    id: { type: Number },
    codigo_estado: { type: String },
    codigo_municipio: { type: String },
    codigo_locallidad: { type: String },
    nombre_localidad: { type: String },
    codigo_postal: { type: String },
    id_ciudad_localidad: { type: Number },
    id_municipio: { type: Number },
    id_estado: { type: Number },
    id_pais: { type: Number },
    etiqueta: { type: String },
    codigo: { type: String },
    abreviatura: { type: String },
});

catalogSchema.statics.updateCatalogFromHF = async(name, chunk) => {
    try {
        // make sure that any items are correctly URL encoded in the connection string
        await Catalog.deleteMany({ name });

        sql.connect(sqlConfig, (err) => {
            const request = new sql.Request();
            request.stream = true;
            request.query(`select * from ${name}`);

            let rowData = [];

            request.on("row", (row) => {
                rowData.push({ name, ...row });
                if (rowData.length >= chunk) {
                    request.pause();
                    Catalog.insertMany(rowData);
                    rowData = [];
                    request.resume();
                }
            });

            request.on("error", (err) => {
                console.log(err);
            });

            request.on("done", (result) => {
                Catalog.insertMany(rowData);

                rowData = [];
                request.resume();
                console.log("Done!:", result);
            });
        });
    } catch (err) {
        console.log(err);
    }
};

const Catalog = mongoose.model("Catalog", catalogSchema);
module.exports = Catalog;