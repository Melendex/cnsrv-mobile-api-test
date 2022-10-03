
const mongoose = require("mongoose");
const mongoose_delete = require("mongoose-delete");
const validador = require("validator");
const sqlConfig = require("../db/connSQL");
const sql = require("mssql");
const tbl = require('./../utils/TablesSQL');
const { UTD_CLIE_Clientes } = require("./../utils/TablesSQL");


const clientSchema = new mongoose.Schema({
    name: {
        type: String,
        trim: true,
        uppercase: true,
    },
    lastname: {
        type: String,
        trim: true,
        uppercase: true,
    },
    second_lastname: {
        type: String,
        trim: true,
        uppercase: true,
    },
    email: {
        type: String,
        unique: true,
        required: true,
        trim: true,
        validate(value) {
            if (!validador.isEmail(value)) {
                throw new Error("Correo electronico no válido..");
            }
        },
    },
    curp: {
        type: String,
        unique: true,
        trim: true
    },
    ine_folio: {
        type: String,
        trim: true,
        required: false,
    },
    dob: {
        type: Date,
        required: false,
    },
    loan_cycle: {
        //Cuántos creditos ha tenido el cliente
        type: String,
        required: false,
    },
    branch: [],
    sex: [],
    education_level: [],
    address: [{
        _id: { type: Number },
        type: { type: String },
        country: [],
        province: [],
        municipality: [],
        city: [],
        colony: [],
        address_line1: { type: String },
        ext_number: { type: String },
        int_number: { type: String },
        street_reference: { type: String },
        ownership: { type: Boolean },
        post_code: { type: String },
        residence_since: { type: Date },
        residence_to: { type: Date }
    }],
    phones: [{
        _id: {
            type: Number
        },
        phone: {
            type: String,
            required: true
        },
        type: {
            type: String,
            default: 'Móvil',
            trim: true,
        },
        company: {
            type: String,
            required: false,
        },
        validated: {
            type: Boolean,
            default: false,
            required: true
        },
        validatedAt: {
            type: Date,
            required: false
        }
    },],
    external_id: {
        type: String,
        trim: true,
    },
    //TODO:Campos nuevos
    tributary_regime: [],
    rfc: {
        type: String,
        trim: true,
    },
    nationality: [],
    province_of_birth: [],
    country_of_birth: [],
    ocupation: [],
    marital_status: [],
    identification_type: [], // INE/PASAPORTE/CEDULA/CARTILLA MILITAR/LICENCIA
    guarantor: [{
        name: {
            type: String,
            trim: true,
            uppercase: true,
        },
        lastname: {
            type: String,
            trim: true,
            uppercase: true,
        },
        second_lastname: {
            type: String,
            trim: true,
            uppercase: true,
        },
        dob: {
            type: Date,
            required: false,
        },
        sex: [],
        nationality: [],
        province_of_birth: [],
        country_of_birth: [],
        rfc: {
            type: String,
            trim: true,
        },
        curp: {
            type: String,
            trim: true
        },
        ocupation: [],
        e_signature: {
            type: String,
            trim: true,
        },
        marital_status: [],
        phones: [{
            phone: {
                type: String,
                trim: true,
            },
            phone_type: {
                type: String,
                trim: true,
            },
        },],
        email: {
            type: String,
            trim: true,
        },
        identification_type: [],
        identification_number: {
            type: String,
            trim: true,
        },
        company_works_at: {
            type: String,
            trim: true,
        },
        address: [],
        person_resides_in: {
            type: String,
            trim: true,
        },
    },],
    business_data: {
        economic_activity: [],
        profession: [],
        business_name: { type: String },
        business_start_date: { type: Date }
    },
    beneficiaries: [{
        name: {
            type: String,
            trim: true,
            uppercase: true,
        },
        lastname: {
            type: String,
            trim: true,
            uppercase: true,
        },
        second_lastname: {
            type: String,
            trim: true,
            uppercase: true,
        },
        dob: {
            type: Date,
            required: false,
        },
        relationship: [],
        phones: [{
            phone: {
                type: String,
                trim: true,
            },
            phone_type: {
                type: String,
                trim: true,
            },
        },],
        percentage: {
            //Verificar que del total de beneficiarios sume 100%
            type: String,
            trim: true,
            uppercase: true,
        },
        address: [],
    },],
    personal_references: [],
    guarantee: [],
    status: [],
    user_id: {},
}, { timestamps: true });

clientSchema.methods.toJSON = function () {
    const client = this;

    const clientPublic = client.toObject();
    delete clientPublic.deleted;

    return clientPublic;
};

clientSchema.statics.passwordHashing = async (password) => {
    return bcrypt.hash(password, 8);
};

clientSchema.statics.findClientByCurp = async (curp) => {
    // buscar un cliente por curp;
};

clientSchema.statics.findClientByExternalId = async (externalId) => {
    try {

        let pool = await sql.connect(sqlConfig);
        let result = await pool
            .request()
            .input("idCliente", sql.Int, parseInt(externalId))
            .execute("MOV_ObtenerDatosPersona");
        return result;
    } catch (err) {
        console.log(err)
        return err;
    }
};

clientSchema.statics.findClientByCurp = async (curp) => {
    try {

        let pool = await sql.connect(sqlConfig);
        let result = await pool
            .request()
            .input("CURPCliente", sql.VarChar, curp)
            .execute("MOV_ObtenerDatosPersona");
        return result;
    } catch (err) {
        console.log(err)
        return err;
    }

};


clientSchema.statics.createClientHF = async (data) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const cleanAllTables = () => {
            tbl.cleanTable(tbl.UDT_CONT_Empresa);
            tbl.cleanTable(tbl.UDT_CONT_Direcciones);
            tbl.cleanTable(tbl.UDT_CONT_Oficinas);
            tbl.cleanTable(tbl.UDT_CONT_Persona);
            tbl.cleanTable(tbl.UDT_CONT_Telefonos);
            tbl.cleanTable(tbl.UDT_CONT_Identificaciones);
            tbl.cleanTable(tbl.UDT_CONT_Negocios);
            tbl.cleanTable(tbl.UTD_CLIE_Clientes);
            tbl.cleanTable(tbl.UDT_CLIE_Individual);
            tbl.cleanTable(tbl.UDT_CLIE_Solicitud);
            tbl.cleanTable(tbl.UDT_CLIE_DatoBancario);
            tbl.cleanTable(tbl.UDT_SPLD_DatosCliente);
            tbl.cleanTable(tbl.UDT_CONT_FirmaElectronica);
        }

        tbl.UDT_CONT_Empresa.rows.add(
            472669,
            data["NEGOCIO"][0].nombre,
            data["NEGOCIO"][0].rfc,
            '',
            0,
            data["NEGOCIO"][0].id_actividad_economica,
            '',
            data["NEGOCIO"][0].ventas_totales_cantidad,
            data["NEGOCIO"][0].ventas_totales_unidad.toString(),
            data["NEGOCIO"][0].revolvencia,
            data["NEGOCIO"][0].numero_empleados,
            data["NEGOCIO"][0].tiempo_actividad_incio,
            data["NEGOCIO"][0].tiempo_actividad_final,
            '',
            data["NEGOCIO"][0].econ_registro_egresos_ingresos, // 0/1
            ''
        );

        tbl.UDT_CONT_Direcciones.rows.add(
            1374659,
            '',
            data["NEGOCIO"][0].id_pais,
            data["NEGOCIO"][0].id_estado,
            data["NEGOCIO"][0].id_municipio,
            data["NEGOCIO"][0].id_ciudad,
            data["NEGOCIO"][0].id_colonia,
            data["NEGOCIO"][0].calle, //direccion
            data["NEGOCIO"][0].letra_exterior,
            data["NEGOCIO"][0].letra_interior,
            data["NEGOCIO"][0].referencia,
            data["NEGOCIO"][0].casa_situacion,
            data["NEGOCIO"][0].tiempo_actividad_incio,
            data["NEGOCIO"][0].tiempo_actividad_final,
            data["NEGOCIO"][0].correo_electronico,
            data["NEGOCIO"][0].num_exterior,
            data["NEGOCIO"][0].num_interior,
            data["NEGOCIO"][0].id_vialidad
        );

        tbl.UDT_CONT_Oficinas.rows.add(
            473542,
            472669,
            1374659,
            0,
            data["NEGOCIO"][0].nombre_oficina + 'MOD',
            'AC',
            'AC',
            'AC',
            'AC',
            'AC',
            'ACC'
        );

        tbl.UDT_CONT_Telefonos.rows.add(
            838813,
            data["TELEFONO"][0].idcel_telefono,
            '',
            data["TELEFONO"][0].tipo_telefono,
            data["TELEFONO"][0].compania,
            data["TELEFONO"][0].sms
        )

        const empresa = await pool.request()
            .input('tablaEmpresa', tbl.UDT_CONT_Empresa)
            .input('tablaDirecciones', tbl.UDT_CONT_Direcciones)
            .input('tablaOficinas', tbl.UDT_CONT_Oficinas)
            .input('tablaTelefonos', tbl.UDT_CONT_Telefonos)
            .input('id_opcion', sql.Int, 1) // 1-Insertar/2-Actualizar
            .input('id_sesion', sql.Int, 0)
            .execute('MOV_AdministrarEmpresa')
        cleanAllTables();

        console.log(empresa.recordsets);
        // return empresa.recordsets;
        const id_empresa = empresa.recordsets[0][0].id_resultado;
        const id_direccion = empresa.recordsets[0][1].id_resultado;
        const id_oficina = empresa.recordsets[0][2].id_resultado;
        const id_telefono = empresa.recordsets[0][3].id_resultado;
        // console.log({
        //     id_empresa,
        //     id_direccion,
        //     id_oficina,
        //     id_telefono
        // })
        // return {
        //     id_empresa,
        //     id_direccion,
        //     id_oficina,
        //     id_telefono
        // };


        //#region CREATE CLIENT
        tbl.UDT_CONT_Persona.rows.add(data["PERSONA"][0].id, null, null,
            null, null, null, null, null, null,
            null, null, null, null, null, null,
            null, null, null);

        tbl.UDT_CONT_Identificaciones.rows.add( // NO SE USA
            0,
            0,
            'PROSPERA',
            '',
            0,
            1
        );

        tbl.UDT_CONT_Telefonos.rows.add(
            0,
            data["TELEFONO"][0].idcel_telefono,
            data["TELEFONO"][0].extension,
            data["TELEFONO"][0].tipo_telefono,
            data["TELEFONO"][0].compania,
            data["TELEFONO"][0].sms
        );

        tbl.UDT_CONT_Negocios.rows.add(0,
            data["PERSONA"][0].id,
            id_oficina,
            data["NEGOCIO"][0].nombre_oficina,
            data["NEGOCIO"][0].nombre_puesto,
            data["NEGOCIO"][0].departamento,
            id_empresa,
            data["NEGOCIO"][0].numero_empleados,
            data["NEGOCIO"][0].registro_egresos,
            data["NEGOCIO"][0].revolvencia,
            data["NEGOCIO"][0].ventas_totales_cantidad,
            data["NEGOCIO"][0].ventas_totales_unidad,
            data["NEGOCIO"][0].id_actividad_economica,
            data["NEGOCIO"][0].tiempo_actividad_incio,
            data["NEGOCIO"][0].tiempo_actividad_final
        );

        tbl.UTD_CLIE_Clientes.rows.add(
            0, // TODO: Se debe mandar el id para actualizar
            null,
            null,
            null,
            data["CLIENTE"][0].id_oficina,
            data["CLIENTE"][0].id_oficial_credito,
            '0000000000', // En desuso
            null);

        tbl.UDT_CLIE_Individual.rows.add(0,
            0,
            data["INDIVIDUAL"][0].econ_ocupacion, // CATA_ocupacionPLD (enviar la etiqueta ej. EMPLEADA) YA NO SE USA
            data["INDIVIDUAL"][0].econ_id_actividad_economica, // CATA_ActividadEconomica (los que tengan FINAFIM)
            data["INDIVIDUAL"][0].econ_id_destino_credito, // CATA_destinoCredito
            data["INDIVIDUAL"][0].econ_id_ubicacion_negocio, // CATA_ubicacionNegocio
            data["INDIVIDUAL"][0].econ_id_rol_hogar, // CATA_rolHogar
            id_empresa,
            data["INDIVIDUAL"][0].econ_cantidad_mensual, // Ej. 2000.0
            data["INDIVIDUAL"][0].econ_sueldo_conyugue,
            data["INDIVIDUAL"][0].econ_otros_ingresos,
            data["INDIVIDUAL"][0].econ_otros_gastos,
            data["INDIVIDUAL"][0].econ_familiares_extranjeros,
            data["INDIVIDUAL"][0].econ_parentesco,
            data["INDIVIDUAL"][0].envia_dinero, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].econ_dependientes_economicos,
            data["INDIVIDUAL"][0].econ_pago_casa,
            data["INDIVIDUAL"][0].econ_gastos_vivienda,
            data["INDIVIDUAL"][0].econ_gastos_familiares,
            data["INDIVIDUAL"][0].econ_gastos_transporte,
            data["INDIVIDUAL"][0].credito_anteriormente, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].mejorado_ingreso, // 0/1 (NO/SI) 
            data["INDIVIDUAL"][0].lengua_indigena, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].habilidad_diferente, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].utiliza_internet, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].utiliza_redes_sociales, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].id_actividad_economica, // 0/1 (NO/SI)
            data["INDIVIDUAL"][0].id_ocupacion, // CATA_ocupacionPLD
            data["INDIVIDUAL"][0].id_profesion
        );

        tbl.UDT_CLIE_Solicitud.rows.add(0, null, null, null, null, null, null);

        // tbl.UDT_CLIE_DatoBancario.rows.add(0, null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null,
        //     null
        // );
        tbl.UDT_CLIE_DatoBancario.rows.add(0, null,
            data["BANCARIO"][0].id_banco,
            data["BANCARIO"][0].clave_banco,
            data["BANCARIO"][0].nombre_banco,
            data["BANCARIO"][0].id_tipo_cuenta,
            data["BANCARIO"][0].clave_tipo_cuenta,
            data["BANCARIO"][0].nombre_tipo_cuenta,
            data["BANCARIO"][0].numero_cuenta,
            data["BANCARIO"][0].principal,
            data["BANCARIO"][0].activo);

        tbl.UDT_SPLD_DatosCliente.rows.add(0, null,
            data["PLD"][0].desempenia_funcion_publica,
            data["PLD"][0].desempenia_funcion_publica_cargo,
            data["PLD"][0].desempenia_funcion_publica_dependencia,
            data["PLD"][0].familiar_desempenia_funcion_publica,
            data["PLD"][0].familiar_desempenia_funcion_publica_cargo,
            data["PLD"][0].familiar_desempenia_funcion_publica_dependencia,
            data["PLD"][0].familiar_desempenia_funcion_publica_nombre,
            data["PLD"][0].familiar_desempenia_funcion_publica_paterno,
            data["PLD"][0].familiar_desempenia_funcion_publica_materno,
            data["PLD"][0].familiar_desempenia_funcion_publica_parentesco,
            data["PLD"][0].id_instrumento_monetario);

        tbl.UDT_CONT_FirmaElectronica.rows.add(
            data["EFIRMA"][0].id_firma_electronica,
            data["PERSONA"][0].id,
            data["EFIRMA"][0].fiel
        );

        const result = await pool.request()
            .input('info_persona', tbl.UDT_CONT_Persona)
            .input('info_identificaciones', tbl.UDT_CONT_Identificaciones)
            .input('info_telefonos', tbl.UDT_CONT_Telefonos)
            .input('info_empleos', tbl.UDT_CONT_Negocios)
            .input('info_cliente', tbl.UTD_CLIE_Clientes)
            .input('info_individual', tbl.UDT_CLIE_Individual)
            .input('info_solicitud', tbl.UDT_CLIE_Solicitud)
            .input('info_dato_bancario', tbl.UDT_CLIE_DatoBancario)
            .input('info_datos_pld', tbl.UDT_SPLD_DatosCliente)
            .input('info_firma_electronica', tbl.UDT_CONT_FirmaElectronica)
            .input('id_opcion', sql.Int, 0)
            .input('uid', sql.Int, 0)
            .execute('MOV_insertarInformacionClienteV2')

        console.log(result.recordsets)
        cleanAllTables();
        return result.recordsets;

        //#endregion


    } catch (error) {
        console.log(error);
        throw new Error(error)
    }
}

clientSchema.statics.createGroupHF = async (data) => {
    try {
        const {
            id_cliente,
            etiqueta_opcion,
            tipo_baja,
            id_motivo
         } = data;
        const pool = await sql.connect(sqlConfig);

        const cleanAllTables = () => {
            tbl.UDT_CONT_Empresa.Clear();
            tbl.UDT_CONT_Direcciones.Clear();
            tbl.UDT_CONT_Oficinas.Clear();
            tbl.UDT_CONT_Persona.Clear();
            tbl.UDT_CONT_Telefonos.Clear();
            tbl.UDT_CONT_Identificaciones.Clear();
            tbl.UDT_CONT_Negocios.Clear();
            tbl.UTD_CLIE_Clientes.Clear();
            tbl.UDT_CLIE_Individual.Clear();
            tbl.UDT_CLIE_Solicitud.Clear();
            tbl.UDT_CLIE_DatoBancario.Clear();
            tbl.UDT_SPLD_DatosCliente.Clear();
            tbl.UDT_CONT_FirmaElectronica.Clear();
        };

        //CREANDO SOLICITUD GRUPAL
        const resultLoan = await pool.request()
            .input('idUsuario', sql.Int, 0) // Creado por
            .input('idOficina', sql.Int, data['SOLICITUD'][0].id_oficina) // IdOficina
            .input('idOficialCredito', sql.Int, 0)
            .input('idTipoCliente', sql.Int, 1) //1 -> Grupo, 2 -> Individual
            .input('idServicioFinanciero', sql.Int, 1) // Es el unico que existe
            .input('cantidad', sql.Int, 1) // Numero de solicitudes a hacer
            .execute('MOV_InsertarSolicitudServicioFinanciero');

            const idLoanCreated = resultLoan.recordset[0].idSolicitud;
            const idClientGroupCreated = resultLoan.recordset[0].idCliente;

            tbl.UDT_Solicitud.rows.add(
                idLoanCreated,
                idClientGroupCreated,
                data['SOLICITUD'][0].id_oficial, // OFICIAL CREDITO debe ser el id de la persona oficial
                0, // id del producto
                data['SOLICITUD'][0].id_disposicion, // se obtiene del procedimiento asignarDisposicion
                data['SOLICITUD'][0].monto_solicitado, // Ej. 10000.00 (Es la suma del monto de todos los intrgrantes)
                data['SOLICITUD'][0].monto_autorizado, // Monto_autorizado TODO: MANDAR EN 0 DESDE MÓVIL
                data['SOLICITUD'][0].periodicidad, // Meses/Quincena (Se obtiene de configuracionMaestro)
                data['SOLICITUD'][0].plazo, // 1, 2, 3, 6, 12, 24, etc.
                'TRAMITE', // ESTATUS
                'NUEVO TRAMITE', // SUB_ESTATUS
                data['SOLICITUD'][0].fecha_primer_pago, // Ej. 2022-07-20
                data['SOLICITUD'][0].fecha_entrega, // Ej. 2022-07-20
                data['SOLICITUD'][0].medio_desembolso, // ORP -> Orden de pago / cheque
                data['SOLICITUD'][0].garantia_liquida, // Ej. 10 Se obtiene de configuracionMaestro
                '2022-07-07', // FECHA DE CREACION
                data['SOLICITUD'][0].id_oficina, // 1 por defecto
                data['SOLICITUD'][0].garantia_liquida_financiable, // 0/1 False/True
                data['SOLICITUD'][0].id_producto_maestro, // Ej. 4
                data['SOLICITUD'][0].tasa_anual // Se calcula dependiendo del plazo
            );

            tbl.Cliente.rows.add(
                idClientGroupCreated,
                data['CLIENTE'][0].ciclo, // se obtiene del cliente
                'INACTIVO', // En individual se manda vacio
                '', // SUB_ESTATUS (MANDAR VACIO)
                data['SOLICITUD'][0].id_oficial,
                data['SOLICITUD'][0].id_oficina,
                0 // 0 TODO: Ver si se requiere en el procedimiento
            );

            tbl.GrupoSolidario.rows.add(
                data['GrupoSolidario'][0].id,
                data['GrupoSolidario'][0].nombre,
                data['GrupoSolidario'][0].idDireccion, // 0 si es grupo nuevo
                data['GrupoSolidario'][0].reunionDia, // Ej. "Martes"
                data['GrupoSolidario'][0].reunionHora // Ej. 11:30 formato 24 Hrs
            );

            tbl.Direccion.rows.add(
                data["DIRECCION"][0].id, //0 si es grupo nuevo
                data["DIRECCION"][0].calle,
                data["DIRECCION"][0].id_pais,
                data["DIRECCION"][0].id_estado,
                data["DIRECCION"][0].id_municipio,
                data["DIRECCION"][0].id_localidad,
                data["DIRECCION"][0].id_colonia,
                data["DIRECCION"][0].referencia,
                data["DIRECCION"][0].num_exterior,
                data["DIRECCION"][0].num_interior,
                data["DIRECCION"][0].id_vialidad
            );

            for (const idx in data['INTEGRANTES']) {
                tbl.UDT_SolicitudDetalle.rows.add(
                    data['INTEGRANTES'][idx].id_INDIVIDUAL, // id cliente individual
                    data['SOLICITUD'][0].id,
                    data['INTEGRANTES'][idx].id_persona, // id persona
                    '', // Nombre
                    '', // Apellido paterno
                    '', // Apellido Materno
                    'TRAMITE', // ESTATUS
                    'LISTO PARA TRAMITE', // SUB_ESTATUS LISTO PARA TRAMITE
                    '', // CARGO
                    data['INTEGRANTES'][idx].monto_solicitado,
                    data['INTEGRANTES'][idx].monto_sugerido, // TODO: Se establece cuando sea POR AUTORIZAR (WEB ADMIN)
                    data['INTEGRANTES'][idx].monto_autorizado, // 0 -> desde Móvil, >0 desde WEB ADMIN 
                    0, // econ_id_actividad_economica // TODO: ver si lo ocupa el procedimiento
                    0, // CURP Fisica
                    0, // motivo
                    data['INTEGRANTES'][idx].id_medio_desembolso, //1->CHEQUE, 2->ORDEN DE PAGO, 3->TARJETA DE PAGO
                    0.00 // monto_garantia_financiable
                );
            };

            for (const idx in data['SEGURO']) {
                tbl.UDT_CLIE_DetalleSeguro.rows.add(
                    data['SEGURO'][idx].id,
                    data['SOLICITUD'][0].id,
                    data['INTEGRANTES'][idx].id_individual,
                    0,
                    data['SEGURO'][idx].id_seguro_asignacion, // a
                    '', // nombre socia
                    data['SEGURO'][idx].nombre_beneficiario, // Ej. OMAR MELENDEZ
                    data['SEGURO'][idx].parentesco, // Ej. AMIGO,PRIMO, ETC.
                    data['SEGURO'][idx].porcentaje, // Ej. 100.00
                    data['SEGURO'][idx].costo_seguro, // 1560
                    data['SEGURO'][idx].incluye_saldo_deudor,
                    0
                )
            }

            const resultRegistrarGroup = await pool.request()
            .input('tablaSolicitud', tbl.UDT_Solicitud)
            .input('tablaCliente', tbl.Cliente)
            .input('tablaGrupo', tbl.GrupoSolidario)
            .input('tablaDireccion', tbl.Direccion)
            .input('tablaPrestamoMonto', tbl.UDT_SolicitudDetalle)
            .input('seguro', tbl.UDT_CLIE_DetalleSeguro)
            .input('referencias_personales', tbl.UDT_CLIE_ReferenciasPersonales) // Se toma de la tabla CONT_Personas, si no se encuentra se tendra que dar de alta
            .input('garantias_prendarias', tbl.UDT_OTOR_GarantiaPrendaria)
            .input('tabla_TuHogarConConserva', tbl.UDT_OTOR_TuHogarConConserva)
            .input('tabla_TuHogarConConservaCoacreditado', tbl.UDT_CLIE_TuHogarConConservaCoacreditado)
            .input('idUsuario', sql.Int, 0) // PERSONA QUIEN CREA LA SOLICITUD (EMPLEADO)
            .execute('MOV_registrarActualizarSolicitudCliente');

        return resultRegistrarGroup.recordsets;
        // return resultLoan.recordset;


        // const result = await pool.request()
        //     .input('') //TODO:SKND

    } catch (error) {
        throw new Error(error)
    }
}

clientSchema.statics.getAccountStatus = async (idClient) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('id_cliente', sql.Int, idClient)
            .execute('MOV_obtenerEstadoCuenta');

        return result.recordsets;
    } catch (err) {
        throw new Error(err);
    }
}

clientSchema.statics.createContractHF = async (idLoan) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('idSolicitudPrestamo', sql.Int, idLoan)
            .output('idContratoInsertado', sql.Int)
            .execute('MOV_InsertContrato');
        console.log(result);

        const idContract = result.output.idContratoInsertado;

        return idContract;
    } catch (err) {
        console.error(err);
        throw new Error(err);
    }
}

clientSchema.statics.createReference = async (typeReference, idClient) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('tipoEvento', sql.Int, typeReference)
            .input('id_cliente', sql.Int, idClient)
            .execute('MARE_ObtenerReferenciaIntermediario');

        return result.recordset;
    } catch (err) {
        throw new Error(err);
    }
}

clientSchema.statics.getOficialCredito = async (idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('id_sucursal', sql.Int, idOffice)
            .input('id_zona', sql.Int, 0)
            .input('id_coordinador', sql.Int, 0)
            .input('codigo', sql.VarChar, 'PROM')
            .input('operacion', sql.VarChar, 'CLIENTE')
            .input('id_sesion', sql.Int, 1)
            .execute('COMM_ObtenerPlantillaPuesto');

        return result.recordset;

    } catch (err) {
        throw new Error(err);
    }
}

clientSchema.statics.getBalanceById = async (idClient) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('idCliente', sql.Int, idClient)
            .execute('MOV_ObtenerSaldoClienteById');

        return result.recordsets
    } catch (err) {
        throw new Error(err);
    }
}

clientSchema.statics.getPaymentPlan = async (idContract) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('idContrato', sql.Int, idContract)
            .execute('MOV_uspObtenerDatosTablaAmortizacion');

        return result.recordsets
    } catch (err) {
        throw new Error(err);
    }
}

clientSchema.statics.getLoanPorAutorizar = async (idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('estatus', sql.Int, 8)
            .input('idOficina', sql.Int, idOffice)
            .input('idCoordinador', sql.Int, 0)
            .input('idUsuario', sql.Int, 0)
            .execute('CLIE_getPrestamos');

        return result.recordset
    } catch (error) {
        throw new Error(error);
    }
}

clientSchema.statics.createLoanFromHF = async (data) => {
    try {
        const { idUsuario, idOficina } = data;

        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('idUsuario', sql.Int, idUsuario) // Creado por
            .input('idOficina', sql.Int, idOficina)
            .input('idOficialCredito', sql.Int, 0)
            .input('idTipoCliente', sql.Int, 2) //1 -> Grupo, 2 -> Individual
            .input('idServicioFinanciero', sql.Int, 1) // Es el unico que existe
            .input('cantidad', sql.Int, 1) // Numero de solicitudes a hacer
            .execute('MOV_InsertarSolicitudServicioFinanciero');

        return result.recordset;
    } catch (err) {
        throw new Error(err)
    }
}

clientSchema.statics.assignClientLoanFromHF = async (data) => {
    try {
        const {
            id_solicitud_prestamo,
            id_cliente,
            etiqueta_opcion,
            tipo_baja,
            id_motivo,
            uid
        } = data;

        const pool = await sql.connect(sqlConfig);

        return new Promise((resolve, reject) => {
            pool.request()
                .input("id_solicitud_prestamo", sql.Int, id_solicitud_prestamo)
                .input("id_cliente", sql.Int, id_cliente)
                .input("etiqueta_opcion", sql.VarChar(50), etiqueta_opcion) // ALTA/BAJA
                .input("tipo_baja", sql.VarChar(50), tipo_baja)
                .input("id_motivo", sql.Int, id_motivo)
                .input("uid", sql.Int, uid) // 0
                .execute('MOV_AsignacionCreditoCliente')
                .then((result) => {
                    resolve(result.recordset);
                }).catch((err) => {
                    reject(new Error(err));
                });
        });
    } catch (err) {
        console.log(error);
        throw new Error(error)
    }
}

clientSchema.statics.getProductsByOffice = async (idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('id_producto', sql.Int, 0)
            .input('id_fondeador', sql.Int, 0)
            .input('id_disposicion', sql.Int, 0)
            .input('id_servicio_financiero', sql.Int, 1)
            .input('id_tipo_cliente', sql.Int, 0)
            .input('id_oficina', sql.Int, idOffice)
            .input('id_periodicidad', sql.Int, 0)
            .input('id_tipo_contrato', sql.Int, 0)
            .input('visible', sql.Bit, 1)
            .input('producto_maestro', sql.Bit, 1)
            .execute('CATA_ObtenerProducto')

        return result.recordset;
    }
    catch (error) {
        throw new Error(error)
    }
}

clientSchema.statics.getDetailLoan = async (idLoan, idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('id_solicitud', sql.Int, idLoan)
            .input('id_oficina', sql.Int, idOffice)
            .execute('MOV_ObtenerSolicitudClienteServicioFinanciero_V2')

        return result.recordsets;
    }
    catch (error) {
        throw new Error(error)
    }
}

clientSchema.statics.getSeguroProducto = async (idProductoMaestro) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('id_producto', sql.Int, idProductoMaestro)
            .input('etiqueta_opcion', sql.VarChar, 'OBTENER_SEGURO_PRODUCTO')
            .execute('CLIE_ObtenerListaSegurosProducto')

        return result.recordsets;
    }
    catch (error) {
        throw new Error(error)
    }
}

clientSchema.statics.getDisposicionByOffice = async (idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('idTipoCliente', sql.Int, 0)
            .input('idServicioFinanciero', sql.Int, 1)
            .input('idOficina', sql.Int, idOffice)
            .input('idLocalidad', sql.Int, 0)
            .input('todasCurp', sql.Int, 1)
            .input('ciclo', sql.Int, 0)
            .input('montoSolicitado', sql.Int, 0)
            .input('montoMaximoSolicitado', sql.Int, 0)
            .execute('FUND_ASIGNAR_DISPOSICION')

        return result.recordsets;
    }
    catch (error) {
        throw new Error(error)
    }
}

clientSchema.statics.getStatusGLByLoan = async (idLoan) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const detailLoan = await pool.request()
            .input('id_solicitud', sql.Int, idLoan)
            .input('id_oficina', sql.Int, 0)
            .execute('MOV_ObtenerSolicitudClienteServicioFinanciero_V2');

        const garantia = await pool.request()
            .input('idSolicitudPrestamo', sql.Int, idLoan)
            .input('opcion', sql.Int, 0)
            .execute('CLIE_ObtenerGarantias');

        const seguro = await pool.request()
            .input('opcion', sql.VarChar, 'CONFIGURACION_SEGURO')
            .input('busqueda', sql.VarChar, '')
            .input('pagina', sql.Int, 0)
            .input('id_oficina', sql.Int, 0)
            .execute('HF_uspObtenerSeguros');

        // const loanClient = detailLoan.recordsets[0][0];
        // let idProduct = 0;

        // if(tbl.UDT_Solicitud.columns['sub_estatus'] = 'POR AUTORIZAR'){
        //     const productHF = await pool.request()
        //     .input('tasa_anual', sql.Decimal(18, 4), data['SOLICITUD'][0].tasa_anual)
        //     .input('periodicidad', sql.VarChar(50), data['SOLICITUD'][0].periodicidad)
        //     .input('periodos', sql.Int, data['SOLICITUD'][0].plazo)
        //     .input('id_producto_maestro', sql.Int, data['SOLICITUD'][0].id_producto_maestro)
        //     .output('id_producto', sql.Int)
        //     .execute('MOV_CATA_CrearProducto');
        //     idProduct = productHF.output.id_producto;
        //     console.log('id_productoo: ', productHF.output.id_producto)
        // }

        // tbl.UDT_Solicitud.rows.add(
        //     loanClient.id,
        //     loanClient.id_cliente,
        //     loanClient.id_oficial,
        //     idProduct,
        //     loanClient.id_disposicion,
        //     loanClient.monto_total_solicitado,
        //     loanClient.monto_total_autorizado,
        //     loanClient.periodicidad,
        //     loanClient.plazo,
        //     'TRAMITE',
        //     'POR AUTORIZAR',
        //     loanClient.fecha_primer_pago,
        //     loanClient.fecha_entrega,
        //     loanClient.medio_desembolso,
        //     loanClient.garantia_liquida,
        //     loanClient.fecha_creacion,
        //     loanClient.id_oficina,
        //     loanClient.garantia_liquida_financiable,
        //     loanClient.id_producto_maestro,
        //     loanClient.tasa_anual
        // )



        const montoSolicitado = detailLoan.recordsets[0][0].monto_total_solicitado;
        const glDepositado = garantia.recordset[0].montoGarantiaDadoAEmpresa;

        // console.log(detailLoan.recordsets[4][0]);
        const porcentaje = detailLoan.recordsets[0][0].garantia_liquida / 100;
        const glFinanciable = detailLoan.recordsets[4][0].monto_garantia_financiable;
        const glObligatoria = montoSolicitado * porcentaje;

        const diferenciaGL = glDepositado + glFinanciable - glObligatoria;
        var periodicidad = detailLoan.recordsets[0][0].periodicidad.toUpperCase();
        const plazo = detailLoan.recordsets[0][0].plazo;
        let multiplicadorPeriodos = 0;
        const primaSemanal = seguro.recordset[0].prima_seguro;
        const primaSemanalSaldoDeudor = seguro.recordset[0].prima_semanal_saldo_deudor;
        console.log(periodicidad);
        switch (periodicidad) {
            case 'SEMANAL': multiplicadorPeriodos = 1; break;
            case 'CATORCENAL': multiplicadorPeriodos = 2; break;
            case 'QUINCENAL': multiplicadorPeriodos = 2; break;
            case 'MENSUAL': multiplicadorPeriodos = 4; break;
            case 'BIMESTRAL': multiplicadorPeriodos = 8; break;
            case 'TRIMESTRAL': multiplicadorPeriodos = 12; break;
            case 'CUATRIMESTRAL': multiplicadorPeriodos = 16; break;
            case 'SEMESTRAL': multiplicadorPeriodos = 24; break;
            case 'ANUAL': multiplicadorPeriodos = 48; break;
            default: multiplicadorPeriodos = 0; break;
        }

        if (multiplicadorPeriodos == 0) throw new Error('Error de periodicidad');

        const montoPrimaNormal = plazo * multiplicadorPeriodos * primaSemanal;
        const montoPrimaSeguroDeudor = plazo * multiplicadorPeriodos * primaSemanalSaldoDeudor;

        let data = {
            seguroNormal: montoPrimaNormal,
            seguroSaldoDeudor: montoPrimaNormal + montoPrimaSeguroDeudor,
            'Garantía Líquida': porcentaje * 100 + '%',
            'Garantía Obligatoria': glObligatoria,
            'Depositado: ': glDepositado,
            'Financiada: ': glFinanciable,
            estatus: ''
        }

        // TODO: COMO SABER SI INCLUYE SALDO DEUDOR

        if (diferenciaGL == 0) {
            data.estatus = 'G.L. COMPLETA.'
            return data;
        } else {
            if (diferenciaGL < 0) {
                data.estatus = 'FALTA G.L.'
                return data;
            } else {
                if (diferenciaGL > 0) {
                    data.estatus = 'G.L. SOBRANTE.';
                    return data;
                }
            }
        }


    }
    catch (error) {
        throw new Error(error)
    }
}

clientSchema.statics.checkRows = async () => {
    tbl.UDT_CONT_IFE.rows.add(
        1,
        'asasasasasa',
        '22',
        'sasa233'
    );
    tbl.UDT_CONT_IFE.rows.clear();
    console.log(tbl.UDT_CONT_IFE.rows)
    return tbl.UDT_CONT_IFE.rows;
}

clientSchema.statics.toAuthorizeLoanHF = async (body, seguro) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const productHF = await pool.request()
            .input('tasa_anual', sql.Decimal(18, 4), body[0][0].tasa_anual)
            .input('periodicidad', sql.VarChar(50), body[0][0].periodicidad.toUpperCase())
            .input('periodos', sql.Int, body[0][0].plazo)
            .input('id_producto_maestro', sql.Int, body[0][0].id_producto_maestro)
            .output('id_producto', sql.Int)
            .execute('MOV_CATA_CrearProducto');
        console.log('id_productoo: ', productHF.output.id_producto)
        return productHF.output;

        tbl.UDT_Solicitud.rows.add(
            body[0][0].id,
            body[0][0].id_cliente,
            body[0][0].id_oficial, // OFICIAL CREDITO debe ser el id de la persona oficial
            // 0,
            productHF.output.id_producto, // id del producto
            body[0][0].id_disposicion, // se obtiene del procedimiento asignarDisposicion
            body[0][0].monto_total_solicitado, // Ej. 10000.00 (debe estar entre la politicas)
            body[0][0].monto_total_autorizado, // Monto_autorizado TODO: MANDAR EN 0 DESDE MÓVIL
            body[0][0].periodicidad, // Meses/Quincena (Se obtiene de configuracionMaestro)
            body[0][0].plazo, // 1, 2, 3, 6, 12, 24, etc.
            'TRAMITE',// ESTATUS
            'POR AUTORIZAR',  // SUB_ESTATUS 
            body[0][0].fecha_primer_pago, // Ej. 2022-07-20
            body[0][0].fecha_entrega, // Ej. 2022-07-20
            body[0][0].medio_desembolso, // ORP -> Orden de pago / cheque
            body[0][0].garantia_liquida, // Ej. 10 Se obtiene de configuracionMaestro
            body[0][0].fecha_creacion, // FECHA DE CREACION
            body[0][0].id_oficina, // 1 por defecto
            body[0][0].garantia_liquida_financiable, // 0/1 False/True
            body[0][0].id_producto_maestro, // Ej. 4
            body[0][0].tasa_anual // Se calcula dependiendo del plazo
            // 0
        );

        // return tbl.UDT_Solicitud.rows;

        tbl.Cliente.rows.add(
            body[1][0].id,
            body[1][0].ciclo,
            '', // estatus (MANDAR VACIO)
            '', // SUB_ESTATUS (MANDAR VACIO)
            body[0][0].id_oficial,
            body[0][0].id_oficina,
            body[0][0].tipo_cliente // 0 TODO: Ver si se requiere en el procedimiento
        );


        tbl.UDT_SolicitudDetalle.rows.add(
            body[4][0].id_individual,
            body[0][0].id,
            body[4][0].id,
            '', // Nombre
            '', // Apellido paterno
            '', // Apellido Materno
            'TRAMITE', // ESTATUS
            'POR AUTORIZAR', // SUB_ESTATUS LISTO PARA TRAMITE
            '', // CARGO
            body[0][0].monto_total_solicitado,
            body[0][0].monto_total_autorizado, // TODO: Se establece cuando sea POR AUTORIZAR (WEB ADMIN)
            body[0][0].monto_total_autorizado, // 0 -> desde Móvil, >0 desde WEB ADMIN 
            0, // econ_id_actividad_economica // TODO: ver si lo ocupa el procedimiento
            0, // CURP Fisica
            0, // motivo
            body[4][0].id_cata_medio_desembolso, //1->CHEQUE, 2->ORDEN DE PAGO, 3->TARJETA DE PAGO
            0.00 // monto_garantia_financiable
        );

        let valorSeguro;

        if (body[5][0].incluye_saldo_deudor) {
            valorSeguro = seguro.seguroSaldoDeudor
        } else {
            valorSeguro = seguro.seguroNormal
        }

        tbl.UDT_CLIE_DetalleSeguro.rows.add(
            body[5][0].id,
            body[5][0].id_solicitud_prestamo,
            body[5][0].id_individual,
            body[5][0].id_seguro,
            body[5][0].id_asignacion_seguro, // a
            body[5][0].nombre_socia, // nombre socia
            body[5][0].nombre_beneficiario, // Ej. OMAR MELENDEZ
            body[5][0].parentesco, // Ej. AMIGO,PRIMO, ETC.
            body[5][0].porcentaje, // Ej. 100.00
            valorSeguro, // 1560
            body[5][0].incluye_saldo_deudor,
            body[5][0].activo
        );

        // return {
        //     solicitud: tbl.UDT_Solicitud.rows,
        //     cliente : tbl.Cliente.rows,
        //     soliDetale: tbl.UDT_SolicitudDetalle.rows,
        //     detalleSeguro: tbl.UDT_CLIE_DetalleSeguro.rows
        // };

        const result = await pool.request()
            .input('tablaSolicitud', tbl.UDT_Solicitud)
            .input('tablaCliente', tbl.Cliente)
            .input('tablaGrupo', tbl.GrupoSolidario)
            .input('tablaDireccion', tbl.Direccion)
            .input('tablaPrestamoMonto', tbl.UDT_SolicitudDetalle)
            .input('seguro', tbl.UDT_CLIE_DetalleSeguro)
            .input('referencias_personales', tbl.UDT_CLIE_ReferenciasPersonales) // Se toma de la tabla CONT_Personas, si no se encuentra se tendra que dar de alta
            .input('garantias_prendarias', tbl.UDT_OTOR_GarantiaPrendaria)
            .input('tabla_TuHogarConConserva', tbl.UDT_OTOR_TuHogarConConserva)
            .input('tabla_TuHogarConConservaCoacreditado', tbl.UDT_CLIE_TuHogarConConservaCoacreditado)
            .input('idUsuario', sql.Int, 0) // PERSONA QUIEN CREA LA SOLICITUD (EMPLEADO)
            .execute('MOV_registrarActualizarSolicitudCliente');
        // .execute('MOV_Prueba')
        //.execute('MOV_Prueba');
        const cleanAllTables = () => {
            tbl.cleanTable(tbl.UDT_Solicitud);
            tbl.cleanTable(tbl.Cliente);
            tbl.cleanTable(tbl.GrupoSolidario);
            tbl.cleanTable(tbl.Direccion);
            tbl.cleanTable(tbl.UDT_SolicitudDetalle);
            tbl.cleanTable(tbl.UDT_CLIE_DetalleSeguro);
            tbl.cleanTable(tbl.UDT_CLIE_ReferenciasPersonales);
            tbl.cleanTable(tbl.UDT_OTOR_GarantiaPrendaria);
            tbl.cleanTable(tbl.UDT_OTOR_TuHogarConConserva);
            tbl.cleanTable(tbl.UDT_CLIE_TuHogarConConservaCoacreditado);
        }
        cleanAllTables();
        // console.log(result.recordsets)

        return result.recordsets;
    } catch (err) {
        console.log(err)
        throw new Error(err);
    }
}

clientSchema.statics.getPoderNotarialByOfficeYFondo = async (idLoan, idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const fondo = await pool.request()
            .input('idPrestamo', sql.Int, idLoan)
            .execute('DISB_GetFondoByPrestamo');

        const idFondeador = fondo.recordset[0].id;

        const notarial = await pool.request()
            .input('idOficinaFinanciera', sql.Int, idOffice)
            .input('idFondeador', sql.Int, idFondeador)
            .input('idSesion', sql.Int, 0)
            .execute('OTOR_ObtenerPoderNotarialPorUsuarioOficinaYFondo');

        return notarial.recordset;
    } catch (err) {

    }
}

clientSchema.statics.getLoanByAuthorize = async (idLoan, idOffice) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const fondo = await pool.request()
            .input('estatus', sql.Int, 8)
            .input('idOficina', sql.Int, idOffice)
            .input('idCoordinador', sql.Int, 0)
            .input('idUsuario', sql.Int, 0)
            .execute('CLIE_getPrestamos');

        return notarial.recorset;
    } catch (err) {

    }
}

clientSchema.statics.getNotarialByContracto = async (idContract) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const notarial = await pool.request()
            .input('idContrato', sql.Int, idContract)
            .execute('OTOR_ObtenerPoderNotarialAsignadoAContrato');

        return notarial.recorset;
    } catch (err) {

    }
}

clientSchema.statics.getFonfoByLoan = async (idLoan) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const notarial = await pool.request()
            .input('@idPrestamo', sql.Int, idLoan)
            .execute('DISB_GetFondoByPrestamo');

        return notarial.recorset;
    } catch (err) {

    }
}


clientSchema.statics.updateCurpPersonaHF = async (idPerson, curpNueva) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('idPersona', sql.Int, idPerson)
            .input('curpNueva', sql.VarChar, curpNueva)
            .execute('MOV_ActualizarCurpPersona');

        return result.recorset;
    } catch (err) {

    }
}

clientSchema.statics.getHomonimoHF = async (nombre, apellidoPaterno, ApellidoMaterno) => {
    try {
        const pool = await sql.connect(sqlConfig);

        const result = await pool.request()
            .input('nombre', sql.VarChar, nombre)
            .input('apellido_paterno', sql.VarChar, apellidoPaterno)
            .input('apellido_materno', sql.VarChar, ApellidoMaterno)
            .execute('MOV_obtenerHomonimo');

        return result.recordset;
    } catch (err) {

    }
}

clientSchema.plugin(mongoose_delete, {
    deletedAt: true,
    deletedBy: true,
    overrideMethods: "all",
});

const Client = mongoose.model("Client", clientSchema);
module.exports = Client;
