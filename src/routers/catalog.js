const express = require("express");
const router = new express.Router();
const auth = require("./../middleware/auth");

const Neighborhood = require("../model/neighborhood");
const City = require('../model/city');
const Municipality = require('../model/municipality');
const Province = require('../model/province');
const Country = require('../model/country');

const Catalog = require("./../model/catalog");


router.post("/catalogs", auth, async (req, res) => {
// Devuelte N catalogos con base en el array CATALOGS especificado en el req.body
    try {
        if( !req.body.catalogs ){
            throw new Error('You need to include a valid *catalog[catalog_name1,catalog_name2,catalog_name3]* query parameter!')
        }
        if( !req.query.limit){
            throw new Error('You need to include a valid *limit* query parameter!')
        }
        if( !req.query.skip){
            throw new Error('You need to include a valid *skip* query parameter!')
        }
        const match = {
            name: { $in: req.body.catalogs}
        }

        const options = {
            limit: parseInt(req.query.limit),
            skip: parseInt(req.query.skip)
        }

        const data = await Catalog.find( match,null,options )
        
        res.send(data)
    
    }
    catch(err) {
        res.status(400).send('You need to include a valid cata_id, limit and skip URL parameters!')
    }
    
});

router.get('/catalogs/sync', auth, async (req,res) => {
    try{

        await Country.updateFromHF(1000);
        await Province.updateFromHF(1000);
        await Municipality.updateFromHF(1000);
        await City.updateFromHF(1000);
        await Neighborhood.updateFromHF(1000);

    
        await Catalog.updateCatalogFromHF('CATA_ActividadEconomica',10000)
        await Catalog.updateCatalogFromHF('CATA_sexo',10000)
        await Catalog.updateCatalogFromHF('CATA_sector',10000)
        await Catalog.updateCatalogFromHF('CATA_escolaridad',10000)
        await Catalog.updateCatalogFromHF('CATA_estadoCivil',10000)
        await Catalog.updateCatalogFromHF('CATA_nacionalidad',10000)
        await Catalog.updateCatalogFromHF('CATA_ocupacion',10000)
        await Catalog.updateCatalogFromHF('CATA_parentesco',10000)
        await Catalog.updateCatalogFromHF('CATA_profesion',10000)
        await Catalog.updateCatalogFromHF('CATA_TipoRelacion',10000)
        await Catalog.updateCatalogFromHF('CATA_TipoPuesto',10000)
        await Catalog.updateCatalogFromHF('CATA_TipoVialidad',10000)


        res.send('Done!')
    }
    catch(error){
        console.log(error);
        res.status(401).send(error)
    }
})


module.exports = router;
