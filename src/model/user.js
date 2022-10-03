const mongoose = require('mongoose')
const validador = require('validator')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken');
const sqlConfig = require("./../db/connSQL");
const sql = require('mssql');
const tbl = require('./../utils/TablesSQL');


const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    lastname: {
        type: String,
        trim: true,
        required: true
    },
    email: {
        type: String,
        unique: true,
        required: true,
        trim: true,
        validate(value) {
            if (!(validador.isEmail(value))) {
                throw new Error('Correo electronico no valido..')
            }
        }
    },
    password: {
        type: String,
        trim: true
    },
    selfi: {
        type: Buffer,
        required: false
    },
    tokens: [{
        token: {
            type: String,
            required: true
        }
    }],
    client_id: {type: mongoose.Schema.Types.ObjectId, ref: 'Client'},
    veridoc: { type: mongoose.Schema.Types.ObjectId, ref: 'Identityimg'}

}, { timestamps: true })


userSchema.methods.generateAuthToken = async function() {
    const user = this

    /// adds 5 hours of token expiration
    const expires_at = new Date();
    expires_at.setHours(expires_at.getHours() + 5);

    const jwt_secret_key = process.env.JWT_SECRET_KEY
    const token = jwt.sign({ _id: user._id.toString(), expires_at }, jwt_secret_key)

    user.tokens = user.tokens.concat({ token })
    await user.save();

    return token
}

userSchema.methods.toJSON = function() {
    const user = this

    const userPublic = user.toObject()

    delete userPublic._id;
    delete userPublic.password
    delete userPublic.tokens
    delete userPublic.selfi

    return userPublic


}


userSchema.statics.findUserByCredentials = async(email, password) => {

    const user = await User.findOne({ email })
    if (!user) {
        throw new Error('No puede logearse...')
    }
    const isMatch = await bcrypt.compare(password, user.password)
    if (!isMatch) {
        throw new Error('No puede logearse...')
    }

    return user
}

userSchema.statics.createPersonHF = async(data) => {
    const pool = await sql.connect(sqlConfig);

    // TODO: ENVIAR LOS id´s CUANDO SE TENGA QUE ACTUALIZAR DE LO CONTRARIO ENVIAR 0

    for (const idx in data['DIRECCIONES']) {
        tbl.UDT_CONT_DireccionContacto.rows.add(
            data['DIRECCIONES'][idx].id,
            data['DIRECCIONES'][idx].tipo,
            data['DIRECCIONES'][idx].id_pais,
            data['DIRECCIONES'][idx].id_estado, // CATA_Estado
            data['DIRECCIONES'][idx].id_municipio, // CATA_municipio
            data['DIRECCIONES'][idx].id_localidad, // CATA_Ciudad_Localidad
            data['DIRECCIONES'][idx].id_asentamiento,
            data['DIRECCIONES'][idx].direccion, // CONT_Direcciones
            data['DIRECCIONES'][idx].numero_exterior,
            data['DIRECCIONES'][idx].numero_interior,
            data['DIRECCIONES'][idx].referencia,
            data['DIRECCIONES'][idx].casa_situacion, // 0-Rentado, 1-Propio (SOLO DOMICILIO)
            data['DIRECCIONES'][idx].tiempo_habitado_inicio,
            data['DIRECCIONES'][idx].tiempo_habitado_final,
            data['DIRECCIONES'][idx].correo_electronico,
            data['DIRECCIONES'][idx].num_interior,
            data['DIRECCIONES'][idx].num_exterior,
            data['DIRECCIONES'][idx].id_vialidad, // CATA_TipoVialidad
            data['DIRECCIONES'][idx].domicilio_actual // 0-Rentado, 1-Propio, 3-No Aplica (SOLO DOMICILIO -> Capturar el dato si el producto es Tu Hogar con Conserva)
        )
    }

    tbl.UDT_CONT_Persona.rows.add(
        data['DATOS_PERSONALES'][0].id,
        data['DATOS_PERSONALES'][0].nombre,
        data['DATOS_PERSONALES'][0].apellido_paterno,
        data['DATOS_PERSONALES'][0].apellido_materno,
        data['DATOS_PERSONALES'][0].fecha_nacimiento,
        data['DATOS_PERSONALES'][0].id_sexo,
        data['DATOS_PERSONALES'][0].id_escolaridad,
        data['DATOS_PERSONALES'][0].id_estado_civil,
        data['DATOS_PERSONALES'][0].entidad_nacimiento,
        data['DATOS_PERSONALES'][0].regimen,
        data['DATOS_PERSONALES'][0].id_oficina,
        data['DATOS_PERSONALES'][0].curp_fisica, // curp_fisica (SIEMPRE EN 0, NO SE USA)
        data['DATOS_PERSONALES'][0].datos_personales_diferentes_curp,
        data['DATOS_PERSONALES'][0].id_entidad_nacimiento,
        data['DATOS_PERSONALES'][0].id_nacionalidad,
        data['DATOS_PERSONALES'][0].id_pais_nacimiento,
        data['DATOS_PERSONALES'][0].es_pep,
        data['DATOS_PERSONALES'][0].es_persona_prohibida
    );

    for (const idx in data['IDENTIFICACIONES']) {
        tbl.UDT_CONT_Identificaciones.rows.add(
            data['IDENTIFICACIONES'][idx].id, // ID
            data['IDENTIFICACIONES'][idx].id_entidad, //IdPersona
            data['IDENTIFICACIONES'][idx].tipo_identificacion,
            data['IDENTIFICACIONES'][idx].id_numero, // CURP -> Validar desde el Front, debe estar compuesto por 4 letras - 6 números - 6 letras - 1 letra o número - 1 número
            data['IDENTIFICACIONES'][idx].id_direccion,
            0//1 -> persona, 2->Empresa
        );
    }
    //Son para CURP Fisica (NO SE USA)
    tbl.UDT_CONT_CURP.rows.add(
        data['IDENTIFICACIONES'].filter(item => item.tipo_identificacion == 'CURP')[0].id_curp,
        0,
        '',
        '',
        0,
        ''
    );

    tbl.UDT_CONT_IFE.rows.add(
        data['DATOS_IFE'][0].id,
        '', // Clave de elector - 18 Caracteres TODO: FILTRAR EL NUMERO DEL IFE DE IDENTIFICACIONES
        data['DATOS_IFE'][0].numero_emision,
        data['DATOS_IFE'][0].numero_vertical_ocr
    );

    tbl.UDT_CONT_Telefonos.rows.add(
        data['TELEFONOS'][0].id, //
        data['TELEFONOS'][0].idcel_telefono, // número de Telefono
        '', // extension (No se usa)
        data['TELEFONOS'][0].tipo_telefono, // Casa/Móvil/Caseta/Vecinto/Trabajo
        data['TELEFONOS'][0].compania, // Telcel/Movistar/Telmex/Megacable/Axtel
        data['TELEFONOS'][0].sms // 0-False, 1-True
    );

    const result = await pool.request()
        .input('DATOSDireccion', tbl.UDT_CONT_DireccionContacto)
        .input('DATOSPersona', tbl.UDT_CONT_Persona)
        .input('DATOSIdentificacion', tbl.UDT_CONT_Identificaciones)
        .input('DATOSCurp', tbl.UDT_CONT_CURP)
        .input('DATOSIfe', tbl.UDT_CONT_IFE)
        .input('DATOSTelefono', tbl.UDT_CONT_Telefonos)
        .input('etiqueta_opcion', sql.VarChar(50), 'INSERTAR_PERSONA') // INSERTAR_PERSONA/ACTUALIZAR_PERSONA
        .input('id_session', sql.Int, 0) // Quien manda la informacion
        .execute("MOV_AdministrarInformacionPersona")

    tbl.cleanTable(tbl.UDT_CONT_DireccionContacto);
    tbl.cleanTable(tbl.UDT_CONT_Persona);
    tbl.cleanTable(tbl.UDT_CONT_Identificaciones);
    tbl.cleanTable(tbl.UDT_CONT_CURP);
    tbl.cleanTable(tbl.UDT_CONT_IFE);
    tbl.cleanTable(tbl.UDT_CONT_Telefonos);

    return result.recordsets;
}

const User = mongoose.model('User', userSchema)

module.exports = User