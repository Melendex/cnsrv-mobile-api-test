const express = require("express");
const router = new express.Router();
const auth = require("./../middleware/auth");

const Neighborhood = require("./../model/neighborhood");

router.get('/neighborhood/:cp', auth, async(req,res)=>{

    /// devuelve TODOS los Asentamiento en base al codigo postal,
    // Solo devolvera un el elemento con el ID que corresponsa al asentamiento
    let match = {}    
    try{
        if( !req.params.cp ){
            throw new Error('You need to provide a valid *cp* param')
        }
        match = {
            codigo_postal: `${req.params.cp}`
        }

        if( req.query.id){
            match = { ...match, _id: parseInt(req.query.id)}
        }
        const data = await Neighborhood.find(match);

        for( let i=0; i< data.length; i++){
            const n1 = await data[i].populate('ciudad_localidad').execPopulate()
            const n2 = await n1.ciudad_localidad.populate('municipio').execPopulate();        
            const n3 = await n2.municipio.populate('estado').execPopulate();
            await n3.estado.populate('pais').execPopulate();
        }
            
        res.send(data);
    }
    catch(err){
        res.status(400).send(err)
    }
})

module.exports = router;
