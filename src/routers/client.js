const express = require("express");
const router = new express.Router();
const User = require("../model/user");
const Client = require("../model/client");
const auth = require("../middleware/auth");
const sql = require('mssql');
const sqlConfig = require("./../db/connSQL");
const tbl = require('./../utils/TablesSQL');


router.post("/clients", auth, async(req, res) => {
    try {
        const client = new Client({
            ...req.body,
            user_id: req.user._id,
            status: [1,'Pendiente']
        });

        const clientNew = await client.save();
        req.user["client_id"] = clientNew._id;
        await req.user.save();

        return res.status(200).send(clientNew);
    } catch (e) {
        res.status(400).send(e + "");
    }
});

router.get("/clients/hf", auth, async(req, res) => {
    /* 
      337793 Alberto Andres Morales Morales
      272394 Oscar Alejandro Roman Diaz RODO960112HCSMZS00
      149219 Jose Roberto Chacon Escobar

      recordsets[0][0]  -> Datos personsales
      recordsets[1] Dataset -> Identificaciones
      recordsets[2] Dataset -> Datos del IFE / INE
      recordsets[3] Direcciones -> Direcciones  
      recordsets[4] Telefonos
      recordsets[5] Aval
      recordsets[6] Ciclo
      recordsets[7] Datos economicos
      */

    try {
        
        let data;
        if (req.query.externalId && req.query.identityNumber) {
            data = await Client.findClientByExternalId(req.query.externalId);
        } else
        if (req.query.identityNumber && !req.query.externalId) {
            data = await Client.findClientByCurp(req.query.identityNumber);
        } else {
            throw new Error('Some query parameters area mising...')
        }

        if (data.recordset.length == 1) {
            /// extract CURP and Ine Folio
            const curp = data.recordsets[1].find(
                (i) => i.tipo_identificacion === "CURP"
            );
            const ife = data.recordsets[1].find(
                (i) => i.tipo_identificacion === "IFE"
            );
            const rfc = data.recordsets[1].find(
                (i) => i.tipo_identificacion === "RFC"
            );


            const address = []
            for (let i = 0; i < data.recordsets[3].length; i++) {
                const add = data.recordsets[3][i]

                address.push({
                    _id: add.id,
                    type: add.tipo.trim(),

                    country: [add.id_pais,  add.nombre_pais],

                    province: [add.id_estado, add.nombre_estado],
                    municipality: [add.id_municipio, add.nombre_municipio],
                    city: [add.id_ciudad_localidad, add.nombre_ciudad_localidad],
                    colony: [add.id_asentamiento, add.nombre_asentamiento],

                    address_line1: add.direccion,
                    ext_number: add.numero_exterior,
                    int_number: add.numero_interior,
                    street_reference: add.referencia,
                    ownership: add.casa_situacion === 'RENTADO' ? true : false,
                    post_code: add.codigo_postal,
                    residence_since: add.tiempo_habitado_inicio,
                    residence_to: add.tiempo_habitado_final
                })
            }
            const phones = []
            for (let l = 0; l < data.recordsets[4].length; l++) {
                const phone = data.recordsets[4][l]
                phones.push({
                    _id: phone.id,
                    phone: phone.idcel_telefono.trim(),
                    type: phone.tipo_telefono.trim(),
                    company: phone.compania.trim(),
                    validated: false
                })
            }

            // Evalua si el Curp NO es igual al Curp suministrado, entonces devuelve not found
            if (!(curp.id_numero === req.query.identityNumber)) {
                throw new Error("Not found!");
            }

            const perSet = {
                ...data.recordsets[0][0],
            };

            const business_data = {
                economic_activity: [data.recordsets[7][0].id_actividad_economica,
                    data.recordsets[7][0].nombre_actividad_economica
                ],
                profession: [data.recordsets[7][0].id_profesion,
                    data.recordsets[7][0].nombre_profesion
                ],
                business_name: data.recordsets[7][0].nombre_negocio,
                business_start_date: data.recordsets[7][0].econ_fecha_inicio_act_productiva
            }

            const result = {
                name: perSet.name,
                lastname: perSet.lastname,
                second_lastname: perSet.second_lastname,
                email: req.user.email,
                curp: curp ? curp.id_numero : "",
                ine_folio: ife ? ife.id_numero : "",
                rfc: rfc ? rfc.id_numero : "",
                dob: perSet.dob,
                loan_cycle: 0,

                branch: [perSet.id_oficina, perSet.nombre_oficina],
                sex: [perSet.id_gender, perSet.gender],
                education_level: [perSet.id_scholarship, perSet.scholarship],

                address,
                phones,
                external_id: perSet.id,
                tributary_regime: [],

                nationality: [perSet.id_nationality, perSet.nationality],
                province_of_birth: [
                    perSet.id_province_of_birth,
                    perSet.province_of_birth,
                ],
                country_of_birth: [
                    perSet.id_country_of_birth,
                    perSet.country_of_birth,
                ],
                ocupation: [perSet.id_occupation, perSet.occupation],
                marital_status: [perSet.id_marital_status, perSet.marital_status],
                identification_type: [], // INE/PASAPORTE/CEDULA/CARTILLA MILITAR/LICENCIA
                guarantor: [],
                business_data,
                beneficiaries: [],
                personal_references: [],
                guarantee: [],
                user_id: req.user._id,
            };
            res.send(result);
        } else {
            res.status(404).send("Not found");
        }
    } catch (err) {
        res.status(404).send('Client data not found');
    }
});

router.get("/clientsDeleted", async(req, res) => {
    try {
        const client = await Client.findDeleted();
        if (!client || client.length === 0) {
            throw new Error("Not able to find the client");
        }

        res.status(200).send(client);
    } catch (e) {
        res.status(400).send(e + "");
    }
});

router.get("/clients", auth, async(req, res) => {
    const match = {};

    try {
        if (req.query.id) {
            match._id = req.query.id;
        }

        const client = await Client.find(match);
        if (!client || client.length === 0) {
            throw new Error("Not able to find the client");
        }

        res.status(200).send(client);
    } catch (e) {
        console.log(e);
        res.status(400).send(e + "");
    }
});

router.patch("/clients/:id", auth, async(req, res) => {
    try {
        const _id = req.params.id;
        const data = req.body.data;
        const actualizar = Object.keys(data);

        const client = await Client.findOne({ _id });
        if (!client) {
            throw new Error("Not able to find the client");
        }

        const user = await User.findOne({ client_id: _id });
        if (user != null) {
            actualizar.forEach((valor) => (user[valor] = data[valor]));
            await user
                .save()
                .then((result) => {})
                .catch((e) => {
                    throw new Error("Error updating user");
                });
        }

        actualizar.forEach((valor) => (client[valor] = data[valor]));
        await client.save();

        res.status(200).send(client);
    } catch (e) {
        console.log(e);
        res.status(400).send(e + "");
    }
});

router.delete("/clients/:id", auth, async(req, res) => {
    try {
        const _id = req.params.id;

        const client = await Client.findOne({ _id });
        if (!client) {
            throw new Error("Not able to find the client");
        }

        const user = await User.findOne({ client_id: client._id });
        if (user != null) {
            const userDeleted = await user.delete();
            if (!userDeleted) {
                throw new Error("Error deleting user");
            }
        }

        const clientDeleted = await client.delete();
        if (!clientDeleted) {
            throw new Error("Error deleting client");
        }

        res.status(200).send("ok");
    } catch (e) {
        res.status(400).send(e + "");
    }
});

router.post("/clients/restore/:id", auth, async(req, res) => {
    try {
        const _id = req.params.id;

        const client = await Client.findOneDeleted({ _id });
        if (!client) {
            throw new Error("Not able to find the client");
        }

        const user = await User.findOneDeleted({ client_id: client._id });
        if (user != null) {
            const userRestore = await user.restore();
            if (!userRestore) {
                throw new Error("Error restoring user");
            }
        }

        const clientRestore = await client.restore();
        if (!clientRestore) {
            throw new Error("Error restore client");
        }
        res.status(200).send("ok");
    } catch (e) {
        res.status(400).send(e + "");
    }
});

router.get('/clients/data/:idClient', async(req, res) => {
    /*  --------------------- ESTRUCTURA DE RESPUESTA ---------------------
    [
        [Datos Personales],
        [identificacion],
        [DatosIFE],
        [direcciones],
        [Telefonos]
        [Aval],
        [Ciclo],
        [Datos socioeconómicos]
    ] */
    try {
        const { idClient } = req.params;
        pool = await sql.connect(sqlConfig);

        pool.request()
            .input('idCliente', sql.Int, parseInt(idClient)) // undefined para recibir como NULL en sql Server
            .input('CURPCliente', sql.VarChar(18), undefined) // MOMA841130HCSRRL01
            .execute('MOV_ObtenerDatosPersona')
            .then((result) => {
                res.status(200).send(result.recordsets);
            }).catch((err) => {
                throw new Error(err)
            });

    } catch (error) {
        res.status(401).send(error.message)
    }
})

// ------------------- CREATE CLIENT INDIVIDUAL -------------------
router.post('/clients/hf/create', async(req, res) => { // FUNCIONA
    try {
        const result = await Client.createClientHF(req.body);

        res.status(201).send(result);

    } catch (error) {
        res.status(401).send(error.message)
    }
});

// ------------------- CREATE GROUP -------------------

router.post('/clients/hf/createGroup', async(req, res) => { // FUNCIONA
    try {
        // console.log(req.body);
        const result = await Client.createGroupHF(req.body);

        res.status(201).send(result);

    } catch (error) {
        res.status(401).send(error.message)
    }
});

// ------------------- FIN CREATE GROUP -------------------

router.get('/clients/getAccountStatus', auth, async(req, res) => {
    try {
        const result = await Client.getAccountStatus(req.query.idClient);

        res.status(201).send(result);
    } catch(error){
        console.log(error.message);
        res.status(401).send(error.message);
    }
})

router.get('/clients/createContract', auth, async(req, res) => {
    try {
        const result = await Client.createContractHF(req.query.idLoan);

        res.status(201).send(result.toString());
    } catch(error){
        console.log(error.message);
        res.status(401).send(error.message);
    }
})

// CREAR REFERENCIA DE GARANTÍA LÍQUIDA -> idCliente
router.get('/clients/createReference', auth, async(req, res) => {
    try {
        //TODO: typeReference: 1 -> id: Crédito por id_cliente
        //      typeReference: 2 -> id: Garantía Líquida por id_cliente
        //      typeReference: 3 -> id: Pago de moratorios por id_cliente
        //      typeReference: 6 -> id: Pago de crédito por id_contrato
        const {typeReference, id} = req.query;
        const result = await Client.createReference(typeReference, id);

        res.status(201).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
})

router.get('/clients/getOficialCredito', async(req, res) => {
    try {
        const result = await Client.getOficialCredito(req.query.idOffice);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
})

router.get('/clients/getBalance', async(req, res) => {
    
    try{
        const result = await Client.getBalanceById(req.query.idClient);
    
        res.send(result);
    } catch (error) {
        res.status(401).send(error.message)
    }
});

router.get('/clients/paymentPlan', auth, async(req, res) => {
    try {
        const result = await Client.getPaymentPlan(req.query.idContract);

        res.status(200).send(result);
    } catch(error){
        res.status(401).send(error.message);
    }
});

router.get('/admin/getloanautorizar', async(req, res) => {
    try {
        const idOffice = req.query.idOffice;
        const result = await Client.getLoanPorAutorizar(idOffice);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
});

router.post('/loans/create', async(req, res) => {
    try {
        const result = await Client.createLoanFromHF(req.body);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
});

router.post('/loans/assign_client', async(req, res) => {
    try {
        const result = await Client.assignClientLoanFromHF(req.body);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
})

router.get('/obtenerProductos', async(req, res) => {
    try {
        const result = await Client.getProductsByOffice(req.query.idOffice);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
})

router.get('/getdetallesolicitud', async(req, res) => {
    try {
        const {idLoan, idOffice} = req.query;
        const result = await Client.getDetailLoan(idLoan, idOffice);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
});

router.get('/getseguroproducto', async(req, res) => {
    try {
        const {idLoan} = req.query;
        const result = await Client.getSeguroProducto(idProductoMaestro);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
});

router.get('/getdisposicion', async(req, res) => {
    try {
        const {idOffice} = req.query;
        const result = await Client.getDisposicionByOffice(idOffice);

        res.status(200).send(result);
    } catch (error) {
        res.status(401).send(error.message);
    }
});

router.get('/getstatusloan', async(req, res) => {
    try {
        const {idLoan} = req.query;
        const result = await Client.getStatusGLByLoan(idLoan);

        res.status(200).send(result);
    } catch (error) {
        res.status(400).send(error.message);
    }
});

router.get('/rows', async(req, res) => {
    try {
        const result = await Client.checkRows();

        res.status(200).send(result);
    } catch (error) {
        res.status(400).send(error.message);
    }
});

router.post('/toAuthorizeLoan/:id', auth, async(req, res) => {

    const {idLoan} = req.query;

    try{

        const detail = await Client.getDetailLoan(idLoan, 1);
        const seguro = await Client.getStatusGLByLoan(idLoan);
        detail[0][0].fecha_primer_pago = getDates(detail[0][0].fecha_primer_pago);
        detail[0][0].fecha_entrega = getDates(detail[0][0].fecha_entrega);
        detail[0][0].fecha_creacion = getDates(detail[0][0].fecha_creacion);

        if(seguro.estatus === "FALTA G.L."){
            throw new Error("No se puede realizar la accion debido a que falta la garantia liquida")
        }

        const result = await Client.toAuthorizeLoanHF(detail, seguro);
        const detail2 = await Client.getDetailLoan(idLoan, 1);


        res.status(200).send(result);


    }
    catch(err){
        res.status(400).send(err + '')
    }
});

router.get('/getNotarial', async(req, res) => {
    const { idLoan, idOffice } = req.query;

    console.log({ idLoan, idOffice });

    const result = await Client.getPoderNotarialByOfficeYFondo(idLoan, idOffice);

    res.status(200).send(result);
})

router.get('/homonimo', async(req, res) => {
    const { nombre, apellidoPaterno, apellidoMaterno } = req.query;

    const result = await Client.getHomonimoHF(nombre, apellidoPaterno, apellidoMaterno);

    res.status(200).send(result);
})

const removeAccents = (str) => {
    return str
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .toUpperCase();
};

const comparar = (entrada) => {
    const permitido = [
        "name",
        "lastname",
        "second_lastname",
        "email",
        "password",
        "curp",
        "ine_folio",
        "dob",
        "segmento",
        "loan_cicle",
        "client_type",
        "branch",
        "is_new",
        "bussiness_data",
        "gender",
        "scolarship",
        "address",
        "phones",
        "credit_circuit_data",
        "external_id",
    ];
    const result = entrada.every((campo) => permitido.includes(campo));
    return result;
};

module.exports = router;