--  EJECUTA TODOS LOS PROCEDIMIENTOS

USE HBMFS
GO

--#region ---------------------------------------- CREA FUNCIONES PARA EL PROCEDIMIENTO DE OBTENER DATOS DEL CLIENTE DESDE LA APP MOVIL ------------------------------------------ 

CREATE OR ALTER FUNCTION MOV_ObtenerDatosPersonales(@idPersona INT)
RETURNS TABLE
AS
	 RETURN (SELECT TOP 1
			CI.id_cliente as 'id',
			CP.nombre as 'name',
			CP.apellido_paterno as 'lastname',
			CP.apellido_materno 'second_lastname',
			CP.fecha_nacimiento as 'dob',
			CS.id as 'id_gender',
			CS.etiqueta as 'gender',
			CP.id as 'id_province_of_birth',
			CP.entidad_nacimiento as 'province_of_birth',
			PAIS.id as 'id_country_of_birth',
			PAIS.etiqueta as 'country_of_birth',
			NACIONALIDAD.id as 'id_nationality',
			NACIONALIDAD.etiqueta as 'nationality',
			COCU.id as 'id_occupation',
			COCU.etiqueta as 'occupation',
			CPROF.id as 'id_profession',
			CPROF.etiqueta as 'profession',
			CEC.id as 'id_marital_status',
			CEC.etiqueta as 'marital_status',
			LTRIM(RTRIM(TEL.idcel_telefono)) as 'phone',
			ESCO.id as 'id_scholarship',
			ESCO.etiqueta as 'scholarship',
			CLIE.id_oficina as 'id_oficina',
			Oficinas.nombre as 'nombre_oficina'
			--@curpFisica as curpFisica,
			FROM [dbo].[CLIE_Individual] AS CI
				FULL JOIN CONT_Personas AS CP ON CI.id_persona = CP.id
				FULL JOIN CATA_estadoCivil AS CEC ON CP.id_estado_civil = CEC.id
				FULL JOIN CATA_escolaridad AS ESCO ON ESCO.id = CP.id_escolaridad
				FULL JOIN CATA_sexo AS CS ON CS.id = cp.id_sexo
				FULL JOIN CATA_pais AS PAIS ON PAIS.id = CP.id_pais_nacimiento
				FULL JOIN CATA_nacionalidad AS NACIONALIDAD ON NACIONALIDAD.id = CP.id_nacionalidad
				FULL JOIN CATA_profesion AS CPROF ON CPROF.id = CI.id_profesion
				FULL JOIN CONT_TelefonosPersona AS TELP ON TELP.id_persona = CI.id_persona
				FULL JOIN CONT_Telefonos  AS TEL ON TEL.id = TELP.id
				FULL JOIN CLIE_Clientes AS CLIE ON CLIE.id = CI.id_cliente
				LEFT JOIN CORP_OficinasFinancieras AS Oficinas ON Oficinas.id = CLIE.id_oficina
				LEFT JOIN CATA_ocupacion AS COCU ON COCU.id = CI.id_ocupacion
			WHERE CP.nombre IS NOT NULL AND CI.id_persona = @idPersona)

GO


CREATE OR ALTER FUNCTION MOV_ObtenerDatosIdentificacion(@idPersona INT)
RETURNS @identificaciones TABLE (
	id INT,
	id_persona INT,
	tipo_identificacion VARCHAR(20),
	id_numero VARCHAR(50),
	id_direccion INT,
	estatus_registro VARCHAR(20)
)
AS
BEGIN

		--INFORMACION DEL IFE
		INSERT INTO @identificaciones
		SELECT CONT_IdentificacionOficial.id,
			CONT_IdentificacionOficial.id_persona,
			LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) AS tipo_identificacion,
			LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) AS id_numero,
			CONT_IdentificacionOficial.id_direccion,
			LTRIM(RTRIM(CONT_IdentificacionOficial.estatus_registro)) AS estatus_registro
		FROM CONT_IdentificacionOficial
		WHERE CONT_IdentificacionOficial.id_persona = @idPersona
		RETURN
END
GO

CREATE OR ALTER FUNCTION MOV_ObtenerDatosIFE(@idPersona INT)
RETURNS TABLE
AS
	RETURN (
	SELECT
		CONT_IFE.id_identificacion_oficial,
		CONT_IFE.numero_emision,
		CONT_IFE.numero_vertical_ocr
	FROM CONT_IFE
	INNER JOIN CONT_IdentificacionOficial
	ON CONT_IFE.id_identificacion_oficial = CONT_IdentificacionOficial.id_numero
	WHERE CONT_IdentificacionOficial.id_persona = @idPersona
	AND CONT_IdentificacionOficial.tipo_identificacion = 'IFE'
)
GO

CREATE OR ALTER FUNCTION [dbo].[MOV_ObtenerDirecciones](@idPersona INT)
RETURNS @direcciones TABLE
    (
        id INT,
        tipo CHAR(10),
        id_pais INT,
		nombre_pais VARCHAR(50),
        id_estado INT,
		nombre_estado VARCHAR(50),
        id_municipio INT,
		nombre_municipio VARCHAR(50),
        id_ciudad_localidad INT,
		nombre_ciudad_localidad VARCHAR(50),
        id_asentamiento INT,
		nombre_asentamiento VARCHAR(50),
        direccion VARCHAR(255),
        codigo_postal CHAR(5),
        numero_exterior CHAR(15),
        numero_interior CHAR (15),
        referencia VARCHAR(255),
        casa_situacion VARCHAR(20),
        tiempo_habitado_inicio DATE,
        tiempo_habitado_final DATE,
        correo_electronico VARCHAR(100)
    )
BEGIN
	INSERT INTO @direcciones
			SELECT CONT_Direcciones.id,
				'DOMICILIO',
				CONT_Direcciones.pais,
				PAIS.etiqueta,
				CONT_Direcciones.estado,
				ESTADO.etiqueta,
				CONT_Direcciones.municipio,
				MUN.etiqueta,
				CONT_Direcciones.localidad,
				CL.etiqueta,
				CONT_Direcciones.colonia,
				COL.etiqueta,
				CONT_Direcciones.direccion,
				CONT_Direcciones.codigo_postal,
				ISNULL(CONT_Direcciones.numero_exterior,'') AS numero_exterior,	
				ISNULL(CONT_Direcciones.numero_interior,'') AS numero_interior,
				ISNULL(CONT_Direcciones.referencia,'') AS referencia,	
				CASE WHEN (CONT_Direcciones.casa_situacion  = 1) THEN 'PROPIO' WHEN (CONT_Direcciones.casa_situacion  = 0) THEN 'RENTADO' END,
				CONT_Direcciones.tiempo_habitado_inicio,
				CONT_Direcciones.tiempo_habitado_final,
				CONT_Direcciones.correo_electronico
			FROM CONT_Direcciones 
			INNER JOIN CONT_Personas ON CONT_Direcciones.id = CONT_Personas.id_direccion
			INNER JOIN CATA_pais AS PAIS ON PAIS.id = CONT_Direcciones.pais
			INNER JOIN CATA_estado AS ESTADO ON ESTADO.id = CONT_Direcciones.estado
			INNER JOIN CATA_municipio AS MUN ON MUN.id = CONT_Direcciones.municipio
			INNER JOIN CATA_ciudad_localidad AS CL ON CL.id = CONT_Direcciones.localidad
			INNER JOIN CATA_asentamiento AS COL ON COL.id = CONT_Direcciones.colonia
			WHERE CONT_Direcciones.estatus_registro = 'ACTIVO' 
			AND CONT_Personas.id = @idPersona

			INSERT INTO @direcciones
			SELECT CONT_Direcciones.id,
				RTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)),
				CONT_Direcciones.pais,
				PAIS.etiqueta,
				CONT_Direcciones.estado,
				ESTADO.etiqueta,
				CONT_Direcciones.municipio,
				MUN.etiqueta,
				CONT_Direcciones.localidad,
				CL.etiqueta,
				CONT_Direcciones.colonia,
				COL.etiqueta,
				CONT_Direcciones.direccion,
				CONT_Direcciones.codigo_postal,
				LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior,''))) AS numero_exterior,	
				LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior,''))) AS numero_interior,
				ISNULL(CONT_Direcciones.referencia,'') AS referencia,	
				CASE WHEN (CONT_Direcciones.casa_situacion  = 1) THEN 'PROPIO' WHEN (CONT_Direcciones.casa_situacion  = 0) THEN 'RENTADO' END,
				CONT_Direcciones.tiempo_habitado_inicio,
				CONT_Direcciones.tiempo_habitado_final,
				CONT_Direcciones.correo_electronico
			FROM CONT_Direcciones 
			INNER JOIN CONT_IdentificacionOficial ON CONT_Direcciones.id = CONT_IdentificacionOficial.id_direccion
			INNER JOIN CATA_pais AS PAIS ON PAIS.id = CONT_Direcciones.pais
			INNER JOIN CATA_estado AS ESTADO ON ESTADO.id = CONT_Direcciones.estado
			INNER JOIN CATA_municipio AS MUN ON MUN.id = CONT_Direcciones.municipio
			INNER JOIN CATA_ciudad_localidad AS CL ON CL.id = CONT_Direcciones.localidad
			INNER JOIN CATA_asentamiento AS COL ON COL.id = CONT_Direcciones.colonia
			WHERE CONT_Direcciones.estatus_registro = 'ACTIVO' 
			AND CONT_IdentificacionOficial.id_persona = @idPersona
    
			INSERT INTO @direcciones
			SELECT CONT_Direcciones.id,
				LTRIM(RTRIM('NEGOCIO')),
				CONT_Direcciones.pais,
				PAIS.etiqueta,
				CONT_Direcciones.estado,
				ESTADO.etiqueta,
				CONT_Direcciones.municipio,
				MUN.etiqueta,
				CONT_Direcciones.localidad,
				CL.etiqueta,
				CONT_Direcciones.colonia,
				COL.etiqueta,
				CONT_Direcciones.direccion,
				CONT_Direcciones.codigo_postal,
				LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior,''))) AS numero_exterior,	
				LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior,''))) AS numero_interior,
				ISNULL(CONT_Direcciones.referencia,'') AS referencia,	
				CASE WHEN (CONT_Direcciones.casa_situacion  = 1) THEN 'PROPIO' WHEN (CONT_Direcciones.casa_situacion  = 0) THEN 'RENTADO' END,
				CONT_Direcciones.tiempo_habitado_inicio,
				CONT_Direcciones.tiempo_habitado_final,
				CONT_Direcciones.correo_electronico
			FROM CONT_Direcciones 
			INNER JOIN CONT_Oficinas ON CONT_Direcciones.id = CONT_Oficinas.id_direccion
			INNER JOIN CATA_pais AS PAIS ON PAIS.id = CONT_Direcciones.pais
			INNER JOIN CATA_estado AS ESTADO ON ESTADO.id = CONT_Direcciones.estado
			INNER JOIN CATA_municipio AS MUN ON MUN.id = CONT_Direcciones.municipio
			INNER JOIN CATA_ciudad_localidad AS CL ON CL.id = CONT_Direcciones.localidad
			INNER JOIN CATA_asentamiento AS COL ON COL.id = CONT_Direcciones.colonia
			INNER JOIN CONT_Empleados ON CONT_Oficinas.id = CONT_Empleados.id_oficina
			WHERE CONT_Empleados.id_persona= @idPersona 
			AND CONT_Empleados.estatus_registro= 'ACTIVO'
	RETURN
END
GO


CREATE OR ALTER FUNCTION MOV_ObtenerAval(@idCliente INT)
RETURNS TABLE
AS
	RETURN(
	SELECT * FROM CLIE_R_I where tipo_relacion = 'aval' and id_cliente = @idCliente
	)
GO


CREATE OR ALTER FUNCTION MOV_ObtenerCiclo(@idPersona INT)
RETURNS TABLE
AS
	RETURN(
	SELECT 
    		ISNULL(CLIE_Clientes.id, 0) AS id_cliente,
			ISNULL((SELECT MAX(OTOR_SolicitudPrestamoMonto.ciclo) FROM OTOR_SolicitudPrestamoMonto WHERE id_individual = CLIE_Clientes.id AND OTOR_SolicitudPrestamoMonto.autorizado=1), 0) AS ciclo,
			LTRIM(RTRIM(ISNULL(CLIE_Clientes.estatus, ''))) AS estatus,
			LTRIM(RTRIM(ISNULL(CLIE_Clientes.sub_estatus, ''))) AS sub_estatus,
			ISNULL(CLIE_Clientes.id_oficina, 0) AS id_oficina,
			ISNULL(CLIE_Clientes.id_oficial_credito, 0) AS id_oficial,
			ISNULL(CLIE_Clientes.folio_solicitud_credito, '') AS folio_solicitud,
			ISNULL(CLIE_Clientes.lista_negra, 0) AS lista_negra,
			ISNULL(CLIE_Clientes.activo, 0) AS activo
			FROM CONT_Personas
			INNER JOIN CLIE_Individual
			ON CONT_Personas.id = CLIE_Individual.id_persona
			INNER JOIN CLIE_Clientes
			ON CLIE_Individual.id_cliente = CLIE_Clientes.id
			WHERE CONT_Personas.id = @idPersona
	)
GO

CREATE OR ALTER FUNCTION MOV_ObtenerTelefonos(@idPersona INT)
RETURNS @Telefonos TABLE (
id INT,
idcel_telefono CHAR(20),
tipo_telefono CHAR(12),
sms BIT,
compania CHAR(20),
estatus_registro CHAR(11))
AS
BEGIN
		IF(@idPersona != 0)
		BEGIN
			INSERT INTO @Telefonos
			SELECT CONT_Telefonos.id,
				LTRIM(RTRIM(CONT_Telefonos.idcel_telefono)),
				LTRIM(RTRIM(CONT_Telefonos.tipo_telefono)),
				CONT_Telefonos.sms,
				LTRIM(RTRIM(ISNULL(CONT_Telefonos.compania, ''))) AS compania,
				CONT_Telefonos.estatus_registro
			FROM CONT_Telefonos
			INNER JOIN CONT_TelefonosPersona
			ON CONT_Telefonos.id = CONT_TelefonosPersona.id_telefono
			WHERE CONT_TelefonosPersona.id_persona = @idPersona AND CONT_Telefonos.estatus_registro='ACTIVO'
		END

		RETURN
END
GO

CREATE OR ALTER FUNCTION MOV_ObtenerDatosSocioeconomicos(@idCliente INT)
RETURNS TABLE
AS
	RETURN(
		SELECT CI.*, ACTE.etiqueta as 'nombre_actividad_economica',
		OCU.etiqueta as 'nombre_ocupacion',
		PROF.etiqueta as 'nombre_profesion',
		EMP.nombre_comercial as 'nombre_negocio'
		FROM CLIE_Individual AS CI
		INNER JOIN CATA_ActividadEconomica AS ACTE ON ACTE.id = CI.id_actividad_economica
		INNER JOIN CATA_ocupacion AS OCU ON OCU.id = CI.id_ocupacion
		INNER JOIN CATA_profesion AS PROF ON PROF.ID = CI.id_profesion
		INNER JOIN CONT_Empresas AS EMP ON EMP.ID = CI.econ_id_empresa
		WHERE CI.id_cliente = @idCliente
	)

GO

--#endregion ---------------------------------------- FIN FUNCIONES PARA EL PROCEDIMIENTO DE OBTENER DATOS DEL CLIENTE DESDE LA APP MOVIL ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE OBTENER DATOS PERSONA ------------------------------------------ 

CREATE OR ALTER PROCEDURE [dbo].[MOV_ObtenerDatosPersona]
@idCliente INT = NULL,
@CURPCliente VARCHAR(18) = NULL
AS
BEGIN
    DECLARE @path VARCHAR(250)
	DECLARE @IdPersona INT

	IF (@idCliente IS NOT NULL)
		BEGIN
			--Establece el id de la persona tomando como referencia el cliente
			IF EXISTS (SELECT ISNULL(CI.id_persona,0) FROM CLIE_Individual AS CI WHERE CI.id_cliente = @idCliente)
				SET @idPersona = (SELECT ISNULL(CI.id_persona,0) FROM CLIE_Individual AS CI WHERE CI.id_cliente = @idCliente)
				ELSE
				SET @IdPersona = 0
		END
	ELSE
		BEGIN
			SET @IdPersona = (
					SELECT TOP 1 CI.id_persona FROM CONT_IdentificacionOficial AS CI
					WHERE CI.tipo_identificacion = 'CURP' AND CI.id_numero = @CURPCliente
			)

			SET @idCliente = (
				SELECT TOP 1 CI.id_cliente FROM CLIE_Individual AS CI WHERE CI.id_persona = @IdPersona
			)
	END

		SELECT * FROM dbo.MOV_ObtenerDatosPersonales(@idPersona)
		SELECT * FROM dbo.MOV_ObtenerDatosIdentificacion(@idPersona)
		SELECT * FROM dbo.MOV_ObtenerDatosIFE(@idPersona)
		SELECT * FROM dbo.MOV_ObtenerDirecciones(@idPersona)
		SELECT * FROM dbo.MOV_ObtenerTelefonos(@idPersona)
		SELECT * FROM dbo.MOV_ObtenerAval(@idCliente)
		SELECT * FROM dbo.MOV_ObtenerCiclo(@idPersona)
		SELECT * FROM dbo.MOV_ObtenerDatosSocioeconomicos(@idCliente)
END
GO

--#endregion ---------------------------------------- FIN PROCEDURE OBTENER DATOS PERSONA ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE CREATE PERSON --------------------------------------------

CREATE OR ALTER PROCEDURE MOV_AdministrarInformacionPersona
	@DATOSDireccion UDT_CONT_DireccionContacto READONLY,
    @DATOSPersona UDT_CONT_Persona READONLY, 
    @DATOSIdentificacion UDT_CONT_Identificaciones READONLY, 
    @DATOSCurp UDT_CONT_CURP readonly, 
    @DATOSIfe UDT_CONT_IFE readonly, 
    @DATOSTelefono UDT_CONT_Telefonos READONLY, 
    @etiqueta_opcion VARCHAR(50),
    @id_session INT
AS
BEGIN
	DECLARE @TABLAMensajes TABLE
	(
		Resultado VARCHAR(MAX),
		Tipo VARCHAR(20),
		Mensaje VARCHAR(MAX),
		id INT	  			
	);
	DECLARE @IDPersona INT = 0;
	DECLARE @IDNumeroIFE VARCHAR(30) = 0;--, @IDDireccionIFE INT = 0, @IDDireccionRFC INT = 0;
	DECLARE @IDDireccionDomicilio INT = 0, @IDDireccionIFE INT = 0, @IDDireccionRFC INT = 0;
	DECLARE @IDIdentificacionIFE INT = 0, @IDIdentificacionRFC INT = 0, @IDIdentificacionCURP INT = 0;
	DECLARE @IDCurp INT = 0, @IDIfe INT = 0, @IDTelefono INT = 0, @COUNT_IFE INT = 0, @COUNT_RFC INT = 0, @COUNT_CURP INT = 0
	BEGIN TRY
		BEGIN TRAN AdministrarPersona
		IF(@etiqueta_opcion = 'INSERTAR_PERSONA')
		BEGIN
			--SELECT * FROM CONT_Direcciones
			--DIRECCION DOMICILIO
			INSERT INTO CONT_Direcciones(
			direccion, colonia, codigo_postal, localidad, estado, municipio, pais, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, casa_situacion, tiempo_habitado_inicio, tiempo_habitado_final, correo_electronico, hipotecada, numero_interior, numero_exterior, referencia, num_interior, num_exterior, vialidad,domicilio_actual)
			SELECT TOP 1 
			DIRECCION.direccion, 
			DIRECCION.id_asentamiento, 
			ISNULL(CATA_Asentamiento.codigo_postal, ''), 
			DIRECCION.id_localidad, 
			DIRECCION.id_estado, 
			DIRECCION.id_municipio, 
			DIRECCION.id_pais, 
			0, 
			@id_session, 
			GETDATE(), 
			'ACTIVO',
			@id_session, 
			GETDATE(), 
			DIRECCION.casa_situacion, 
			DIRECCION.tiempo_habitado_inicio, 
			DIRECCION.tiempo_habitado_final, 
			DIRECCION.correo_electronico, 
			0, 
			DIRECCION.numero_interior, 
			DIRECCION.numero_exterior, 
			DIRECCION.referencia, 
			DIRECCION.num_interior, 
			DIRECCION.num_exterior, 
			DIRECCION.id_vialidad,
			DIRECCION.domicilio_actual
			FROM @DATOSDireccion DIRECCION
			LEFT JOIN CATA_Asentamiento ON CATA_asentamiento.id = DIRECCION.id_asentamiento
			WHERE LTRIM(RTRIM(DIRECCION.tipo)) = 'DOMICILIO'
			SELECT @IDDireccionDomicilio = SCOPE_IDENTITY()
			--DIRECCION IFE
			INSERT INTO CONT_Direcciones(
			direccion, colonia, codigo_postal, localidad, estado, municipio, pais, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, casa_situacion, tiempo_habitado_inicio, tiempo_habitado_final, correo_electronico, hipotecada, numero_interior, numero_exterior, referencia, num_interior, num_exterior, vialidad)
			SELECT TOP 1 
			DIRECCION.direccion, 
			DIRECCION.id_asentamiento, 
			ISNULL(CATA_Asentamiento.codigo_postal, ''), 
			DIRECCION.id_localidad, 
			DIRECCION.id_estado, 
			DIRECCION.id_municipio, 
			DIRECCION.id_pais, 
			0, 
			@id_session, 
			GETDATE(), 
			'ACTIVO',
			@id_session, 
			GETDATE(), 
			DIRECCION.casa_situacion, 
			DIRECCION.tiempo_habitado_inicio, 
			DIRECCION.tiempo_habitado_final, 
			DIRECCION.correo_electronico, 
			0, 
			DIRECCION.numero_interior, 
			DIRECCION.numero_exterior, 
			DIRECCION.referencia, 
			DIRECCION.num_interior, 
			DIRECCION.num_exterior, 
			DIRECCION.id_vialidad
			FROM @DATOSDireccion DIRECCION
			LEFT JOIN CATA_Asentamiento ON CATA_asentamiento.id = DIRECCION.id_asentamiento
			WHERE LTRIM(RTRIM(DIRECCION.tipo)) = 'IFE'
			SELECT @IDDireccionIFE = SCOPE_IDENTITY()
			--DIRECCION RFC
			INSERT INTO CONT_Direcciones(
			direccion, colonia, codigo_postal, localidad, estado, municipio, pais, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, casa_situacion, tiempo_habitado_inicio, tiempo_habitado_final, correo_electronico, hipotecada, numero_interior, numero_exterior, referencia, num_interior, num_exterior, vialidad)
			SELECT TOP 1 
			DIRECCION.direccion, 
			DIRECCION.id_asentamiento, 
			ISNULL(CATA_Asentamiento.codigo_postal, ''), 
			DIRECCION.id_localidad, 
			DIRECCION.id_estado, 
			DIRECCION.id_municipio, 
			DIRECCION.id_pais, 
			0, 
			@id_session, 
			GETDATE(), 
			'ACTIVO',
			@id_session, 
			GETDATE(), 
			DIRECCION.casa_situacion, 
			DIRECCION.tiempo_habitado_inicio, 
			DIRECCION.tiempo_habitado_final, 
			DIRECCION.correo_electronico, 
			0, 
			DIRECCION.numero_interior, 
			DIRECCION.numero_exterior, 
			DIRECCION.referencia, 
			DIRECCION.num_interior, 
			DIRECCION.num_exterior, 
			DIRECCION.id_vialidad
			FROM @DATOSDireccion DIRECCION
			LEFT JOIN CATA_Asentamiento ON CATA_asentamiento.id = DIRECCION.id_asentamiento
			WHERE LTRIM(RTRIM(DIRECCION.tipo)) = 'RFC'
			SELECT @IDDireccionRFC = SCOPE_IDENTITY()
			IF(@IDDireccionDomicilio > 0)
			BEGIN
				--INSERTAR PERSONA
				INSERT INTO CONT_Personas (
				nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_sexo, curp, id_escolaridad, id_estado_civil, id_direccion, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, entidad_nacimiento, regimen, id_conyuge, rfc, id_oficina, generado, datos_diferentes_curp, id_entidad_nacimiento, id_nacionalidad, es_pep, es_persona_prohibida)
				SELECT TOP 1
				nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_sexo, '', id_escolaridad, id_estado_civil, @IDDireccionDomicilio, @id_session, GETDATE(), 'ACTIVO', @id_session, GETDATE(), entidad_nacimiento, regimen, 0, '', id_oficina, 0, datos_personales_diferentes_curp, id_entidad_nacimiento, id_nacionalidad, es_pep, es_persona_prohibida
				FROM @DATOSPersona
				SELECT @IDPersona = SCOPE_IDENTITY()
				IF(@IDPersona > 0)
				BEGIN
					INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
					VALUES('OK','INFO','Persona Registrada Correctamente.', @IDPersona);
					IF(@IDDireccionIFE > 0)
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('OK','INFO','Direccion IFE Registrada Correctamente.', @IDDireccionIFE);
						--IDENTIFICACION IFE
						SELECT @COUNT_IFE =  COUNT(*) FROM CONT_IdentificacionOficial
						INNER JOIN @DATOSIdentificacion IFE ON IFE.tipo_identificacion = 'IFE'
							AND LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) = 'IFE'
							AND LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) = LTRIM(RTRIM(IFE.id_numero))
						
						INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, predeterminado, creado_por, 
						fecha_registro, estatus_registro, modificado_por, fecha_revision, id_direccion)
						SELECT TOP 1 @IDPersona, tipo_identificacion, id_numero, 0, @id_session, GETDATE(), 'ACTIVO', @id_session,
						 GETDATE(), @IDDireccionIFE
						FROM @DATOSIdentificacion WHERE tipo_identificacion = 'IFE'
						SELECT @IDIdentificacionIFE = SCOPE_IDENTITY()
						IF(@IDIdentificacionIFE > 0)
						BEGIN
							SELECT @IDNumeroIFE = id_numero FROM CONT_IdentificacionOficial WHERE id = @IDIdentificacionIFE
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO','Identificacion INE Registrada Correctamente.', @IDDireccionIFE);
							
							INSERT INTO CONT_IFE (id_identificacion_oficial, numero_emision, numero_vertical_ocr)
							SELECT @IDNumeroIFE, numero_emision, numero_vertical_ocr FROM @DATOSIfe
							SELECT @IDIfe = SCOPE_IDENTITY()
							IF(@IDIfe <= 0 OR @IDIfe IS NULL)
							BEGIN
								INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
								VALUES('ALERT','ALERT','Clave INE no se registr�', 0);
							END
							ELSE
							BEGIN
								INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
								VALUES('OK','INFO','Clave INE Registrada Correctamente.', @IDDireccionIFE);
							END
						END
					END
					ELSE
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('ALERT','ALERT','La Direccion INE No se Registr�.', 0);
					END
					IF(@IDDireccionRFC > 0)
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('OK','INFO','Direccion RFC Registrada Correctamente.', @IDDireccionRFC);
						--IDENTIFICACION RFC
						SELECT @COUNT_RFC =  COUNT(*) FROM CONT_IdentificacionOficial
						INNER JOIN @DATOSIdentificacion IFE ON IFE.tipo_identificacion = 'RFC'
							AND LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) = 'RFC'
							AND LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) = LTRIM(RTRIM(IFE.id_numero))
							
						INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, predeterminado, creado_por, 
						fecha_registro, estatus_registro, modificado_por, fecha_revision, id_direccion)
						SELECT TOP 1 @IDPersona, tipo_identificacion, id_numero, 0, @id_session, GETDATE(), 'ACTIVO', @id_session, 
						GETDATE(), @IDDireccionRFC
						FROM @DATOSIdentificacion WHERE tipo_identificacion = 'RFC'
						SELECT @IDIdentificacionRFC = SCOPE_IDENTITY()
						IF(@IDIdentificacionRFC > 0)
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO','Clave RFC Registrada Correctamente.', @IDIdentificacionRFC);
						END
						ELSE
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('ALERT','ALERT','Clave RFC no se registr�', 0);
						END
					ENd
					ELSE
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('ALERT','ALERT','La Direccion RFC No se Registr�.', 0);
					END
					
					--IDENTIFICACION CURP
					SELECT @COUNT_IFE =  COUNT(*) FROM CONT_IdentificacionOficial
					INNER JOIN @DATOSIdentificacion IFE ON IFE.tipo_identificacion = 'CURP'
						AND LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) = 'CURP'
						AND LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) = LTRIM(RTRIM(IFE.id_numero))
					INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, predeterminado, creado_por,
					 fecha_registro, estatus_registro, modificado_por, fecha_revision, id_direccion)
					SELECT TOP 1 @IDPersona, tipo_identificacion, id_numero, 0, @id_session, GETDATE(), 'ACTIVO', @id_session,
					 GETDATE(), 0
					FROM @DATOSIdentificacion WHERE tipo_identificacion = 'CURP'			
					SELECT @IDIdentificacionCURP = SCOPE_IDENTITY()
					IF(@IDIdentificacionCURP > 0)
					BEGIN 
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('OK','INFO','Identificacion CURP Registrada Correctamente.', @IDIdentificacionCURP);
							
						--SELECT id_identificacion_oficial, archivo, xml_datos_oficiales, guardado, tipo FROM CONT_CURP
						INSERT INTO CONT_CURP (id_identificacion_oficial, archivo, xml_datos_oficiales, guardado, tipo, fecha_creacion) 
						SELECT @IDIdentificacionCURP, path_archivo, xml_datos, archivo_guardado, tipo_archivo, GETDATE() 
						FROM @DATOSCurp
						SELECT @IDCurp = SCOPE_IDENTITY()
						IF(@IDCurp > 0)
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO','Clave CURP Registrada Correctamente.', @IDIdentificacionCURP);
						END
						ELSE
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('ALERT','ALERT','Clave CURP No se Registr�.', 0);
						END
					END
					
					--TELEFONO PERSONAL
					INSERT INTO CONT_Telefonos 
					(idcel_telefono, extension, tipo_telefono, compania, sms, mms, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision)
					SELECT TOP 1 
					idcel_telefono, extension, tipo_telefono, compania, sms, 0, 0, @id_session, GETDATE(), 'ACTIVO', @id_session, GETDATE()
					FROM @DATOSTelefono
					SELECT @IDTelefono = SCOPE_IDENTITY()
					IF(@IDTelefono > 0)
					BEGIN
						INSERT INTO CONT_TelefonosPersona (id_persona,id_telefono) VALUES (@IDPersona, @IDTelefono)
						IF(SCOPE_IDENTITY() > 0)
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO','Tel�fono asignado Correctamente.', 0);
						END
						ELSE
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('ALERT','ALERT','Tel�fono No se Registr�.', 0);
						END
					END
					ELSE
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('ALERT','ALERT','Tel�fono No se Registr�.', 0);
					END
				END
			END
		END
		IF(@etiqueta_opcion = 'ACTUALIZAR_PERSONA')
		BEGIN
			SELECT TOP 1 @IDPersona = id FROM @DATOSPersona
			SELECT TOP 1 @IDDireccionIFE = id FROM @DATOSDireccion WHERE LTRIM(RTRIM(tipo)) = 'IFE'
			SELECT TOP 1 @IDDireccionRFC = id FROM @DATOSDireccion WHERE LTRIM(RTRIM(tipo)) = 'RFC'
			SELECT TOP 1 @IDDireccionDomicilio = id FROM @DATOSDireccion WHERE LTRIM(RTRIM(tipo)) = 'DOMICILIO'
			SELECT TOP 1 @IDIdentificacionIFE = id FROM @DATOSIdentificacion WHERE LTRIM(RTRIM(tipo_identificacion)) = 'IFE'
			SELECT TOP 1 @IDIdentificacionRFC = id FROM @DATOSIdentificacion WHERE LTRIM(RTRIM(tipo_identificacion)) = 'RFC'
			SELECT TOP 1 @IDIdentificacionCURP = id FROM @DATOSIdentificacion WHERE LTRIM(RTRIM(tipo_identificacion)) = 'CURP'
			SELECT TOP 1 @IDIfe = id FROM @DATOSIfe
			SELECT TOP 1 @IDTelefono = TEL.id FROM 
			@DATOSTelefono TEL
			INNER JOIN CONT_Telefonos ON CONT_Telefonos.id = TEL.id
			ORDER BY CONT_Telefonos.fecha_registro ASC
			
			IF(@IDPersona > 0)
			BEGIN
				--INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
				--select tipo,'INFO', tipo + ' - '  + CAST(id AS VARCHAR(20)) + ' - '  + CAST(id_asentamiento AS VARCHAR(20)), id from @DATOSDireccion				
				UPDATE CONT_Direcciones 
				SET 
				CONT_Direcciones.pais = DIRECCION.id_pais,
				CONT_Direcciones.estado = DIRECCION.id_estado,
				CONT_Direcciones.municipio = DIRECCION.id_municipio,
				CONT_Direcciones.localidad = DIRECCION.id_localidad,
				CONT_Direcciones.colonia = DIRECCION.id_asentamiento,
				CONT_Direcciones.direccion = DIRECCION.direccion,
				CONT_Direcciones.numero_exterior = DIRECCION.numero_exterior,
				CONT_Direcciones.numero_interior = DIRECCION.numero_interior,
				CONT_Direcciones.referencia = DIRECCION.referencia,
				CONT_Direcciones.casa_situacion = DIRECCION.casa_situacion,
				CONT_Direcciones.tiempo_habitado_inicio = DIRECCION.tiempo_habitado_inicio,
				CONT_Direcciones.tiempo_habitado_final = DIRECCION.tiempo_habitado_final,
				CONT_Direcciones.correo_electronico = DIRECCION.correo_electronico,
				CONT_Direcciones.num_exterior = DIRECCION.num_exterior,
				CONT_Direcciones.num_interior = DIRECCION.num_interior,
				CONT_Direcciones.vialidad = DIRECCION.id_vialidad,
				CONT_Direcciones.domicilio_actual = DIRECCION.domicilio_actual,
				CONT_Direcciones.fecha_revision = GETDATE(),
				CONT_Direcciones.modificado_por = @id_session
				FROM 
				(
					SELECT 
					[id] AS id_direccion,
					LTRIM(RTRIM([tipo])) AS tipo,
					[id_pais],
					[id_estado],
					[id_municipio],
					[id_localidad],
					[id_asentamiento],
					LTRIM(RTRIM([direccion])) AS direccion,
					[numero_exterior],
					[numero_interior],
					LTRIM(RTRIM([referencia])) AS referencia,
					[casa_situacion],
					[tiempo_habitado_inicio],
					[tiempo_habitado_final],
					[correo_electronico],
					[num_interior],
					[num_exterior],
					[id_vialidad],
					[domicilio_actual]
					FROM @DATOSDireccion
				)
				AS DIRECCION
				WHERE DIRECCION.id_direccion = CONT_Direcciones.id
				AND DIRECCION.id_direccion <> 0
				AND LTRIM(RTRIM(DIRECCION.tipo)) IN ('IFE', 'RFC', 'DOMICILIO')
				
				IF(@IDDireccionDomicilio = 0)
				BEGIN
					--DIRECCION DOMICILIO
					INSERT INTO CONT_Direcciones(
					direccion, colonia, codigo_postal, localidad, estado, municipio, pais, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, casa_situacion, tiempo_habitado_inicio, tiempo_habitado_final, correo_electronico, hipotecada, numero_interior, numero_exterior, referencia, num_interior, num_exterior, vialidad, domicilio_actual)
					SELECT TOP 1 
					DIRECCION.direccion, 
					DIRECCION.id_asentamiento, 
					ISNULL(CATA_Asentamiento.codigo_postal, ''), 
					DIRECCION.id_localidad, 
					DIRECCION.id_estado, 
					DIRECCION.id_municipio, 
					DIRECCION.id_pais, 
					0, 
					@id_session, 
					GETDATE(), 
					'ACTIVO',
					@id_session, 
					GETDATE(), 
					DIRECCION.casa_situacion, 
					DIRECCION.tiempo_habitado_inicio, 
					DIRECCION.tiempo_habitado_final, 
					DIRECCION.correo_electronico, 
					0, 
					DIRECCION.numero_interior, 
					DIRECCION.numero_exterior, 
					DIRECCION.referencia, 
					DIRECCION.num_interior, 
					DIRECCION.num_exterior, 
					DIRECCION.id_vialidad,
					DIRECCION.domicilio_actual
					FROM @DATOSDireccion DIRECCION
					LEFT JOIN CATA_Asentamiento ON CATA_asentamiento.id = DIRECCION.id_asentamiento
					WHERE LTRIM(RTRIM(DIRECCION.tipo)) = 'DOMICILIO'
					
					SELECT @IDDireccionDomicilio = SCOPE_IDENTITY()
					IF(@IDDireccionDomicilio > 0)
					BEGIN
						
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('OK','INFO', 'Direccion DOMICILIO Insertado correctamente', @IDPersona);
					END
				END
				IF(@IDDireccionIFE = 0)
				BEGIN
					--DIRECCION IFE
					INSERT INTO CONT_Direcciones(
					direccion, colonia, codigo_postal, localidad, estado, municipio, pais, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, casa_situacion, tiempo_habitado_inicio, tiempo_habitado_final, correo_electronico, hipotecada, numero_interior, numero_exterior, referencia, num_interior, num_exterior, vialidad)
					SELECT TOP 1 
					DIRECCION.direccion, 
					DIRECCION.id_asentamiento, 
					ISNULL(CATA_Asentamiento.codigo_postal, ''), 
					DIRECCION.id_localidad, 
					DIRECCION.id_estado, 
					DIRECCION.id_municipio, 
					DIRECCION.id_pais, 
					0, 
					@id_session, 
					GETDATE(), 
					'ACTIVO',
					@id_session, 
					GETDATE(), 
					DIRECCION.casa_situacion, 
					DIRECCION.tiempo_habitado_inicio, 
					DIRECCION.tiempo_habitado_final, 
					DIRECCION.correo_electronico, 
					0, 
					DIRECCION.numero_interior, 
					DIRECCION.numero_exterior, 
					DIRECCION.referencia, 
					DIRECCION.num_interior, 
					DIRECCION.num_exterior, 
					DIRECCION.id_vialidad
					FROM @DATOSDireccion DIRECCION
					LEFT JOIN CATA_Asentamiento ON CATA_asentamiento.id = DIRECCION.id_asentamiento
					WHERE LTRIM(RTRIM(DIRECCION.tipo)) = 'IFE'
					SELECT @IDDireccionIFE = SCOPE_IDENTITY()
					IF(@IDDireccionIFE > 0)
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('OK','INFO', 'Direccion INE Insertado correctamente', @IDPersona);
					END
				END
				IF(@IDDireccionRFC = 0)
				BEGIN
					--DIRECCION RFC
					INSERT INTO CONT_Direcciones(
					direccion, colonia, codigo_postal, localidad, estado, municipio, pais, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision, casa_situacion, tiempo_habitado_inicio, tiempo_habitado_final, correo_electronico, hipotecada, numero_interior, numero_exterior, referencia, num_interior, num_exterior, vialidad)
					SELECT TOP 1 
					DIRECCION.direccion, 
					DIRECCION.id_asentamiento, 
					ISNULL(CATA_Asentamiento.codigo_postal, ''), 
					DIRECCION.id_localidad, 
					DIRECCION.id_estado, 
					DIRECCION.id_municipio, 
					DIRECCION.id_pais, 
					0, 
					@id_session, 
					GETDATE(), 
					'ACTIVO',
					@id_session, 
					GETDATE(), 
					DIRECCION.casa_situacion, 
					DIRECCION.tiempo_habitado_inicio, 
					DIRECCION.tiempo_habitado_final, 
					DIRECCION.correo_electronico, 
					0, 
					DIRECCION.numero_interior, 
					DIRECCION.numero_exterior, 
					DIRECCION.referencia, 
					DIRECCION.num_interior, 
					DIRECCION.num_exterior, 
					DIRECCION.id_vialidad
					FROM @DATOSDireccion DIRECCION
					LEFT JOIN CATA_Asentamiento ON CATA_asentamiento.id = DIRECCION.id_asentamiento
					WHERE LTRIM(RTRIM(DIRECCION.tipo)) = 'RFC'
					SELECT @IDDireccionRFC = SCOPE_IDENTITY()
					IF(@IDDireccionRFC > 0)
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
						VALUES('OK','INFO', 'Direccion RFC Insertado correctamente', @IDPersona);
					END
				END
				
				UPDATE CONT_Personas 
				SET nombre = PERSON.nombre,
				apellido_paterno = PERSON.apellido_paterno,
				apellido_materno = PERSON.apellido_materno,
				fecha_nacimiento = PERSON.fecha_nacimiento,
				id_sexo = PERSON.id_sexo
				,id_escolaridad = PERSON.id_escolaridad
				,id_direccion = @IDDireccionDomicilio
				,id_estado_civil = PERSON.id_estado_civil
				,entidad_nacimiento = PERSON.entidad_nacimiento
				,regimen = PERSON.regimen
				,id_oficina = PERSON.id_oficina
				--,curp = PERSON.curp_fisica
				,datos_diferentes_curp = PERSON.datos_personales_diferentes_curp
				,id_entidad_nacimiento = PERSON.id_entidad_nacimiento
				,id_nacionalidad = PERSON.id_nacionalidad
				,id_pais_nacimiento = PERSON.id_pais_nacimiento
				,es_pep = PERSON.es_pep
				,es_persona_prohibida = PERSON.es_persona_prohibida
				,fecha_revision = GETDATE()
				,modificado_por = @id_session
				FROM 
				(
					SELECT 
					[id],
					[nombre],
					[apellido_paterno],
					[apellido_materno],
					[fecha_nacimiento],
					[id_sexo],
					[id_escolaridad],
					[id_estado_civil],
					[entidad_nacimiento],
					[regimen],
					[id_oficina],
					[curp_fisica],
					[datos_personales_diferentes_curp],
					[id_entidad_nacimiento],
					[id_nacionalidad],
					[id_pais_nacimiento],
					[es_pep],
					[es_persona_prohibida]
					FROM @DATOSPersona
				)  AS PERSON
				WHERE PERSON.id = CONT_Personas.id
				
				
				IF(@IDDireccionIFE > 0)
				BEGIN
					--IDENTIFICACION IFE
					IF(@IDIdentificacionIFE = 0)
					BEGIN
						INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, predeterminado, creado_por, 
						fecha_registro, estatus_registro, modificado_por, fecha_revision, id_direccion)
						SELECT TOP 1 @IDPersona, tipo_identificacion, id_numero, 0, @id_session, GETDATE(), 'ACTIVO', @id_session,
						 GETDATE(), @IDDireccionIFE
						FROM @DATOSIdentificacion WHERE tipo_identificacion = 'IFE'
						SELECT @IDIdentificacionIFE = SCOPE_IDENTITY()
						IF(@IDIdentificacionIFE > 0)
						BEGIN
							INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO', 'Identificaci�n INE Actualizado correctamente', @IDPersona);
							SELECT @IDNumeroIFE = id_numero FROM CONT_IdentificacionOficial WHERE id = @IDIdentificacionIFE
							--select * from CONT_IFE
							INSERT INTO CONT_IFE (id_identificacion_oficial, numero_emision, numero_vertical_ocr)
							SELECT @IDNumeroIFE, numero_emision, numero_vertical_ocr FROM @DATOSIfe
							SELECT @IDIfe = SCOPE_IDENTITY()
						END
					END
					ELSE
					BEGIN
						UPDATE CONT_IdentificacionOficial SET id_direccion = @IDDireccionIFE
						WHERE LTRIM(RTRIM(tipo_identificacion)) = 'IFE'
						AND id = @IDIdentificacionIFE
						AND id_direccion = 0
					END
				END
				IF(@IDDireccionRFC > 0)
				BEGIN
					--IDENTIFICACION RFC
					IF(@IDIdentificacionRFC = 0)
					BEGIN
						INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO', 'Identificaci�n RFC Actualizado correctamente', @IDPersona);
						INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, predeterminado, creado_por, 
						fecha_registro, estatus_registro, modificado_por, fecha_revision, id_direccion)
						SELECT TOP 1 @IDPersona, tipo_identificacion, id_numero, 0, @id_session, GETDATE(), 'ACTIVO', @id_session, 
						GETDATE(), @IDDireccionRFC
						FROM @DATOSIdentificacion WHERE tipo_identificacion = 'RFC'
						SELECT @IDIdentificacionRFC = SCOPE_IDENTITY()
					END
					ELSE
					BEGIN
						UPDATE CONT_IdentificacionOficial SET id_direccion = @IDDireccionRFC
						WHERE LTRIM(RTRIM(tipo_identificacion)) = 'RFC'
						AND id = @IDIdentificacionRFC
						AND id_direccion = 0
					END
				END
				IF(@IDIdentificacionCURP = 0)
				BEGIN
					--IDENTIFICACION CURP
					INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
							VALUES('OK','INFO', 'Identificaci�n CURP Actualizado correctamente', @IDPersona);
					INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, predeterminado, creado_por,
					 fecha_registro, estatus_registro, modificado_por, fecha_revision, id_direccion)
					SELECT TOP 1 @IDPersona, tipo_identificacion, id_numero, 0, @id_session, GETDATE(), 'ACTIVO', @id_session,
					 GETDATE(), 0
					FROM @DATOSIdentificacion WHERE tipo_identificacion = 'CURP'			
					SELECT @IDIdentificacionCURP = SCOPE_IDENTITY()
					IF(@IDIdentificacionCURP > 0)
					BEGIN
						--SELECT id_identificacion_oficial, archivo, xml_datos_oficiales, guardado, tipo FROM CONT_CURP
						INSERT INTO CONT_CURP (id_identificacion_oficial, archivo, xml_datos_oficiales, guardado, tipo, fecha_creacion) 
						SELECT @IDIdentificacionCURP, path_archivo, xml_datos, archivo_guardado, tipo_archivo, GETDATE() 
						FROM @DATOSCurp
						SELECT @IDCurp = SCOPE_IDENTITY()
					END
				END
				
				
				--INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
				--select tipo_identificacion,'INFO', id_numero + ' - '  + CAST(id AS VARCHAR(20)) + ' - '  + CAST(id AS VARCHAR(20)), id from @DATOSIdentificacion
				
				UPDATE CONT_IdentificacionOficial --WITH (ROWLOCK)
				SET id_numero = IDENTIFICACION.id_numero,
				--id_direccion = IDENTIFICACION.id_direccion,
				modificado_por = @id_session,
				fecha_revision = GETDATE()
				FROM (
					SELECT 
						id,
						id_entidad,
						tipo_identificacion,
						id_numero,
						tipo_entidad,
						id_direccion
					FROM @DATOSIdentificacion
				) AS IDENTIFICACION
				WHERE IDENTIFICACION.id = CONT_IdentificacionOficial.id
				
				SELECT @IDNumeroIFE = id_numero FROM CONT_IdentificacionOficial WHERE id = @IDIdentificacionIFE
				
				IF(@IDIfe = 0)
				BEGIN
					INSERT INTO CONT_IFE(id_identificacion_oficial, numero_emision, numero_vertical_ocr)
					SELECT TOP 1 @IDNumeroIFE, numero_emision, numero_vertical_ocr FROM @DATOSIfe
					SELECT @IDIfe = SCOPE_IDENTITY()
				END
				ELSE
				BEGIN
					UPDATE CONT_IFE 
					SET id_identificacion_oficial = LTRIM(RTRIM(IFE.id_identificacion_oficial))
					,numero_emision = LTRIM(RTRIM(IFE.numero_emision))
					,numero_vertical_ocr = LTRIM(RTRIM(IFE.numero_vertical_ocr))
					FROM @DATOSIfe IFE WHERE CONT_IFE.id = IFE.id
				END
				
				SELECT @COUNT_CURP =  COUNT(*) FROM CONT_IdentificacionOficial
				INNER JOIN @DATOSIdentificacion IFE ON IFE.tipo_identificacion = 'CURP'
				AND LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) = 'CURP'
				AND LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) = LTRIM(RTRIM(IFE.id_numero))
				AND CONT_IdentificacionOficial.id_persona <> @IDPersona
				
				SELECT @COUNT_RFC =  COUNT(*) FROM CONT_IdentificacionOficial
				INNER JOIN @DATOSIdentificacion IFE ON IFE.tipo_identificacion = 'RFC'
				AND LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) = 'RFC'
				AND LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) = LTRIM(RTRIM(IFE.id_numero))
				AND CONT_IdentificacionOficial.id_persona <> @IDPersona
				
				SELECT @COUNT_RFC =  COUNT(*) FROM CONT_IdentificacionOficial
				INNER JOIN @DATOSIdentificacion IFE ON IFE.tipo_identificacion = 'IFE'
				AND LTRIM(RTRIM(CONT_IdentificacionOficial.tipo_identificacion)) = 'IFE'
				AND LTRIM(RTRIM(CONT_IdentificacionOficial.id_numero)) = LTRIM(RTRIM(IFE.id_numero))
				AND CONT_IdentificacionOficial.id_persona <> @IDPersona
				
				IF(@IDTelefono = 0)
				BEGIN
					INSERT INTO CONT_Telefonos 
					(idcel_telefono, extension, tipo_telefono, compania, sms, mms, predeterminado, creado_por, fecha_registro, estatus_registro, modificado_por, fecha_revision)
					SELECT TOP 1 
					idcel_telefono, extension, tipo_telefono, compania, sms, 0, 0, @id_session, GETDATE(), 'ACTIVO', @id_session, GETDATE()
					FROM @DATOSTelefono
					SELECT @IDTelefono = SCOPE_IDENTITY()
					IF(@IDTelefono > 0)
					BEGIN
						INSERT INTO CONT_TelefonosPersona (id_persona,id_telefono) VALUES (@IDPersona, @IDTelefono)
					END
				END
				ELSE
				BEGIN
					UPDATE CONT_Telefonos SET
					idcel_telefono = TEL.idcel_telefono,
					tipo_telefono = TEL.tipo_telefono,
					compania = TEL.compania,
					sms = TEL.sms,
					modificado_por = @id_session,
					fecha_revision = GETDATE()
					FROM 
					(
						SELECT
						id, idcel_telefono, extension, tipo_telefono, compania, sms
						FROM @DATOSTelefono
					) AS TEL WHERE TEL.id = CONT_Telefonos.id
					--SELECT * FROM CONT_Telefonos
				END
				
			END
			ELSE
			BEGIN
				INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
				VALUES('ERROR','ERROR', 'Los datos no se estan enviando correctamente. Intente nuevamente. Si el problema persiste contacte con Soporte T�cnico', @IDPersona);
			END
			INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
			VALUES('OK','INFO', 'Datos Acualizados correctamente', @IDPersona);
		END
	    COMMIT TRAN AdministrarPersona
		SELECT * FROM @TABLAMensajes
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN AdministrarPersona
		INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
		SELECT
		ERROR_NUMBER() AS Numero_de_Error,
		ERROR_SEVERITY() AS Gravedad_del_Error,
		ERROR_STATE() AS Estado_del_Error,
		ERROR_PROCEDURE() AS Procedimiento_del_Error,
		ERROR_LINE() AS Linea_de_Error,
		ERROR_MESSAGE() AS Mensaje_de_Error,
		'CONT_AdministrarInformacionPersona';
		
    	INSERT INTO @TABLAMensajes(Resultado,Tipo,Mensaje,id)
		VALUES('ERROR','ERROR',ERROR_MESSAGE(), 0);
		SELECT * FROM @TABLAMensajes
	END CATCH
END
GO
--#endregion ------------------------------------- FIN PROCEDURE CREATE PERSON ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE CREATE NEGOCIO(EMPRESA) ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_AdministrarEmpresa
	 @tablaEmpresa UDT_CONT_Empresa READONLY,
	 @tablaDirecciones UDT_CONT_Direcciones READONLY,
	 @tablaOficinas  UDT_CONT_Oficinas READONLY,
	 @tablaTelefonos UDT_CONT_Telefonos READONLY,
	 @id_opcion INT,
	 @id_sesion INT
AS
BEGIN
DECLARE @id_empresa INT
DECLARE @id_direccion INT
DECLARE @id_oficina INT
DECLARE @id_telefono INT
DECLARE @contador INT

DECLARE @tablaResultados AS TABLE
(
	id_resultado INT,
	accion VARCHAR(200),
	resultado VARCHAR(200)	
)
	
	BEGIN TRY
		BEGIN TRANSACTION insert_update_empresa_relaciones
			IF(@id_opcion=1)
			BEGIN
				
				DECLARE @tablaDireccionesTemp AS TABLE
				(
					cont_direccion INT IDENTITY,
					[id_direccion] INT ,
					[tipo] CHAR(12) ,
					[id_pais] INT ,
					[id_estado] INT ,
					[id_municipio] INT ,
					[id_localidad] INT ,
					[id_asentamiento] INT ,
					[direccion] VARCHAR(150) ,
					[numero_exterior] VARCHAR(15) ,
					[numero_interior] VARCHAR(15) ,
					[referencia] VARCHAR(150) ,
					[casa_situacion] INT ,
					[tiempo_habitado_inicio] DATETIME ,
					[tiempo_habitado_final] DATETIME ,
					[correo_electronico] VARCHAR(150) ,
					[num_interior] INT ,
					[num_exterior]INT,
					[id_vialidad] INT
				)
				DECLARE @tablaOficinasTemp AS TABLE
				(
					cont_oficina INT IDENTITY,
					id_oficina INT ,
					id_empresa INT ,
					id_direccion INT ,
					matriz BIT ,
					nombre_oficina CHAR(150) ,
					funcion_oficina CHAR(50) ,
					email_sucursal VARCHAR(100),--Nuevo campo para UDT en la tabla CONT_Oficinas ya existe
					horario VARCHAR(100) ,
					tipo_local VARCHAR(80) ,
					dias_laborales VARCHAR(100) ,
					descripcion VARCHAR(300) 
				)
				DECLARE @tablaTelefonosTemp AS TABLE
				(
					cont_telefono INT IDENTITY,
					id INT ,
					idcel_telefono CHAR(20) ,
					extension CHAR(10),
					tipo_telefono CHAR(12) ,
					compania VARCHAR(20),--Nuevo campo para UDT en la tabla CONT_Telefonos ya existe
					sms BIT 
				)
				
				IF((SELECT	COUNT(*) FROM @tablaEmpresa)>0)
				BEGIN
					INSERT INTO
					CONT_Empresas
					(NOMBRE_COMERCIAL,RAZON_SOCIAL,RFC,FIGURA_JURIDICA,ID_ACTIVIDAD_ECONOMICA,PAGINA_WEB,ECON_VENTAS_TOTALES_CANTIDAD,ECON_VENTAS_TOTALES_UNIDAD,
						ECON_REVOLVENCIA_NEGOCIO,ECON_NUMERO_EMPLEADOS,TIEMPO_ACTIVIDAD_INICIO,TIEMPO_ACTIVIDAD_FINAL,GIRO, ECON_REGISTRO_EGRESOS_INGRESOS,ACTA_CONSTITUTIVA,	creado_por,fecha_registro,modificado_por,fecha_revision,estatus_registro) 
					SELECT nombre_comercial,razon_social,rfc,figura_juridica,id_actividad_economica,pagina_web,
						econ_ventas_totales_cantidad, econ_ventas_totales_unidad,econ_revolvencia_negocio,econ_numero_empleados,
						tiempo_actividad_inicio,tiempo_actividad_final,giro,econ_registro_egresos_ingresos,acta_constitutiva,@id_sesion,GETDATE(),@id_sesion,GETDATE(),'ACTIVO'
					 FROM 		@tablaEmpresa
					SET @id_empresa=SCOPE_IDENTITY()
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(@id_empresa,0)>0
					THEN @id_empresa ELSE 0 END,  
					'EMPRESA',	
					CASE  WHEN ISNULL(@id_empresa,0)>0 THEN 'INSERCI�N CORRECTA' ELSE 'INSERCI�N ERR�NEA' END
								
				END
				ELSE
				BEGIN
					
					SELECT TOP(1) @id_empresa=ISNULL(id_empresa,0) FROM @tablaOficinas
				END
					
				INSERT INTO @tablaDireccionesTemp
				SELECT * FROM @tablaDirecciones
						
				INSERT INTO @tablaOficinasTemp
				SELECT * FROM @tablaOficinas
				
				INSERT INTO @tablaTelefonosTemp
				SELECT * FROM @tablaTelefonos
				
				SET @contador=1
			
				WHILE @contador<=(SELECT COUNT(*) FROM @tablaDireccionesTemp)
				BEGIN
					
					INSERT INTO CONT_Direcciones
					(
						direccion,colonia,codigo_postal,localidad,estado,municipio,pais,predeterminado,casa_situacion,tiempo_habitado_inicio,tiempo_habitado_final,correo_electronico,
						hipotecada,numero_interior,numero_exterior,referencia,num_interior,num_exterior,vialidad,creado_por,fecha_registro,modificado_por,fecha_revision,estatus_registro
					) 
					SELECT
					Direcciones.direccion,
					Direcciones.id_asentamiento,
					Asentamiento.codigo_postal,
					Direcciones.id_localidad,
					Direcciones.id_estado,
					Direcciones.id_municipio,
					Direcciones.id_pais,
					0,
					Direcciones.casa_situacion,
					Direcciones.tiempo_habitado_inicio,
					Direcciones.tiempo_habitado_final,
					CAST(Direcciones.correo_electronico AS VARCHAR(50)),
					0,
					Direcciones.numero_interior,
					Direcciones.numero_exterior,
					Direcciones.referencia,
					Direcciones.num_interior,
					Direcciones.num_exterior,
					Direcciones.id_vialidad,
					@id_sesion,
					GETDATE(),
					@id_sesion,
					GETDATE(),
					'ACTIVO'
					FROM @tablaDireccionesTemp Direcciones
					
					CROSS APPLY
					(
						SELECT CATA_asentamiento.etiqueta AS colonia,CATA_asentamiento.codigo_postal FROM CATA_asentamiento WHERE CATA_asentamiento.id=Direcciones.id_asentamiento
					) Asentamiento
					 WHERE cont_direccion=@contador
					SET @id_direccion=IDENT_CURRENT('CONT_Direcciones')
					--SET @id_direccion=SCOPE_IDENTITY()
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(@id_direccion,0)>0
					THEN @id_direccion ELSE 0 END,  
					'DIRECCION',	
					CASE  WHEN ISNULL(@id_direccion,0)>0 THEN 'INSERCI�N CORRECTA' ELSE 'INSERCI�N ERR�NEA' END
					
					
					
					INSERT INTO CONT_Oficinas(ID_EMPRESA,ID_DIRECCION,MATRIZ,NOMBRE_OFICINA,FUNCION_OFICINA,EMAIL_SUCURSAL ,HORARIO,TIPO_LOCAL,DIAS_LABORALES,DESCRIPCION) 	
					SELECT 
					@id_empresa,
					@id_direccion ,
					matriz,
					nombre_oficina,
					funcion_oficina,
					email_sucursal,
					horario,tipo_local,
					dias_laborales,
					CASE  WHEN descripcion IS NULL THEN '' ELSE descripcion END
					FROM @tablaOficinasTemp 
					WHERE cont_oficina=@contador
					SET @id_oficina=IDENT_CURRENT('CONT_Oficinas')
					--SET @id_oficina=SCOPE_IDENTITY()
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(@id_oficina,0)>0
					THEN @id_oficina ELSE 0 END,  
					'OFICINA',	
					CASE  WHEN ISNULL(@id_oficina,0)>0 THEN 'INSERCI�N CORRECTA' ELSE 'INSERCI�N ERR�NEA' END
					
					IF((SELECT	COUNT(*) FROM @tablaTelefonosTemp)>0)
					BEGIN
					
						INSERT INTO CONT_Telefonos (IDCEL_TELEFONO, EXTENSION,TIPO_TELEFONO,COMPANIA,SMS,MMS,PREDETERMINADO,CREADO_POR,FECHA_REGISTRO,MODIFICADO_POR,FECHA_REVISION,ESTATUS_REGISTRO) 
						SELECT 
						idcel_telefono,extension,tipo_telefono,CAST(compania AS CHAR(20)),sms,0,0,@id_sesion,GETDATE(),@id_sesion,GETDATE(),'ACTIVO'
						FROM @tablaTelefonosTemp WHERE cont_telefono=@contador
						SET @id_telefono=SCOPE_IDENTITY()
						
						INSERT INTO   @tablaResultados
						SELECT
						CASE  WHEN ISNULL(@id_telefono,0)>0
						THEN @id_telefono ELSE 0 END,  
						'TELEFONO',	
						CASE  WHEN ISNULL(@id_telefono,0)>0 THEN 'INSERCI�N CORRECTA' ELSE 'INSERCI�N ERR�NEA' END
						
							
						INSERT INTO CONT_TelefonosOficina (id_telefono,id_oficina)
						SELECT @id_oficina,@id_telefono
					END
					
					SET @contador=@contador+1
					
				END
				
				
			END
			ELSE IF(@id_opcion=2)
			BEGIN
			
				DECLARE @tablaEmpresaModificada TABLE
				(
					id_empresa INT,
					accion VARCHAR(20)
				)
				
				DECLARE @tablaDireccionModificada TABLE
				(
					id_direccion INT,
					accion VARCHAR(20)
				)
				
				DECLARE @tablaOficinaModificada TABLE
				(
					id_oficina INT,
					accion VARCHAR(20)
				)
				DECLARE @tablaTelefonoModificado TABLE
				(
					id_telefono INT,
					accion VARCHAR(20)
				)
				IF((SELECT COUNT(*) FROM @tablaEmpresa)>0)
				BEGIN
					MERGE CONT_Empresas AS Empresa
					USING 
					(
						SELECT
						tablaEmpresa.id AS id_empresa,
						tablaEmpresa.nombre_comercial,
						tablaEmpresa.razon_social,
						tablaEmpresa.rfc,
						tablaEmpresa.figura_juridica,
						tablaEmpresa.id_actividad_economica,
						tablaEmpresa.pagina_web,
						tablaEmpresa.econ_ventas_totales_cantidad, 
						tablaEmpresa.econ_ventas_totales_unidad,
						tablaEmpresa.econ_revolvencia_negocio,
						tablaEmpresa.econ_numero_empleados,
						tablaEmpresa.tiempo_actividad_inicio,
						tablaEmpresa.tiempo_actividad_final,
						tablaEmpresa.giro,
						tablaEmpresa.econ_registro_egresos_ingresos,
						tablaEmpresa.acta_constitutiva
						
						FROM @tablaEmpresa tablaEmpresa
						
					) AS EmpresaModificada 
					ON Empresa.id = EmpresaModificada.id_empresa AND Empresa.estatus_registro='ACTIVO'
					WHEN MATCHED THEN
					UPDATE  
						SET
						Empresa.nombre_comercial=EmpresaModificada.nombre_comercial,
						Empresa.razon_social=EmpresaModificada.razon_social,
						Empresa.rfc=EmpresaModificada.rfc,
						Empresa.figura_juridica=EmpresaModificada.figura_juridica,
						Empresa.id_actividad_economica=EmpresaModificada.id_actividad_economica,
						Empresa.pagina_web=EmpresaModificada.pagina_web,
						Empresa.econ_ventas_totales_cantidad= EmpresaModificada.econ_ventas_totales_cantidad,
						Empresa.econ_ventas_totales_unidad=EmpresaModificada.econ_ventas_totales_unidad,
						Empresa.econ_revolvencia_negocio=EmpresaModificada.econ_revolvencia_negocio,
						Empresa.econ_numero_empleados=EmpresaModificada.econ_numero_empleados,
						Empresa.tiempo_actividad_inicio=EmpresaModificada.tiempo_actividad_inicio,
						Empresa.tiempo_actividad_final=EmpresaModificada.tiempo_actividad_final,
						Empresa.giro=EmpresaModificada.giro,
						Empresa.econ_registro_egresos_ingresos=EmpresaModificada.econ_registro_egresos_ingresos,
						Empresa.acta_constitutiva=EmpresaModificada.acta_constitutiva,
						Empresa.creado_por= @id_sesion,
						Empresa.fecha_registro= GETDATE(),
						Empresa.modificado_por= @id_sesion,
						Empresa.fecha_revision= GETDATE()
						
						
					OUTPUT inserted.id, $action INTO @tablaEmpresaModificada;
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(id_empresa,0)>0
					THEN id_empresa ELSE 0 END,  
					'EMPRESA',	
					CASE  WHEN ISNULL(id_empresa,0)>0 THEN 'MODIFICACI�N CORRECTA' ELSE 'MODIFICACI�N ERR�NEA' END
					FROM @tablaEmpresaModificada
				
				END
				ELSE
				BEGIN
					INSERT INTO @tablaEmpresaModificada
					SELECT TOP(1) ISNULL(id_empresa,0),'' FROM @tablaOficinas
				END	
									
					MERGE CONT_Direcciones AS Direccion
					USING 
					(
						SELECT
						tablaDirecciones.id AS id_direccion,
						tablaDirecciones.direccion,
						Asentamiento.codigo_postal,
						tablaDirecciones.id_asentamiento,
						tablaDirecciones.id_localidad,
						tablaDirecciones.id_estado,
						tablaDirecciones.id_municipio,
						tablaDirecciones.id_pais,
						tablaDirecciones.casa_situacion,
						tablaDirecciones.tiempo_habitado_inicio,
						tablaDirecciones.tiempo_habitado_final,
						tablaDirecciones.correo_electronico,
						tablaDirecciones.numero_interior,
						tablaDirecciones.numero_exterior,
						tablaDirecciones.referencia,
						tablaDirecciones.num_interior,
						tablaDirecciones.num_exterior,
						tablaDirecciones.id_vialidad
							
						FROM @tablaDirecciones tablaDirecciones
						CROSS APPLY
						(
							SELECT 
							CATA_asentamiento.codigo_postal FROM CATA_asentamiento WHERE CATA_asentamiento.id=tablaDirecciones.id_asentamiento
						) Asentamiento
						
					) AS DireccionModificada 
					ON Direccion.id = DireccionModificada.id_direccion AND Direccion.estatus_registro='ACTIVO'
					WHEN MATCHED THEN
					UPDATE  
						SET
						Direccion.direccion=DireccionModificada.direccion,
						Direccion.colonia=DireccionModificada.id_asentamiento,
						Direccion.codigo_postal=DireccionModificada.codigo_postal,
						Direccion.localidad=DireccionModificada.id_localidad,
						Direccion.estado=DireccionModificada.id_estado,
						Direccion.municipio=DireccionModificada.id_municipio,
						Direccion.pais=DireccionModificada.id_pais,
						Direccion.predeterminado=0,
						Direccion.casa_situacion=DireccionModificada.casa_situacion,
						Direccion.tiempo_habitado_inicio=DireccionModificada.tiempo_habitado_inicio,
						Direccion.tiempo_habitado_final=DireccionModificada.tiempo_habitado_final,
						Direccion.correo_electronico=CAST(DireccionModificada.correo_electronico AS VARCHAR(50)),
						Direccion.hipotecada=0,
						Direccion.numero_interior=DireccionModificada.numero_interior,
						Direccion.numero_exterior=DireccionModificada.numero_exterior,
						Direccion.referencia=DireccionModificada.referencia,
						Direccion.num_interior=DireccionModificada.num_interior,
						Direccion.num_exterior=DireccionModificada.num_exterior,
						Direccion.vialidad=DireccionModificada.id_vialidad,
						Direccion.creado_por=@id_sesion,
						Direccion.fecha_registro=GETDATE(),
						Direccion.modificado_por=@id_sesion,
						Direccion.fecha_revision=GETDATE()
														
					OUTPUT inserted.id, $action INTO @tablaDireccionModificada;
					
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(id_direccion,0)>0
					THEN id_direccion ELSE 0 END,  
					'DIRECCION',	
					CASE  WHEN ISNULL(id_direccion,0)>0 THEN 'MODIFICACI�N CORRECTA' ELSE 'MODIFICACI�N ERR�NEA' END
					FROM @tablaDireccionModificada
					
							
					
					MERGE CONT_Oficinas AS Oficina
					USING 
					(
						SELECT
						tablaOficinas.id AS id_oficina,
						tablaOficinas.id_empresa AS id_empresa,
						tablaOficinas.id_direccion,
						tablaOficinas.matriz,
						tablaOficinas.nombre_oficina,
						tablaOficinas.funcion_oficina,
						tablaOficinas.email_sucursal,
						tablaOficinas.horario,tipo_local,
						tablaOficinas.dias_laborales,
						tablaOficinas.descripcion
						
						FROM @tablaOficinas tablaOficinas
						INNER JOIN @tablaEmpresaModificada  EmpresaModificada ON EmpresaModificada.id_empresa=tablaOficinas.id_empresa
						INNER JOIN @tablaDireccionModificada DireccionModificada ON DireccionModificada.id_direccion=tablaOficinas.id_direccion
						
					) AS OficinaModificada 
					ON Oficina.id = OficinaModificada.id_oficina 
					WHEN MATCHED THEN
					UPDATE  
						SET
						Oficina.ID_EMPRESA=OficinaModificada.id_empresa,
						Oficina.ID_DIRECCION=OficinaModificada.id_direccion,
						Oficina.MATRIZ=OficinaModificada.matriz,
						Oficina.NOMBRE_OFICINA=OficinaModificada.nombre_oficina,
						Oficina.FUNCION_OFICINA=OficinaModificada.funcion_oficina,
						Oficina.EMAIL_SUCURSAL=OficinaModificada.email_sucursal,
						Oficina.HORARIO=OficinaModificada.horario,
						Oficina.TIPO_LOCAL=OficinaModificada.tipo_local,
						Oficina.DIAS_LABORALES=OficinaModificada.dias_laborales,
						Oficina.DESCRIPCION=OficinaModificada.descripcion
						
					OUTPUT inserted.id, $action INTO @tablaOficinaModificada;
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(id_oficina,0)>0
					THEN id_oficina ELSE 0 END,  
					'OFICINA',	
					CASE  WHEN ISNULL(id_oficina,0)>0 THEN 'MODIFICACI�N CORRECTA' ELSE 'MODIFICACI�N ERR�NEA' END
					FROM @tablaOficinaModificada
					
					
					
					MERGE CONT_Telefonos AS Telefono
					USING
					(
						SELECT 
						tablaTelefonos.id AS id_telefono,
						tablaTelefonos.idcel_telefono,
						tablaTelefonos.extension,
						tablaTelefonos.tipo_telefono,
						tablaTelefonos.compania,
						tablaTelefonos.sms
						FROM @tablaTelefonos tablaTelefonos
						
					) AS TelefonoModificado
					ON Telefono.id=TelefonoModificado.id_telefono AND Telefono.estatus_registro='ACTIVO'
					WHEN MATCHED THEN
					UPDATE  
						SET
						Telefono.idcel_telefono=TelefonoModificado.idcel_telefono,
						Telefono.extension=TelefonoModificado.extension,
						Telefono.tipo_telefono=TelefonoModificado.tipo_telefono,
						Telefono.compania=CAST(TelefonoModificado.compania AS CHAR(20)),
						Telefono.sms=TelefonoModificado.sms,
						Telefono.mms=0,
						Telefono.predeterminado=0,
						Telefono.creado_por=@id_sesion,
						Telefono.fecha_registro=GETDATE(),
						Telefono.modificado_por=@id_sesion,
						Telefono.fecha_revision=GETDATE()
						
					OUTPUT inserted.id, $action INTO @tablaTelefonoModificado;
					
					INSERT INTO   @tablaResultados
					SELECT
					CASE  WHEN ISNULL(id_telefono,0)>0
					THEN id_telefono ELSE 0 END,  
					'TELEFONO',	
					CASE  WHEN ISNULL(id_telefono,0)>0 THEN 'MODIFICACI�N CORRECTA' ELSE 'MODIFICACI�N ERR�NEA' END
					FROM @tablaTelefonoModificado
							
			END
			
			SELECT id_resultado,accion,resultado FROM @tablaResultados
			
		COMMIT TRANSACTION insert_update_empresa_relaciones
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION insert_update_empresa_relaciones
		INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
        SELECT
    	ERROR_NUMBER() AS Numero_de_Error,
    	ERROR_SEVERITY() AS Gravedad_del_Error,
    	ERROR_STATE() AS Estado_del_Error,
    	ERROR_PROCEDURE() AS Procedimiento_del_Error,
    	ERROR_LINE() AS Linea_de_Error,
    	ERROR_MESSAGE() AS Mensaje_de_Error,
        'CONT_AdministrarEmpresa' AS Procedimiento_Origen;
        DELETE FROM @tablaResultados
        INSERT INTO @tablaResultados
        SELECT 0,'EXCEPCION', ERROR_MESSAGE()
      
		SELECT id_resultado,accion,resultado FROM @tablaResultados
	END CATCH
	
END
GO

--#endregion ------------------------------------- FIN PROCEDURE CREATE NEGOCIO(EMPRESA) ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE CREATE CLIENT ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_insertarInformacionClienteV2
    @info_persona UDT_CONT_Persona readonly, 
    @info_identificaciones UDT_CONT_Identificaciones readonly, 
    @info_telefonos UDT_CONT_Telefonos readonly, 
    @info_empleos UDT_CONT_Negocios readonly, 
    @info_cliente UDT_CLIE_Clientes readonly,
    @info_individual  UDT_CLIE_Individual readonly, 
    @info_solicitud UDT_CLIE_Solicitud readonly,
    @info_dato_bancario UDT_CLIE_DatoBancario readonly, 
    --@info_referencias_personales UDT_CLIE_Referencias readonly, 
    @info_datos_pld UDT_SPLD_DatosCliente readonly,
    @info_firma_electronica UDT_CONT_FirmaElectronica readonly,
    @id_opcion INT,
    @uid INT
AS
BEGIN TRY
/****** Object:  StoredProcedure [dbo].[CLIE_insertarInformacionClienteV2]    Script Date: 09/03/2021 12:56:33 p. m. ******/
--Alter Date:	<26/12/2017> <Se modifica para que s�lo el gerente de sucursal o el regional puedan editar los datos del cliente una vez que el cr�dito est� activo o autorizado>
--							 <Las Personas Pol�ticamente Expuestas y las Personas Prohibidas o Bloqueadas se eval�an siempre que el usuario en sesi�n tenga permisos de edici�n de los datos del cliente mientras que el perfil transaccional, adem�s de tomar en cuenta lo anterior, solamente se eval�a  si el cr�dito esta activo>
--							 <Se inserta los datos de id_asentamiento, id_ciudad, id_estado, id_pais y direccion de la persona en SPLD_DatosCliente>
--Alter Date:	<03/12/2020> <Se quita todo lo relacionado con la asignaci�n de folio de cr�dito al cliente>
--Alter Date:	<01/09/2021> <Se inserta un historial de la tabla CLIE_DatoBancario y se valida que no se ingrese m�s de una cuenta de un mismo banco y m�s de una cuenta como principal>
	DECLARE 
        @idPersona INT,
        @idIdentificacionPROSPERA INT,
        @idMinTelefono INT,
        @idEmpresa INT,
        @idEmpleo INT,
        @idCliente INT,
        @idClienteOriginal INT,
        @idServicioFinanciero INT,
        @tipoCliente INT,
        @ciclo INT,
        @idReferencia INT;
        
    DECLARE 
        @id_persona_politicamente_expuesta INT,
        @id_persona_prohibida INT,
        @nombre VARCHAR(255),        
        @paterno VARCHAR(255),      
        @materno VARCHAR(255),
        @intDetonoAlarma INT,
        @FamiliarDesempeniaFuncionPublica BIT,
        @id_firma_electronica INT ,
        @perfil_riesgo VARCHAR(20)
        
    DECLARE @TablaRetornoCliente AS TABLE
    (
		id_cliente INT,
		id_persona INT,
		id_identificacion_curp INT,
		id_archivo_subido INT,
		mensaje VARCHAR(10),
		procedimiento VARCHAR(50),
		linea INT,
		evento VARCHAR(MAX)
    )
    
    DECLARE @DATOSReporteCNBV UDT_SPLD_ReporteCNBV;
	DECLARE @ResultadoOperacion TABLE
	(
		id_registro INT,
		tipo VARCHAR(50),
		resultado VARCHAR(50),
		mensaje VARCHAR(800),
		string_auxiliar VARCHAR(250),
		int_auxiliar INT
	)
	DECLARE @Resultado VARCHAR(50)
	DECLARE @Mensaje VARCHAR(800)
    
    --== NUEVAS VARIABLES SPLD ==
    DECLARE 
	@desempenia_funcion_publicaULTIMO BIT = 0, 
	@desempenia_funcion_publicaACTUAL BIT = 0, 
	@familiar_desempenia_funcion_publicaULTIMO BIT = 0,
	@familiar_desempenia_funcion_publicaACTUAL BIT = 0,
	@id_naturaleza_pagoULTIMO INT = 0, @etiqueta_naturaleza_pagoULTIMO VARCHAR(350) = '',
	@id_naturaleza_pagoACTUAL INT = 0, @etiqueta_naturaleza_pagoACTUAL VARCHAR(350) = '',
	@id_profesionULTIMO INT = 0, 
	@id_profesionACTUAL INT = 0, 
	@id_ocupacionULTIMO INT = 0, 
	@id_ocupacionACTUAL INT = 0, 
	@id_asentamientoULTIMO INT=0,
	@id_ciudadULTIMO INT=0,
	@id_municipioULTIMO INT = 0, 
	@id_estadoULTIMO INT=0,
	@id_paisULTIMO INT=0,
	@direccionULTIMO VARCHAR(800)='',
	@id_asentamientoACTUAL INT = 0, 
	@id_ciudadACTUAL INT = 0, 
	@id_municipioACTUAL INT = 0, 
	@id_estadoACTUAL INT = 0, 
	@id_paisACTUAL INT = 0, 
	@direccionACTUAL VARCHAR(800)='',
	@id_destino_creditoULTIMO INT = 0, @etiqueta_destino_creditoULTIMO VARCHAR(350) = '',
	@id_destino_creditoACTUAL INT = 0, @etiqueta_destino_creditoACTUAL VARCHAR(350) = '',
	@id_actividad_economicaULTIMO INT = 0, @etiqueta_actividad_economicaULTIMO VARCHAR(350) = '',
	@id_actividad_economicaACTUAL INT = 0, @etiqueta_actividad_economicaACTUAL VARCHAR(350) = '',
	@id_pais_nacimientoULTIMO INT = 0, 
	@id_pais_nacimientoACTUAL INT = 0, 
	@id_nacionalidadULTIMO INT = 0, 
	@id_nacionalidadACTUAL INT = 0, 
	@es_pepULTIMO INT = 0, 
	@es_pepACTUAL INT = 0,
	@es_persona_prohibidaULTIMO INT = 0,
	@es_persona_prohibidaACTUAL INT = 0,

	--nuevas variables para lista--
    @nombreSocia VARCHAR(255) = '',
    @tipoListaSocia VARCHAR(100) = ''
    
	DECLARE @INFOCambiosDetectados VARCHAR(MAX) = '', @HASChange INT = 0, @DETONAAlarma INT = 0, @LASTPerfil VARCHAR(100) = '';
    --==  ==
     
    IF(@id_opcion<>1)
    BEGIN      
		
		SET @perfil_riesgo='BAJO RIESGO' 
		--Obtiene id persona      
		SELECT @idPersona = ISNULL(id, 0) FROM @info_persona;
		--Obtiene id de la identificaci�n de PROSPERA
		SELECT @idIdentificacionPROSPERA = ISNULL(id, 0) FROM @info_identificaciones WHERE tipo_identificacion = 'PROSPERA' AND tipo_entidad = 1;

		--Obtiene id Cliente
		SELECT @idCliente = ISNULL(id, 0) FROM @info_cliente;
	    
		--Se respalda el id Original
		SET @idClienteOriginal = @idCliente;
	
		SET @id_firma_electronica=(SELECT TOP(1)FirmaElectronica.id_firma_electronica FROM @info_firma_electronica FirmaElectronica)


		DECLARE @permitir_modificacion BIT=1

		IF(@permitir_modificacion=1)
		BEGIN
			
			IF(@id_firma_electronica=0)
			BEGIN
				INSERT INTO CONT_Fiel 
				SELECT @idPersona,fiel,@uid,GETDATE(),@uid,GETDATE(),'ACTIVO' FROM @info_firma_electronica
			END
			ELSE IF(@id_firma_electronica>0)
			BEGIN
        
					UPDATE CONT_Fiel SET fiel=tFirmaElectronica.fiel
					FROM @info_firma_electronica tFirmaElectronica
					WHERE CONT_Fiel.id=@id_firma_electronica        
			END
			    
			--Insertar/Actualizar Identificaciones
		
			IF @idIdentificacionPROSPERA = 0
			BEGIN
				INSERT INTO CONT_IdentificacionOficial (id_persona, tipo_identificacion, id_numero, id_direccion, 
        			estatus_registro, creado_por, fecha_registro, modificado_por, fecha_revision)
				SELECT TOP(1) @idPersona, tipo_identificacion, id_numero, @idIdentificacionPROSPERA, 'ACTIVO', @uid, GETDATE(),
        			@uid, GETDATE() 
				FROM @info_identificaciones 
				WHERE tipo_identificacion = 'PROSPERA' AND tipo_entidad = 1; SELECT @idIdentificacionPROSPERA = @@IDENTITY;
			END
			ELSE
			BEGIN
    			UPDATE CONT_IdentificacionOficial SET id_persona = @idPersona, tipo_identificacion = tIdentificaciones.tipo_identificacion,
       				id_numero = tIdentificaciones.id_numero, id_direccion = 0, modificado_por = @uid, fecha_revision = GETDATE()
				FROM @info_identificaciones tIdentificaciones
				WHERE CONT_IdentificacionOficial.id = @idIdentificacionPROSPERA AND tIdentificaciones.tipo_identificacion = 'PROSPERA';
			END
		
			--Insertar/Actualizar Tel�fonos
			BEGIN
			--Tabla para almacenar los Id de telefonos insertados
			DECLARE @tablevar TABLE (_id INT);
		
			--Insertar
			INSERT INTO CONT_Telefonos(idcel_telefono,extension, tipo_telefono, compania,sms,mms, estatus_registro, creado_por, fecha_registro, modificado_por, fecha_revision)
    			OUTPUT INSERTED.id INTO @tablevar
			SELECT idcel_telefono,extension, tipo_telefono,compania, sms,CAST(0 AS BIT), 'ACTIVO', @uid, GETDATE(), @uid, GETDATE()
			FROM @info_telefonos
			WHERE id = 0
	    
			--Se escoje el Id Minimo
			SELECT @idMinTelefono = ISNULL(MIN(_id), 0) FROM @tablevar
	    
			WHILE (@idMinTelefono IS NOT NULL)
			BEGIN
    			--Insertar relacion Persona - Telefono
				INSERT INTO CONT_TelefonosPersona(id_telefono, id_persona)
				VALUES(@idMinTelefono, @idPersona) 
	        
				--Se busca el siguiente Id telefono
    			SELECT @idMinTelefono = MIN(_id) FROM @tablevar WHERE _id > @idMinTelefono;
			END
	    
			--Actualizar
			--Reset al id
			SET @idMinTelefono = 0;
	    
			--Se escoje el Id Minimo
			SELECT @idMinTelefono = MIN(id) FROM @info_telefonos
	    
			WHILE (@idMinTelefono IS NOT NULL)
			BEGIN
    			--Actualizar informaci�n de tel�fono
				IF (SELECT TOP(1) LTRIM(RTRIM(idcel_telefono)) FROM @info_telefonos WHERE id = @idMinTelefono) <> ''
				BEGIN
					UPDATE CONT_Telefonos SET idcel_telefono = tTelefonos.idcel_telefono, tipo_telefono = tTelefonos.tipo_telefono, 
						compania=tTelefonos.compania,
						sms = tTelefonos.sms, estatus_registro = 'ACTIVO', modificado_por = @uid, fecha_revision = GETDATE()
					FROM @info_telefonos tTelefonos
					WHERE CONT_Telefonos.id = @idMinTelefono AND tTelefonos.id = @idMinTelefono;        
				END
				ELSE
				BEGIN
       				UPDATE CONT_Telefonos SET estatus_registro = 'ELIMINADO', modificado_por = @uid, fecha_revision = GETDATE()
					--FROM @info_telefonos tTelefonos
					WHERE CONT_Telefonos.id = @idMinTelefono; 
				END
	        
				--Se busca el siguiente Id telefono
    			SELECT @idMinTelefono = MIN(id) FROM @info_telefonos WHERE id > @idMinTelefono;
			END
			END
	    
			--Insertar/Actualizar Negocios
			--Actualizar Informacion de Empresas
			BEGIN 
			SELECT @idEmpresa = MIN(id_empresa) FROM @info_empleos;
	    
			WHILE(@idEmpresa IS NOT NULL)
			BEGIN
    			UPDATE CONT_Empresas SET econ_numero_empleados = tEmpresas.numero_empleados, econ_registro_egresos_ingresos = tEmpresas.registro_egresos_ingreso, econ_revolvencia_negocio = tEmpresas.revolvencia_negocio,
        			econ_ventas_totales_cantidad = tEmpresas.ventas_totales_cantidad, econ_ventas_totales_unidad = tEmpresas.ventas_totales_unidad, id_actividad_economica = tEmpresas.id_actividad_economica, 
					tiempo_actividad_inicio = tEmpresas.tiempo_actividad_inicio, tiempo_actividad_final = tEmpresas.tiempo_actividad_final, 
        			modificado_por = @uid, fecha_revision = GETDATE()
				FROM @info_empleos tEmpresas
				WHERE CONT_Empresas.id = @idEmpresa AND tEmpresas.id_empresa = @idEmpresa; 
	        
    			--Se busca el siguiente id empresa
    			SELECT @idEmpresa = MIN(id_empresa) FROM @info_empleos WHERE id_empresa > @idEmpresa;
			END
			END
	    
			--Empleos
			BEGIN
			INSERT INTO CONT_Empleados(id_persona, id_oficina, oficina, nombre_puesto, departamento, tiempo_actividad_inicio, tiempo_actividad_final, estatus_registro, creado_por, fecha_registro, modificado_por, fecha_revision)
			SELECT @idPersona, id_oficina, nombre_oficina, nombre_puesto, departamento, tiempo_actividad_inicio, tiempo_actividad_final, 'ACTIVO', @uid, GETDATE(), @uid, GETDATE()
			FROM @info_empleos AS tEmpleos 
			WHERE tEmpleos.id = 0;
	    
			--Actualizar Informaci�n Empleos
			SELECT @idEmpleo = MIN(id) FROM @info_empleos WHERE id <> 0;
	    
			IF @idEmpleo <> 0
			BEGIN
				WHILE(@idEmpleo IS NOT NULL)
				BEGIN
					UPDATE CONT_Empleados SET id_persona = @idPersona, id_oficina = tEmpleos.id_oficina, oficina = tEmpleos.nombre_oficina, nombre_puesto = tEmpleos.nombre_puesto, 
						departamento = tEmpleos.departamento, tiempo_actividad_inicio = tEmpleos.tiempo_actividad_inicio, tiempo_actividad_final = tEmpleos.tiempo_actividad_final,
						modificado_por = @uid, fecha_revision = GETDATE()
					FROM @info_empleos tEmpleos
					WHERE CONT_Empleados.id = @idEmpleo AND tEmpleos.id = @idEmpleo; 
	            
					--Se busca el siguiente id empresa
					SELECT @idEmpleo = MIN(id) FROM @info_empleos WHERE id > @idEmpleo;
				END
			END
			END
	    
			--Insertar/Actualizar Cliente/Individual
			IF @idCliente = 0
			BEGIN
    			--Insertar Cliente
				INSERT INTO CLIE_Clientes (estatus, sub_estatus, id_oficina, id_oficial_credito, folio_solicitud_credito, tipo_cliente,
        			estatus_registro, activo, lista_negra, creado_por, fecha_registro, modificado_por, fecha_revision)
				SELECT TOP(1) '', '', id_oficina, id_oficial_credito, folio_solicitud_credito, 2, 'ACTIVO', 0, 0, @uid, GETDATE(), @uid, GETDATE()
				FROM @info_cliente; SELECT @idCliente = @@IDENTITY;
	        
				--Insertar Individual
				INSERT INTO CLIE_Individual(id_cliente, id_persona, econ_ocupacion, econ_id_actividad_economica, econ_id_destino_credito, econ_id_ubicacion_negocio,
        			econ_id_rol_hogar, econ_id_empresa, econ_cantidad_mensual, econ_sueldo_conyugue, econ_otros_ingresos, econ_otros_gastos, econ_familiares_extranjeros,
					econ_parentesco, econ_envia_dinero, econ_dependientes_economicos, econ_pago_casa, econ_gastos_vivienda, econ_gastos_familiares, econ_gastos_transporte,
					credito_anteriormente,mejorado_ingreso,lengua_indigena,habilidad_diferente,utiliza_internet,utiliza_redes_sociales,id_actividad_economica,id_ocupacion,id_profesion,
					desempenia_funcion_publica,desempenia_funcion_publica_cargo,desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica,familiar_desempenia_funcion_publica_cargo,
					familiar_desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica_nombre,familiar_desempenia_funcion_publica_paterno,familiar_desempenia_funcion_publica_materno,
					familiar_desempenia_funcion_publica_parentesco,id_instrumento_monetario)
				SELECT TOP(1) @idCliente, @idPersona, econ_ocupacion, econ_id_actividad_economica, econ_id_destino_credito, econ_id_ubicacion_negocio, econ_id_rol_hogar,
        			econ_id_empresa, econ_cantidad_mensual, econ_sueldo_conyugue, econ_otros_ingresos, econ_otros_gastos, econ_familiares_extranjeros, econ_parentesco,
					econ_envia_dinero, econ_dependientes_economicos, econ_pago_casa, econ_gastos_vivienda, econ_gastos_familiares, econ_gastos_transporte,
					credito_anteriormente,mejorado_ingreso,lengua_indigena,habilidad_diferente,utiliza_internet,utiliza_redes_sociales,id_actividad_economica,id_ocupacion,id_profesion,
					tSPLD.desempenia_funcion_publica,desempenia_funcion_publica_cargo,tSPLD.desempenia_funcion_publica_dependencia,tSPLD.familiar_desempenia_funcion_publica,tSPLD.familiar_desempenia_funcion_publica_cargo,
					tSPLD.familiar_desempenia_funcion_publica_dependencia,tSPLD.familiar_desempenia_funcion_publica_nombre,tSPLD.familiar_desempenia_funcion_publica_paterno,tSPLD.familiar_desempenia_funcion_publica_materno,
					tSPLD.familiar_desempenia_funcion_publica_parentesco,tSPLD.id_instrumento_monetario
				FROM @info_individual,@info_datos_pld tSPLD;
			END
			ELSE
			BEGIN
    			--Actualizar Cliente
    			UPDATE CLIE_Clientes SET id_oficial_credito = tCliente.id_oficial_credito, folio_solicitud_credito = tCliente.folio_solicitud_credito, 
					modificado_por = @uid, fecha_revision = GETDATE()
				FROM @info_cliente tCliente
				WHERE CLIE_Clientes.id = @idCliente;
	        
				--Si no hay registro en la tabla clie_individual
				IF (SELECT CLIE_Individual.id_cliente FROM CLIE_Individual WHERE CLIE_Individual.id_cliente = @idCliente) IS NULL
				BEGIN
        			--Insertar Individual
					INSERT INTO CLIE_Individual(id_cliente, id_persona, econ_ocupacion, econ_id_actividad_economica, econ_id_destino_credito, econ_id_ubicacion_negocio,
						econ_id_rol_hogar, econ_id_empresa, econ_cantidad_mensual, econ_sueldo_conyugue, econ_otros_ingresos, econ_otros_gastos, econ_familiares_extranjeros,
						econ_parentesco, econ_envia_dinero, econ_dependientes_economicos, econ_pago_casa, econ_gastos_vivienda, econ_gastos_familiares, econ_gastos_transporte,
						credito_anteriormente,mejorado_ingreso,lengua_indigena,habilidad_diferente,utiliza_internet,utiliza_redes_sociales,id_actividad_economica,id_ocupacion,id_profesion,
						desempenia_funcion_publica,desempenia_funcion_publica_cargo,desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica,familiar_desempenia_funcion_publica_cargo,
						familiar_desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica_nombre,familiar_desempenia_funcion_publica_paterno,familiar_desempenia_funcion_publica_materno,
						familiar_desempenia_funcion_publica_parentesco,id_instrumento_monetario)
					SELECT TOP(1) @idCliente, @idPersona, econ_ocupacion, econ_id_actividad_economica, econ_id_destino_credito, econ_id_ubicacion_negocio, econ_id_rol_hogar,
						econ_id_empresa, econ_cantidad_mensual, econ_sueldo_conyugue, econ_otros_ingresos, econ_otros_gastos, econ_familiares_extranjeros, econ_parentesco,
						econ_envia_dinero, econ_dependientes_economicos, econ_pago_casa, econ_gastos_vivienda, econ_gastos_familiares, econ_gastos_transporte,
						credito_anteriormente,mejorado_ingreso,lengua_indigena,habilidad_diferente,utiliza_internet,utiliza_redes_sociales,id_actividad_economica,id_ocupacion,id_profesion,
						tSPLD.desempenia_funcion_publica,desempenia_funcion_publica_cargo,tSPLD.desempenia_funcion_publica_dependencia,tSPLD.familiar_desempenia_funcion_publica,tSPLD.familiar_desempenia_funcion_publica_cargo,
						tSPLD.familiar_desempenia_funcion_publica_dependencia,tSPLD.familiar_desempenia_funcion_publica_nombre,tSPLD.familiar_desempenia_funcion_publica_paterno,tSPLD.familiar_desempenia_funcion_publica_materno,
						tSPLD.familiar_desempenia_funcion_publica_parentesco,tSPLD.id_instrumento_monetario
					FROM @info_individual,@info_datos_pld tSPLD;
				END
				ELSE
				BEGIN
					--Actualizar individual
					UPDATE CLIE_Individual SET id_cliente = @idCliente, id_persona = @idPersona, econ_ocupacion = tIndividual.econ_ocupacion, 
						econ_id_actividad_economica = tIndividual.econ_id_actividad_economica, econ_id_destino_credito = tIndividual.econ_id_destino_credito, 
						econ_id_ubicacion_negocio = tIndividual.econ_id_ubicacion_negocio, econ_id_rol_hogar = tIndividual.econ_id_rol_hogar, 
						econ_id_empresa = tIndividual.econ_id_empresa, econ_cantidad_mensual = tIndividual.econ_cantidad_mensual, 
						econ_sueldo_conyugue = tIndividual.econ_sueldo_conyugue, econ_otros_ingresos = tIndividual.econ_otros_ingresos, 
						econ_otros_gastos = tIndividual.econ_otros_gastos, econ_familiares_extranjeros = tIndividual.econ_familiares_extranjeros, 
						econ_parentesco = tIndividual.econ_parentesco, econ_envia_dinero = tIndividual.econ_envia_dinero, 
						econ_dependientes_economicos = tIndividual.econ_dependientes_economicos, econ_pago_casa = tIndividual.econ_pago_casa, 
						econ_gastos_vivienda = tIndividual.econ_gastos_vivienda, econ_gastos_familiares = tIndividual.econ_gastos_familiares, 
						econ_gastos_transporte = tIndividual. econ_gastos_transporte,
						credito_anteriormente=tIndividual.credito_anteriormente,
						mejorado_ingreso=tIndividual.mejorado_ingreso,
						lengua_indigena=tIndividual.lengua_indigena,
						habilidad_diferente=tIndividual.habilidad_diferente,
						utiliza_internet=tIndividual.utiliza_internet,
						utiliza_redes_sociales=tIndividual.utiliza_redes_sociales,
						id_actividad_economica=  tIndividual.id_actividad_economica,
						id_ocupacion=tIndividual.id_ocupacion,
						id_profesion=tIndividual.id_profesion,
						CLIE_Individual.desempenia_funcion_publica=tSPLD.desempenia_funcion_publica,
						CLIE_Individual.desempenia_funcion_publica_cargo=tSPLD.desempenia_funcion_publica_cargo,
						CLIE_Individual.desempenia_funcion_publica_dependencia=tSPLD.desempenia_funcion_publica_dependencia,
						CLIE_Individual.familiar_desempenia_funcion_publica=tSPLD.familiar_desempenia_funcion_publica,
						CLIE_Individual.familiar_desempenia_funcion_publica_cargo=tSPLD.familiar_desempenia_funcion_publica_cargo,
						CLIE_Individual.familiar_desempenia_funcion_publica_dependencia=tSPLD.familiar_desempenia_funcion_publica_dependencia,
						CLIE_Individual.familiar_desempenia_funcion_publica_nombre=tSPLD.familiar_desempenia_funcion_publica_nombre,
						CLIE_Individual.familiar_desempenia_funcion_publica_paterno=tSPLD.familiar_desempenia_funcion_publica_paterno,
						CLIE_Individual.familiar_desempenia_funcion_publica_materno=tSPLD.familiar_desempenia_funcion_publica_materno,
						CLIE_Individual.familiar_desempenia_funcion_publica_parentesco=tSPLD.familiar_desempenia_funcion_publica_parentesco,
						CLIE_Individual.id_instrumento_monetario=tSPLD.id_instrumento_monetario

					FROM @info_individual tIndividual
					INNER JOIN @info_datos_pld tSPLD ON tIndividual.id_cliente=tSPLD.id_cliente
					WHERE CLIE_Individual.id_cliente = @idCliente;
				END
			END      
	    			
			DECLARE @mensaje_dato_bancario VARCHAR(50)=''

			IF NOT EXISTS
			(
				SELECT 
				*
				FROM
				(
					SELECT 
					UDT_DatoBancario.id_banco,
					UDT_DatoBancario.numero_cuenta, 
					COUNT(*) AS cuentas_iguales 
					FROM @info_dato_bancario UDT_DatoBancario 
					WHERE 
					UDT_DatoBancario.principal=1
					AND UDT_DatoBancario.activo=1
					GROUP BY id_banco,UDT_DatoBancario.numero_cuenta
					HAVING COUNT(*)>1
				)CuentasRepetidas
				WHERE CuentasRepetidas.cuentas_iguales>1
			)
			BEGIN
				IF ((SELECT COUNT(*) FROM @info_dato_bancario  WHERE principal=1 AND activo=1)>=0 AND (SELECT COUNT(*) FROM @info_dato_bancario  WHERE principal=1 AND activo=1)<=1)
				BEGIN
					
					IF EXISTS (SELECT * FROM CLIE_DatoBancario WHERE id_banco in (SELECT id_banco FROM @info_dato_bancario  WHERE principal=1 AND activo=1) AND numero_cuenta IN (SELECT numero_cuenta FROM @info_dato_bancario  WHERE principal=1 AND activo=1) AND id_cliente<>@idCliente AND principal=1 AND activo=1)
					BEGIN
						DECLARE @id_cliente INT;
						SELECT TOP(1) @id_cliente=COALESCE(id_cliente,0) FROM CLIE_DatoBancario WHERE id_banco in (SELECT id_banco FROM @info_dato_bancario  WHERE principal=1 AND activo=1) AND numero_cuenta IN (SELECT numero_cuenta FROM @info_dato_bancario  WHERE principal=1 AND activo=1) AND id_cliente<>@idCliente AND principal=1 AND activo=1
						
						SET @mensaje_dato_bancario='Una o m�s cuentas que intenta guardar, ya existe para otro id cliente: '+CAST(@id_cliente AS VARCHAR(12));
					END
					ELSE
					BEGIN
						--Insertar/Actualizar Cuenta Bancaria 

						DECLARE @DatosBancarios TABLE
						(
							id_dato_bancario [bigint],
							[id_cliente] [int],
							[id_banco] [int],
							[clave_banco] [varchar](50),
							[nombre_banco] [varchar](100),
							[id_tipo_cuenta] [int],
							[clave_tipo_cuenta] [varchar](100),
							[nombre_tipo_cuenta] [varchar](100),
							[numero_cuenta] [varchar](50),
							[principal] [bit],
							[creado_por] [int],
							[fecha_creacion] [datetime],
							[modificado_por] [int],
							[fecha_modificacion] [datetime],
							[activo] [bit],
							[accion][varchar](20)
						)


						MERGE CLIE_DatoBancario
						USING (
							SELECT id, id_cliente, id_banco, clave_banco, nombre_banco, id_tipo_cuenta, clave_tipo_cuenta, 
								   nombre_tipo_cuenta, numero_cuenta, principal, activo
							FROM @info_dato_bancario UDT
						) AS UDT
						ON CLIE_DatoBancario.id = UDT.id
						WHEN MATCHED THEN
						UPDATE SET 
							CLIE_DatoBancario.id_banco = UDT.id_banco,
							CLIE_DatoBancario.clave_banco = UDT.clave_banco,
							CLIE_DatoBancario.nombre_banco = UDT.nombre_banco,
							CLIE_DatoBancario.id_tipo_cuenta = UDT.id_tipo_cuenta,
							CLIE_DatoBancario.clave_tipo_cuenta = UDT.clave_tipo_cuenta,
							CLIE_DatoBancario.nombre_tipo_cuenta = UDT.nombre_tipo_cuenta,
							CLIE_DatoBancario.numero_cuenta = UDT.numero_cuenta,
							CLIE_DatoBancario.principal = UDT.principal,
							CLIE_DatoBancario.activo = UDT.activo,
							CLIE_DatoBancario.modificado_por = @uid,
							CLIE_DatoBancario.fecha_modificacion = GETDATE()
						WHEN NOT MATCHED THEN 
						INSERT (id_cliente, id_banco, clave_banco, nombre_banco, id_tipo_cuenta, clave_tipo_cuenta, nombre_tipo_cuenta, 
								numero_cuenta, principal, creado_por, fecha_creacion, modificado_por, fecha_modificacion, activo)
						VALUES(@idCliente, id_banco, clave_banco, nombre_banco, id_tipo_cuenta, clave_tipo_cuenta, nombre_tipo_cuenta, 
								numero_cuenta, principal, @uid, GETDATE(), @uid, GETDATE(), activo)

						OUTPUT inserted.id, inserted.id_cliente, inserted.id_banco, inserted.clave_banco, inserted.nombre_banco, inserted.id_tipo_cuenta, inserted.clave_tipo_cuenta, inserted.nombre_tipo_cuenta, inserted.numero_cuenta, inserted.principal, inserted.creado_por, inserted.fecha_creacion, inserted.modificado_por, inserted.fecha_modificacion, inserted.activo, $action INTO @DatosBancarios;

						INSERT INTO CLIE_DatoBancarioHistory (id_dato_bancario, id_cliente, id_banco, clave_banco, nombre_banco, id_tipo_cuenta, clave_tipo_cuenta, nombre_tipo_cuenta, numero_cuenta, principal, creado_por, fecha_creacion, modificado_por, fecha_modificacion, activo, accion)
						SELECT 
						id_dato_bancario, 
						id_cliente, 
						id_banco, 
						clave_banco, 
						nombre_banco, 
						id_tipo_cuenta, 
						clave_tipo_cuenta, 
						nombre_tipo_cuenta, 
						numero_cuenta, 
						principal, 
						creado_por, 
						fecha_creacion, 
						modificado_por, 
						fecha_modificacion, 
						activo, 
						accion
						FROM
						@DatosBancarios
					END
				END
				ELSE
				BEGIN
					SET @mensaje_dato_bancario='Debe haber s�lo una cuenta como principal';
				END
			END
			ELSE
			BEGIN
				SET @mensaje_dato_bancario='No se puede guardar m�s de una cuenta del mismo banco y el mismo numero de cuenta';
			END

			--Insertar/Actualizar Relaciones Personales
			--Insertar
			--INSERT INTO CLIE_R_I (id_cliente, id_referencia, ciclo, parentesco, tipo_relacion, tipo, eliminado, delete_motivo, antiguedad, id_conyugue, id_empleado, creado_por, fecha_creacion, modificado_por, fecha_revision)
			--SELECT @idCliente, id_referencia, 0, parentesco, tipo_relacion, tipo, eliminado, 'NE', GETDATE(), 0, id_empleado, @uid, GETDATE(), @uid, GETDATE()
			--FROM @info_referencias_personales tReferencias WHERE tReferencias.id = 0;
	    
			----Actualizar
			--SELECT @idReferencia = MIN(id) FROM @info_referencias_personales WHERE id <> 0;
	    
			--WHILE(@idReferencia IS NOT NULL)
			--BEGIN
   -- 			UPDATE CLIE_R_I SET id_cliente = @idCliente, id_referencia = tReferencias.id_referencia, parentesco = tReferencias.parentesco, tipo_relacion = tReferencias.tipo_relacion, 
			--	tipo = tReferencias.tipo, eliminado = tReferencias.eliminado, id_empleado = tReferencias.eliminado, modificado_por = @uid, fecha_revision = GETDATE()
			--	FROM @info_referencias_personales tReferencias
			--	WHERE CLIE_R_I.id = @idReferencia AND tReferencias.id = @idReferencia;
	                
			--	SELECT @idReferencia = MIN(id) FROM @info_referencias_personales WHERE id > @idReferencia;
			--END

		    --------------------------------------------------------------------Validacion de Alarmas SPLD--------------------------------------------------------------------------------------
	  
			DECLARE @es_pep BIT,@es_persona_prohibida BIT,@evaluar_pep BIT, @CURP CHAR(18),@advertencia VARCHAR(255)
		
			--Persona Pol�ticamente Expuesta
			SET @id_persona_politicamente_expuesta = 0
			SET @es_pep=CAST(0 AS BIT)
			SET @intDetonoAlarma = 0;

			SELECT @nombre=nombre,@paterno=apellido_paterno,@materno=apellido_materno,@CURP=ISNULL(CurpPersona.curp,'') FROM CONT_Personas 
			OUTER APPLY
			(
				SELECT TOP(1) ISNULL(CONT_IdentificacionOficial.id_numero,'') AS curp FROM CONT_IdentificacionOficial 
				WHERE CONT_IdentificacionOficial.id_persona=CONT_Personas.id
				AND CONT_IdentificacionOficial.tipo_identificacion='CURP'
				AND CONT_IdentificacionOficial.estatus_registro='ACTIVO' 
				ORDER BY CONT_IdentificacionOficial.id DESC
			)CurpPersona
			WHERE id=@idPersona;

			SELECT @evaluar_pep=ISNULL(CAST(valor AS BIT),CAST(0 AS BIT)) FROM SPLD_Configuracion 
			WHERE codigo='ESPEP' AND estatus_registro='ACTIVO'
		
			IF(@evaluar_pep=CAST(1 AS BIT))
			BEGIN
				--obteniendo nombre del cliente--
				SET @nombreSocia = '';
				SET @nombreSocia = @nombre;
				SET @id_persona_politicamente_expuesta=dbo.ufnIsPEP(@idPersona,@nombre+@paterno+@materno,@CURP);
				SET @advertencia='La Persona se encuentra en el cat�logo de Personas Pol�ticamente Expuestas: '+@nombre+' '+@paterno+' '+@materno; 
			    
				IF @id_persona_politicamente_expuesta <> 0
				BEGIN
					SET @tipoListaSocia = '';
					SET @tipoListaSocia = dbo.ufnObtenerTipoListaPersonaPolExp(@idPersona,@nombreSocia+@paterno+@materno);
        			--EXEC [dbo].[SPLD_InsertReporteClientePorTipo] @idPersona,@uid,'PERPPE','Personas Pol�ticamente Expuestas',@nombre,0,'PERFIL','PENDIENTE','08',0,@intIdSolicitudPrestamoMonto;  
        			 PRINT 'Se debe generar un reporte'
        			 SET @es_pep=CAST(1 AS BIT) 
        			 UPDATE CONT_Personas SET es_pep=@es_pep WHERE CONT_Personas.id=@idPersona;
        			
        			 INSERT INTO @TablaRetornoCliente
        			 SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0 ,'CORRECTO','CLIE_insertarInformacionCliente',0,@advertencia
	        	 
        			 SET @intDetonoAlarma = 1;   
				END
				ELSE
				BEGIN
					UPDATE CONT_Personas SET CONT_Personas.es_pep=0 WHERE CONT_Personas.id=@idPersona
				END
				
			END
	    
			--Persona Prohibida 
			SET @id_persona_prohibida=0
			SET @es_persona_prohibida=CAST(0 AS BIT)
	   
	   
			--SELECT @nombre=nombre,@paterno=apellido_paterno,@materno=apellido_materno FROM CONT_Personas WHERE id=@idPersona;
			SET @id_persona_prohibida=dbo.ufnIsPersonaProhibida(@idPersona,@nombre+@paterno+@materno);
			--obteniendo nombre del cliente--
			SET @nombreSocia = '';
			SET @nombreSocia = @nombre;
			SET @tipoListaSocia = '';
			SET @tipoListaSocia = dbo.ufnObtenerTipoListaPersonaProhibida(@idPersona,@nombreSocia+@paterno+@materno);  
			SET @advertencia='La Persona se encuentra en el cat�logo de Personas Bloqueadas: '+@nombre+' '+@paterno+' '+@materno;     
			IF @id_persona_prohibida <> 0
			BEGIN   
	    		
        			---EXEC [dbo].[SPLD_InsertReporteClientePorTipo] @idPersona,@uid,'PERPLT','Personas Ligadas al Terrorismo',@nombre,4,'FINALIZADO','ENVIAR','08',0,@intIdSolicitudPrestamoMonto;      
        			PRINT 'Se debe generar un reporte'
        			SET @es_persona_prohibida=CAST(1 AS BIT) 
        			UPDATE CONT_Personas SET es_persona_prohibida=@es_persona_prohibida WHERE CONT_Personas.id=@idPersona;       		       			
					
					DELETE FROM @DATOSReporteCNBV	
					DELETE FROM @ResultadoOperacion
					SET @Mensaje=''
					SET @Resultado=''
										
					INSERT INTO @DATOSReporteCNBV
					EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA', '','','01/01/1901','01/01/1901','',@idPersona,0,0
				
					IF(SELECT COUNT(*) FROM @DATOSReporteCNBV)>0
					BEGIN
						UPDATE @DATOSReporteCNBV SET id_tipo_reporte=4, descripcion_reporte=@nombre +'.La persona pertenece al tipo Lista denominada:'+ @tipoListaSocia
					
						INSERT INTO @ResultadoOperacion
						EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV,'CLIE_insertarInformacionCliente','INSERT_REPORT_AND_CNBV',@uid
					
						IF(SELECT COUNT(*) FROM @ResultadoOperacion)>0
						BEGIN
						
							SELECT TOP(1) @Resultado=resultado, @Mensaje=mensaje FROM @ResultadoOperacion 
						
							INSERT INTO @TablaRetornoCliente
							SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,@Resultado,'CLIE_insertarInformacionCliente',0,@Mensaje
						END
						ELSE
						BEGIN
							INSERT INTO @TablaRetornoCliente
							SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo generar el reporte de 24 horas'
					
						END
					END
					ELSE
					BEGIN
						INSERT INTO @TablaRetornoCliente
						SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo obtener los datos para generar el reporte de 24 horas'
					END
		
        			INSERT INTO @TablaRetornoCliente
        			SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,'CORRECTO','CLIE_insertarInformacionCliente',0,@nombre
        			SET @intDetonoAlarma = 1;  
			END
			ELSE
			BEGIN
				--SELECT @nombre=nombre,@paterno=apellido_paterno,@materno=apellido_materno FROM CONT_Personas WHERE id=@idPersona;
				SET @id_persona_prohibida=dbo.ufnPersonasProhibidas(@idPersona,@nombre+@paterno+@materno);
				--obteniendo nombre del cliente--
				SET @nombreSocia = '';
				SET @nombreSocia = @nombre;
				SET @advertencia='La Persona se encuentra en el cat�logo de Personas Bloqueadas: '+@nombre+' '+@paterno+' '+@materno;  
				SET @tipoListaSocia = '';  
				set @tipoListaSocia = dbo.ufnObtenerTipoListaPersonasProhibidas(@idPersona,@nombreSocia+@paterno+@materno);
			 
				IF(@id_persona_prohibida<>0)
				BEGIN
					SET @es_persona_prohibida=CAST(1 AS BIT) 
        			UPDATE CONT_Personas SET es_persona_prohibida=@es_persona_prohibida WHERE CONT_Personas.id=@idPersona
        		       		
					DELETE FROM @DATOSReporteCNBV	
					DELETE FROM @ResultadoOperacion
					SET @Mensaje=''
					SET @Resultado=''
										
					INSERT INTO @DATOSReporteCNBV
					EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA', '','','01/01/1901','01/01/1901','',@idPersona,0,0
				
					IF(SELECT COUNT(*) FROM @DATOSReporteCNBV)>0
					BEGIN
					
						UPDATE @DATOSReporteCNBV SET id_tipo_reporte=4, descripcion_reporte=@nombre+'.La persona pertenece al tipo Lista denominada: '+ @tipoListaSocia;
					
						INSERT INTO @ResultadoOperacion
						EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV,'CLIE_insertarInformacionCliente','INSERT_REPORT_AND_CNBV',@uid
					
						IF(SELECT COUNT(*) FROM @ResultadoOperacion)>0
						BEGIN
						
							SELECT TOP(1) @Resultado=resultado, @Mensaje=mensaje FROM @ResultadoOperacion 
						
							INSERT INTO @TablaRetornoCliente
							SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,@Resultado,'CLIE_insertarInformacionCliente',0,@Mensaje
						
						END
						ELSE
						BEGIN
							INSERT INTO @TablaRetornoCliente
							SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo generar el reporte de 24 horas'
					
						END
					
					END
					ELSE
					BEGIN
						INSERT INTO @TablaRetornoCliente
						SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo obtener los datos para generar el reporte de 24 horas'
					END
		
	        	
        			INSERT INTO @TablaRetornoCliente
        			SELECT @idCliente,@idPersona,@idIdentificacionPROSPERA,0,'CORRECTO','CLIE_insertarInformacionCliente',0,@nombre
        			SET @intDetonoAlarma = 1;  
				END 
				ELSE
				BEGIN 
					UPDATE CONT_Personas SET CONT_Personas.es_persona_prohibida=0 WHERE CONT_Personas.id=@idPersona
				END
			END
	    
			--Verificar si el familiar se encuentra en  el cat�logo de Personas Pol�ticamente Expuestas o Personas Prohibidas
			 SELECT @FamiliarDesempeniaFuncionPublica=familiar_desempenia_funcion_publica,@nombre=familiar_desempenia_funcion_publica_nombre,@paterno= familiar_desempenia_funcion_publica_paterno,@materno=familiar_desempenia_funcion_publica_materno FROM @info_datos_pld
			IF @FamiliarDesempeniaFuncionPublica = 1
			BEGIN
				 --Personas Pol�ticamente Expuestas
				SET @id_persona_politicamente_expuesta = 0
				SET @intDetonoAlarma = 0;
	         
				SET @id_persona_politicamente_expuesta=dbo.ufnIsPersonaPolExp(0,@nombre+@paterno+@materno);
				SET @nombre='La Persona tiene a un familiar en el cat�logo de Personas Pol�ticamente Expuestas: '+@nombre+' '+@paterno+' '+@materno;    		
				IF @id_persona_politicamente_expuesta <> 0
				BEGIN                    
					   --- EXEC [dbo].[SPLD_InsertReporteClientePorTipo] @idPersona,@uid,'PERPPE','Personas Pol�ticamente Expuestas',@nombre,0,'PERFIL','PENDIENTE','08',0,@intIdSolicitudPrestamoMonto;                     
					   PRINT 'Se debe generar un reporte'
					   SET @intDetonoAlarma = 1;  
    			END
				--Personas Proh�bidas o l�gadas al terorismo 
				SET @intDetonoAlarma = 0;
				SET @id_persona_prohibida=0 
				SELECT @nombre=familiar_desempenia_funcion_publica_nombre,@paterno= familiar_desempenia_funcion_publica_paterno,@materno=familiar_desempenia_funcion_publica_materno FROM @info_datos_pld 

				SET @id_persona_prohibida=dbo.ufnIsPersonaProhibida(@idPersona,@nombre+@paterno+@materno);
				SET @nombre='La Persona tiene a un familiar en el cat�logo de Personas Proh�bidas: '+@nombre+' '+@paterno+' '+@materno;			
				IF @id_persona_prohibida <> 0
				BEGIN    				
    					---EXEC [dbo].[SPLD_InsertReporteClientePorTipo] @idPersona,@uid,'PERPLT','Personas Ligadas al Terrorismo',@nombre,4,'FINALIZADO','ENVIAR','08',0,@intIdSolicitudPrestamoMonto;      
    					PRINT 'Se debe generar un reporte'
    					SET @intDetonoAlarma = 1;  
				END 
		
			 END

			DECLARE @evaluar_perfil_transaccional BIT=0
			
			---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			INSERT INTO @TablaRetornoCliente
			SELECT @idCliente, @idPersona,@idIdentificacionPROSPERA,0, 'CORRECTO','CLIE_insertarInformacionCliente',0,CASE WHEN LEN(@mensaje_dato_bancario)>0 THEN 'El cliente fue guardado sin los datos bancarios: '+@mensaje_dato_bancario ELSE'El cliente fue guardado exit�samente.' END
		END
	
	END
    ELSE
    BEGIN
		DECLARE @OficinaOrigen VARCHAR(100) = ''
		DECLARE @OficinaNuevo VARCHAR(100) = ''
		DECLARE @MensajeOperacion VARCHAR(MAX) = ''
		DELETE FROM @DATOSReporteCNBV	
		DELETE FROM @ResultadoOperacion
		SET @Mensaje=''
		SET @Resultado=''
		
		SELECT @idPersona = ISNULL(id, 0) FROM @info_persona;
		
		--Obtiene id Cliente
		SELECT @idCliente = ISNULL(id, 0) FROM @info_cliente;
	
		INSERT INTO @DATOSReporteCNBV
		EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA', '','','01/01/1901','01/01/1901','',@idPersona,0,0
		IF(SELECT COUNT(*) FROM @DATOSReporteCNBV)>0
		BEGIN
			UPDATE @DATOSReporteCNBV SET id_tipo_reporte=0, 
			descripcion_reporte= @MensajeOperacion
			INSERT INTO @ResultadoOperacion
			EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV,'CLIE_insertarInformacionCliente','INSERT_REPORT_AND_CNBV',@uid
			
			IF(SELECT COUNT(*) FROM @ResultadoOperacion)>0
			BEGIN
				SELECT TOP(1) @Resultado=resultado, @Mensaje=mensaje FROM @ResultadoOperacion
				INSERT INTO @TablaRetornoCliente
				SELECT @idCliente,@idPersona,0,0,@Resultado,'CLIE_insertarInformacionCliente',0,@Mensaje
			END
			ELSE
			BEGIN
				INSERT INTO @TablaRetornoCliente
				SELECT @idCliente,@idPersona,0,0,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo generar el reporte de perfil transaccional'
			END
		END
		ELSE
		BEGIN
			INSERT INTO @TablaRetornoCliente
			SELECT @idCliente,@idPersona,0,0,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo obtener los datos para generar el reporte de perfil transaccional'
		END
						
		INSERT INTO @TablaRetornoCliente
		SELECT @idCliente,@idPersona,0,0,'CORRECTO','CLIE_insertarInformacionCliente',0,'El perfil transaccional del cliente cambi� por intentar tener un n�mero de operaciones mayor que las permitidas'
		
		INSERT INTO @TablaRetornoCliente
		SELECT @idCliente,@idPersona,0,0,'CORRECTO','CLIE_insertarInformacionCliente',0,'Los datos del cliente no fueron guardados'
    END
    --SELECT @idCliente, @idPersona, @idIdentificacionCURP;
    SELECT id_cliente,id_persona,id_identificacion_curp,id_archivo_subido,mensaje,procedimiento,linea,evento FROM @TablaRetornoCliente
END TRY
BEGIN CATCH
	DELETE FROM @TablaRetornoCliente
	INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
	SELECT
	ERROR_NUMBER() AS Numero_de_Error,
	ERROR_SEVERITY() AS Gravedad_del_Error,
	ERROR_STATE() AS Estado_del_Error,
	ERROR_PROCEDURE() AS Procedimiento_del_Error,
	ERROR_LINE() AS Linea_de_Error,
	ERROR_MESSAGE() AS Mensaje_de_Error,
	'CLIE_insertarInformacionClienteV2';

	INSERT INTO @TablaRetornoCliente
	SELECT 0,0,0,0,'ERROR',ERROR_PROCEDURE(),ERROR_LINE(),ERROR_MESSAGE()
	SELECT id_cliente,id_persona,id_identificacion_curp,id_archivo_subido,mensaje,procedimiento,linea,evento
	FROM @TablaRetornoCliente
END CATCH
GO

--#endregion ------------------------------------- FIN PROCEDURE CREATE CLIENT ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE CREATE LOAN ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_InsertarSolicitudServicioFinanciero
@idUsuario INT,
@idOficina INT,
@idOficialCredito INT,
@idTipoCliente INT,
@idServicioFinanciero INT,
@cantidad INT

AS
BEGIN
  BEGIN TRY
 	BEGIN TRAN T1
 	
	DECLARE @Solicitudes TABLE(
		idCliente INT,
		folio_solicitud VARCHAR(10),
		idSolicitud INT,
		fecha_creacion DATETIME,
		fecha_revision DATETIME
	)
	
	DECLARE @idSolicitud INT;
	DECLARE @idCliente INT;
	DECLARE @idProducto INT;
	DECLARE @cont INT;
	SET @cont = 0;

	WHILE(@cont < @cantidad)
	BEGIN
	
		IF(@idServicioFinanciero = 1)--Creditos
		BEGIN
			IF(@idTipoCliente = 1 OR @idTipoCliente = 2) -- Cr�dito Grupal y Cr�dito Individual
			BEGIN
			
				SET @idSolicitud = 0;
				SET @idProducto = 0;
				SET @idCliente = 0;


				IF(@idTipoCliente=1)
				BEGIN
					--Insertamos el regisros en la tabla de clientes para apartarlo y emitir las referencias.
					INSERT INTO CLIE_Clientes (tipo_cliente,numero_cliente,ciclo,mal_cliente,comentario,estatus,folio_solicitud_credito,id_oficial_credito,
					sub_estatus,creado_por, fecha_registro,estatus_registro,modificado_por,fecha_revision,fecha_inscripcion,id_oficina,autorizacion_reporte, activo)
					VALUES (@idTipoCliente, 0,0,0,'','INACTIVO','',@idOficialCredito,'',@idUsuario,GETDATE(),'ACTIVO',@idUsuario, GETDATE(),GETDATE(),@idOficina,0,0); 
					SELECT @idCliente=scope_identity(); 
				END
				--Insertamos el registro en la tabla de solicitudes.
				INSERT INTO OTOR_SolicitudPrestamos (id_cliente,id_oficial,estatus,creado_por,periodos,tasa_anual,tipo_cliente,id_oficina, id_servicio_financiero, sub_estatus, tipo_credito, ciclo)
				VALUES (@idCliente,@idOficialCredito,'PREIMPRESO',@idUsuario,0,0,@idTipoCliente,@idOficina, @idServicioFinanciero,'SOLICITUD',1,0);
				SELECT @idSolicitud = scope_identity(); 
				
				----Insertamos el registro en la tabla de ciclos.
				--INSERT INTO CLIE_EventosCiclos(id_cliente,id_contrato,id_servicio_financiero,ciclo,fecha_registro,revertido, id_tipo_cliente)
				--VALUES (@idCliente, 0, @idServicioFinanciero,0, GETDATE(),0,@idTipoCliente);
				
				INSERT INTO @Solicitudes 
				SELECT OTOR_SolicitudPrestamos.id_cliente, CAST(OTOR_SolicitudPrestamos.id AS VARCHAR),OTOR_SolicitudPrestamos.id, 
				OTOR_SolicitudPrestamos.fecha_creacion, OTOR_SolicitudPrestamos.fecha_creacion 
				FROM OTOR_SolicitudPrestamos
				WHERE OTOR_SolicitudPrestamos.id = @idSolicitud
	
			END
		END
		SET @cont = @cont + 1;
	END
		
	SELECT * FROM @Solicitudes;
	
	COMMIT TRAN T1;
  END TRY
  BEGIN CATCH
  	ROLLBACK TRAN T1;
    
    	INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
        SELECT
    	ERROR_NUMBER() AS Numero_de_Error,
    	ERROR_SEVERITY() AS Gravedad_del_Error,
    	ERROR_STATE() AS Estado_del_Error,
    	ERROR_PROCEDURE() AS Procedimiento_del_Error,
    	ERROR_LINE() AS Linea_de_Error,
    	ERROR_MESSAGE() AS Mensaje_de_Error,
        'OTOR_InsertSolicitudServicioFinanciero' AS Procedimiento_Origen;
  END CATCH
END
GO

--#endregion ------------------------------------- FIN PROCEDURE CREATE LOAN ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE ASIGNAMENT CLIENT A LOAN ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_AsignacionCreditoCliente
	-- Add the parameters for the stored procedure here
	@id_solicitud_prestamo INT, 
	@id_cliente INT,
	@etiqueta_opcion VARCHAR(50),
	@tipo_baja VARCHAR(50) = '',
	@id_motivo INT = 0,
    @uid INT
	
AS
BEGIN

DECLARE @TablaRetorno AS TABLE
    (
		id_prestamo_monto INT,
		id_cliente INT,
		id_persona INT,
		mensaje VARCHAR(10),
		procedimiento VARCHAR(50),
		linea INT,
		evento VARCHAR(MAX)
    )

IF(@etiqueta_opcion = 'ALTA')
BEGIN
	DECLARE @intIdSolicitudPrestamoMonto INT;
	DECLARE @ciclo INT;
	DECLARE @perfil_riesgo VARCHAR(20);
	DECLARE @id_oficina_cliente INT;
	DECLARE @id_oficina_credito INT;
	DECLARE @id_tipo_cliente INT;
	DECLARE @id_tipo_credito INT;
	DECLARE @id_persona INT=0;
	DECLARE @id_cliente_solicitud_prestamo INT;

	DECLARE @TablaSeguro AS TABLE
	(
		id_detalle_seguro INT,
		id_solicitud_prestamo INT,
		id_individual INT,
		id_seguro INT,
		id_seguro_asignacion INT,
		nombre_socia VARCHAR(300),
		nombre_beneficiario VARCHAR(300),
		parentesco VARCHAR(100),
		porcentaje MONEY,
		costo_seguro MONEY,
		incluye_saldo_deudor BIT,
		activo BIT
	)
	DECLARE @TablaPrestamoMonto AS TABLE
	(
		id_individual INT,
		id_persona INT,
		nombre VARCHAR(100),
		apellido_paterno VARCHAR(100),
		apellido_materno VARCHAR(100),
		estatus VARCHAR(100),
		sub_estatus VARCHAR(100),
		cargo VARCHAR(100),
		monto_solicitado MONEY,
		monto_sugerido MONEY,
		monto_autorizado MONEY,
		econ_id_actividad_economica INT,
	    id_archivo_curp INT,
		id_solicitud_prestamo INT,
		ciclo INT,
		monto_anterior MONEY,
		id_riesgo_pld INT,
		etiqueta_riesgo_Pld VARCHAR(100),
		id_cata_medio_desembolso INT
		
	)

	BEGIN TRY

		SET @perfil_riesgo='BAJO RIESGO';

		SELECT 
		@id_oficina_credito=ISNULL(id_oficina,0), 
		@id_tipo_credito=ISNULL(tipo_cliente,0)
		,@id_cliente_solicitud_prestamo=ISNULL(id_cliente,0)
		FROM OTOR_SolicitudPrestamos 
		WHERE id=@id_solicitud_prestamo AND estatus<>'CANCELADO' AND estatus<>'CASTIGADO' AND estatus<>'RECHAZADO';
		SELECT @id_oficina_cliente=ISNULL(id_oficina,0), @id_tipo_cliente=ISNULL(tipo_cliente,0) FROM CLIE_Clientes WHERE id=@id_cliente;

		IF(SELECT CATA_TipoCliente.nombre FROM CATA_TipoCliente WHERE id=@id_tipo_cliente)='INDIVIDUAL'
		BEGIN
			
			/*IF((@id_tipo_credito=2 AND (EXISTS (SELECT * FROM OTOR_SolicitudPrestamos WHERE id=@id_solicitud_prestamo AND id_cliente=@id_cliente) OR @id_cliente_solicitud_prestamo=0)) OR @id_tipo_credito=1)
			BEGIN*/

				IF(@id_oficina_credito=@id_oficina_cliente AND  (@id_oficina_credito>0 OR @id_oficina_cliente>0))
				BEGIN
	
					BEGIN TRANSACTION TranAsignarCreditoCliente

						--Insertar nueva solicitud
						IF(@id_tipo_credito=1 AND NOT EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente ))
						BEGIN 

							SELECT @ciclo =ISNULL(dbo.getMaxCicloIndividual(@id_cliente,@id_tipo_credito),0);
	             
							INSERT INTO OTOR_SolicitudPrestamoMonto(id_solicitud_prestamo, id_individual, estatus, sub_estatus, monto_solicitado,
								monto_autorizado, autorizado, econ_id_actividad_economica, monto_sugerido, motivo, cargo,creado_por, fecha_registro,
								modificado_por, fecha_revision, ciclo,perfil_riesgo)
							VALUES(@id_solicitud_prestamo, @id_cliente, 'TRAMITE', 'NUEVO TRAMITE', 0, 0, 0, 0, 0, 0,'', @uid, GETDATE(), @uid, GETDATE(), @ciclo,@perfil_riesgo)
							--VALUES(@id_solicitud_prestamo, @id_cliente, 'TRAMITE', 'POR AUTORIZAR', 0, 0, 0, 0, 0, 0,'', @uid, GETDATE(), @uid, GETDATE(), @ciclo,@perfil_riesgo)
							-- VALUES(@id_solicitud_prestamo, @id_cliente, 'TRAMITE', 'LISTO PARA TRAMITE', 0, 0, 0, 0, 0, 0,'', @uid, GETDATE(), @uid, GETDATE(), @ciclo,@perfil_riesgo)
	                    
							SELECT @intIdSolicitudPrestamoMonto = SCOPE_IDENTITY();
	
						END

						ELSE IF (@id_tipo_credito=2 AND  NOT EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo))
						BEGIN
							
							
							IF(@id_cliente_solicitud_prestamo=0)
							BEGIN
								
								UPDATE OTOR_SolicitudPrestamos SET id_cliente=@id_cliente WHERE id=@id_solicitud_prestamo;
							END

							SELECT @ciclo =ISNULL(dbo.getMaxCicloIndividual(@id_cliente,@id_tipo_credito),0);
	             
							INSERT INTO OTOR_SolicitudPrestamoMonto(id_solicitud_prestamo, id_individual, estatus, sub_estatus, monto_solicitado,
								monto_autorizado, autorizado, econ_id_actividad_economica, monto_sugerido, motivo, cargo,creado_por, fecha_registro,
								modificado_por, fecha_revision, ciclo,perfil_riesgo)
							VALUES(@id_solicitud_prestamo, @id_cliente, 'TRAMITE', 'NUEVO TRAMITE', 0, 0, 0, 0, 0, 0,'', @uid, GETDATE(), @uid, GETDATE(), @ciclo,@perfil_riesgo)
							--VALUES(@id_solicitud_prestamo, @id_cliente, 'TRAMITE', 'POR AUTORIZAR', 0, 0, 0, 0, 0, 0,'', @uid, GETDATE(), @uid, GETDATE(), @ciclo,@perfil_riesgo)
							-- VALUES(@id_solicitud_prestamo, @id_cliente, 'TRAMITE', 'LISTO PARA TRAMITE', 0, 0, 0, 0, 0, 0,'', @uid, GETDATE(), @uid, GETDATE(), @ciclo,@perfil_riesgo)
	                    
							SELECT @intIdSolicitudPrestamoMonto = SCOPE_IDENTITY();
							
						END

						ELSE IF (@id_tipo_credito=2 AND EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo))
						BEGIN
							
							 IF(EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente))
							 BEGIN

								IF NOT EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo 
									AND id_individual = @id_cliente AND ( (estatus='TRAMITE' AND sub_estatus='INVESTIGACION CREDITICIA')
																			OR (estatus='TRAMITE' AND sub_estatus='LISTO PARA TRAMITE') 
																			OR (estatus='TRAMITE' AND sub_estatus='POR AUTORIZAR') 
																			OR (estatus='ACEPTADO' AND sub_estatus='AUTORIZADO') 
																			OR (estatus='ACEPTADO' AND sub_estatus='PRESTAMO ACTIVO')
																			OR (estatus='ACEPTADO' AND sub_estatus='PRESTAMO FINALIZADO') 
																			OR (estatus='CASTIGADO' AND sub_estatus='CASTIGADO')
																			OR (autorizado=1)
																		))
																
								BEGIN
									
									--UPDATE OTOR_SolicitudPrestamoMonto SET estatus = 'TRAMITE', sub_estatus = 'NUEVO TRAMITE',motivo=0, modificado_por = @uid, fecha_revision = GETDATE()
									--UPDATE OTOR_SolicitudPrestamoMonto SET estatus = 'TRAMITE', sub_estatus = 'POR AUTORIZAR',motivo=0, modificado_por = @uid, fecha_revision = GETDATE()
									UPDATE OTOR_SolicitudPrestamoMonto SET estatus = 'TRAMITE', sub_estatus = 'LISTO PARA TRAMITE',motivo=0, modificado_por = @uid, fecha_revision = GETDATE()
									WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente;							
									
									/**/
									INSERT INTO @TablaRetorno
									SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,'El cliente ya esta asignado al folio de cr�dito';

									SET @intIdSolicitudPrestamoMonto=0;

								END
								ELSE
								BEGIN
									SELECT @id_persona=ISNULL(id_persona,0) FROM CLIE_Individual WHERE id_cliente=@id_cliente;
									SELECT @intIdSolicitudPrestamoMonto = ISNULL(id,0)  FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente;

									INSERT INTO @TablaRetorno
									SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El cliente ya tiene asignado el folio de cr�dito y se encuentra en un estatus que no se puede modificar';

									SET @intIdSolicitudPrestamoMonto=0;
								END
																								
							 END
							 ELSE
							 BEGIN
								
								IF NOT EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo 
									 AND ( (estatus='TRAMITE' AND sub_estatus='INVESTIGACION CREDITICIA')
																			OR (estatus='TRAMITE' AND sub_estatus='LISTO PARA TRAMITE') 
																			OR (estatus='TRAMITE' AND sub_estatus='POR AUTORIZAR') 
																			OR (estatus='ACEPTADO' AND sub_estatus='AUTORIZADO') 
																			OR (estatus='ACEPTADO' AND sub_estatus='PRESTAMO ACTIVO')
																			OR (estatus='ACEPTADO' AND sub_estatus='PRESTAMO FINALIZADO') 
																			OR (estatus='CASTIGADO' AND sub_estatus='CASTIGADO')
																			OR (autorizado=1)
																		))
																
								BEGIN
									DECLARE @id_cliente_actual INT;

									SELECT TOP(1) @id_cliente_actual=ISNULL(id_individual,0) FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo;
									
									UPDATE OTOR_SolicitudPrestamos SET id_cliente=@id_cliente WHERE id=@id_solicitud_prestamo;

									SELECT @ciclo =ISNULL(dbo.getMaxCicloIndividual(@id_cliente,@id_tipo_credito),0);

									--UPDATE OTOR_SolicitudPrestamoMonto SET ciclo=@ciclo, id_individual=@id_cliente, estatus = 'TRAMITE', sub_estatus = 'NUEVO TRAMITE', modificado_por = @uid, fecha_revision = GETDATE()
									-- UPDATE OTOR_SolicitudPrestamoMonto SET ciclo=@ciclo, id_individual=@id_cliente, estatus = 'TRAMITE', sub_estatus = 'POR AUTORIZAR', modificado_por = @uid, fecha_revision = GETDATE()
									UPDATE OTOR_SolicitudPrestamoMonto SET ciclo=@ciclo, id_individual=@id_cliente, estatus = 'TRAMITE', sub_estatus = 'LISTO PARA TRAMITE', modificado_por = @uid, fecha_revision = GETDATE()
									WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente_actual;

									SELECT @intIdSolicitudPrestamoMonto = ISNULL(id,0)  FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente;
								END
								ELSE
								BEGIN
									SELECT @id_persona=ISNULL(id_persona,0) FROM CLIE_Individual WHERE id_cliente=@id_cliente;
									SELECT TOP(1) @id_cliente_actual=ISNULL(id_individual,0) FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo;									
									SELECT @intIdSolicitudPrestamoMonto = ISNULL(id,0)  FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente_actual;

									INSERT INTO @TablaRetorno
									SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El folio de cr�dito ya se encuentra asignado a otro cliente y se encuentra en un estatus que no se puede modificar';
									SET @intIdSolicitudPrestamoMonto=0;
								END
								
							 END
							
						END

						ELSE
						BEGIN	
													
							IF NOT EXISTS (SELECT * FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo 
								AND id_individual = @id_cliente AND ( (estatus='TRAMITE' AND sub_estatus='INVESTIGACION CREDITICIA')
																		OR (estatus='TRAMITE' AND sub_estatus='LISTO PARA TRAMITE') 
																		OR (estatus='TRAMITE' AND sub_estatus='POR AUTORIZAR') 
																		OR (estatus='ACEPTADO' AND sub_estatus='AUTORIZADO') 
																		OR (estatus='ACEPTADO' AND sub_estatus='PRESTAMO ACTIVO')
																		OR (estatus='ACEPTADO' AND sub_estatus='PRESTAMO FINALIZADO') 
																		OR (estatus='CASTIGADO' AND sub_estatus='CASTIGADO')
																		OR (autorizado=1)
																	))
																
							BEGIN
								
								--UPDATE OTOR_SolicitudPrestamoMonto SET estatus = 'TRAMITE', sub_estatus = 'NUEVO TRAMITE', modificado_por = @uid,motivo=0, fecha_revision = GETDATE()
								-- UPDATE OTOR_SolicitudPrestamoMonto SET estatus = 'TRAMITE', sub_estatus = 'POR AUTORIZAR', modificado_por = @uid,motivo=0, fecha_revision = GETDATE()
								UPDATE OTOR_SolicitudPrestamoMonto SET estatus = 'TRAMITE', sub_estatus = 'LISTO PARA TRAMITE', modificado_por = @uid,motivo=0, fecha_revision = GETDATE()
								WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente;
								/**/
								INSERT INTO @TablaRetorno
								SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,'El cliente se ha reasignado al folio en estatus TRAMITE / NUEVO LISTO PARA TRAMITE';

								SET @intIdSolicitudPrestamoMonto=0;
								
							END
							ELSE
							BEGIN
								SELECT @id_persona=ISNULL(id_persona,0) FROM CLIE_Individual WHERE id_cliente=@id_cliente;					
									
								SELECT @intIdSolicitudPrestamoMonto = ISNULL(id,0)  FROM OTOR_SolicitudPrestamoMonto WHERE id_solicitud_prestamo = @id_solicitud_prestamo AND id_individual = @id_cliente;

								INSERT INTO @TablaRetorno
								SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El folio de cr�dito ya se encuentra asignado al cliente y se encuentra en un estatus que no se puede modificar';
								SET @intIdSolicitudPrestamoMonto=0;
							END
							
						END

						/*IF @intIdSolicitudPrestamoMonto IS NULL OR @intIdSolicitudPrestamoMonto=0
						BEGIN
							SELECT @intIdSolicitudPrestamoMonto=MAX(id) FROM OTOR_SolicitudPrestamoMonto WHERE id_individual=@id_cliente;
						END*/

						/*PLD*/
						IF(@intIdSolicitudPrestamoMonto IS NOT NULL AND @intIdSolicitudPrestamoMonto>0)
						BEGIN
							 --------------------------------------------------------------------Validacion de Alarmas SPLD--------------------------------------------------------------------------------------
							 DECLARE @es_pep BIT,@es_persona_prohibida BIT,@evaluar_pep BIT, @CURP CHAR(18),@advertencia VARCHAR(255)						 
							 DECLARE 
								@id_persona_politicamente_expuesta INT,
								@id_persona_prohibida INT,
								@nombre VARCHAR(255), 
								@paterno VARCHAR(255),      
								@materno VARCHAR(255),
								@intDetonoAlarma INT,
								@FamiliarDesempeniaFuncionPublica BIT;

							DECLARE 
							@desempenia_funcion_publicaULTIMO BIT = 0, 
							@desempenia_funcion_publicaACTUAL BIT = 0, 
							@familiar_desempenia_funcion_publicaULTIMO BIT = 0,
							@familiar_desempenia_funcion_publicaACTUAL BIT = 0,
							@id_naturaleza_pagoULTIMO INT = 0, @etiqueta_naturaleza_pagoULTIMO VARCHAR(350) = '',
							@id_naturaleza_pagoACTUAL INT = 0, @etiqueta_naturaleza_pagoACTUAL VARCHAR(350) = '',
							@id_profesionULTIMO INT = 0, 
							@id_profesionACTUAL INT = 0, 
							@id_ocupacionULTIMO INT = 0, 
							@id_ocupacionACTUAL INT = 0, 
							@id_asentamientoULTIMO INT=0,
							@id_ciudadULTIMO INT=0,
							@id_municipioULTIMO INT = 0, 
							@id_estadoULTIMO INT=0,
							@id_paisULTIMO INT=0,
							@direccionULTIMO VARCHAR(800)='',
							@id_asentamientoACTUAL INT = 0, 
							@id_ciudadACTUAL INT = 0, 
							@id_municipioACTUAL INT = 0, 
							@id_estadoACTUAL INT = 0, 
							@id_paisACTUAL INT = 0, 
							@direccionACTUAL VARCHAR(800)='',
							@id_destino_creditoULTIMO INT = 0, @etiqueta_destino_creditoULTIMO VARCHAR(350) = '',
							@id_destino_creditoACTUAL INT = 0, @etiqueta_destino_creditoACTUAL VARCHAR(350) = '',
							@id_actividad_economicaULTIMO INT = 0, @etiqueta_actividad_economicaULTIMO VARCHAR(350) = '',
							@id_actividad_economicaACTUAL INT = 0, @etiqueta_actividad_economicaACTUAL VARCHAR(350) = '',
							@id_pais_nacimientoULTIMO INT = 0, 
							@id_pais_nacimientoACTUAL INT = 0, 
							@id_nacionalidadULTIMO INT = 0, 
							@id_nacionalidadACTUAL INT = 0, 
							@es_pepULTIMO INT = 0, 
							@es_pepACTUAL INT = 0,
							@es_persona_prohibidaULTIMO INT = 0,
							@es_persona_prohibidaACTUAL INT = 0,

							--nuevas variables para lista--
							@nombreSocia VARCHAR(255) = '',
							@tipoListaSocia VARCHAR(100) = ''

							DECLARE @INFOCambiosDetectados VARCHAR(MAX) = '', @HASChange INT = 0, @DETONAAlarma INT = 0, @LASTPerfil VARCHAR(100) = '';
							DECLARE @DATOSReporteCNBV UDT_SPLD_ReporteCNBV;
							DECLARE @ResultadoOperacion TABLE
							(
								id_registro INT,
								tipo VARCHAR(50),
								resultado VARCHAR(50),
								mensaje VARCHAR(800),
								string_auxiliar VARCHAR(250),
								int_auxiliar INT
							)
							DECLARE @Resultado VARCHAR(50)
							DECLARE @Mensaje VARCHAR(800)

							--Persona Pol�ticamente Expuesta
							SET @id_persona_politicamente_expuesta = 0
							SET @es_pep=CAST(0 AS BIT);
							SET @intDetonoAlarma = 0;

							SELECT @id_persona=ISNULL(id_persona,0) FROM CLIE_Individual WHERE id_cliente=@id_cliente;

							SELECT @nombre=nombre,@paterno=apellido_paterno,@materno=apellido_materno,@CURP=ISNULL(CurpPersona.curp,'') FROM CONT_Personas 
									OUTER APPLY
									(
										SELECT TOP(1) ISNULL(CONT_IdentificacionOficial.id_numero,'') AS curp FROM CONT_IdentificacionOficial 
										WHERE CONT_IdentificacionOficial.id_persona=CONT_Personas.id
										AND CONT_IdentificacionOficial.tipo_identificacion='CURP'
										AND CONT_IdentificacionOficial.estatus_registro='ACTIVO' 
										ORDER BY CONT_IdentificacionOficial.id DESC
									)CurpPersona
									WHERE id=@id_persona;

							SELECT @evaluar_pep=ISNULL(CAST(valor AS BIT),CAST(0 AS BIT)) FROM SPLD_Configuracion 
							WHERE codigo='ESPEP' AND estatus_registro='ACTIVO';

							IF(@evaluar_pep=CAST(1 AS BIT))
							BEGIN
								--obteniendo nombre del cliente--
								SET @nombreSocia = '';
								SET @nombreSocia = @nombre;
								SET @id_persona_politicamente_expuesta=dbo.ufnIsPEP(@id_Persona,@nombre+@paterno+@materno,@CURP);
								SET @advertencia='La Persona se encuentra en el cat�logo de Personas Pol�ticamente Expuestas: '+@nombre+' '+@paterno+' '+@materno; 
			    
								IF @id_persona_politicamente_expuesta <> 0
								BEGIN
									SET @tipoListaSocia = '';
									SET @tipoListaSocia = dbo.ufnObtenerTipoListaPersonaPolExp(@id_Persona,@nombreSocia+@paterno+@materno);
        								PRINT 'Se debe generar un reporte'
        								SET @es_pep=CAST(1 AS BIT) 
        								UPDATE CONT_Personas SET es_pep=@es_pep WHERE CONT_Personas.id=@id_Persona
        	
        								SELECT @LASTPerfil = ''
        								SELECT @LASTPerfil = LTRIM(RTRIM(perfil_riesgo)) FROM OTOR_SolicitudPrestamoMonto WHERE id = @intIdSolicitudPrestamoMonto
        		 
        								UPDATE OTOR_SolicitudPrestamoMonto SET perfil_riesgo='ALTO RIESGO' WHERE id=@intIdSolicitudPrestamoMonto;
        		 
	        							INSERT INTO SPLD_HistorialSociaPerfilRiesgo(id_solicitud_prestamo_monto,nombre,apellido_paterno,apellido_materno,perfil_anterior,perfil_actual,comentario,forma,creado_por,fecha_creacion,estatus_registro)
	        							SELECT @intIdSolicitudPrestamoMonto,@nombreSocia,@paterno,@materno,@LASTPerfil,'ALTO RIESGO','La Persona se encuentra en el cat�logo de Personas Pol�ticamente Expuestas,pertenece al tipo Lista denominada: '+@tipoListaSocia,'AUTOMATICA',@uid,GETDATE(),'ACTIVO'
	        
        								INSERT INTO @TablaRetorno
        								SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,@advertencia
	        	 
        								SET @intDetonoAlarma = 1;   
								END
								ELSE
								BEGIN
									UPDATE CONT_Personas SET CONT_Personas.es_pep=0 WHERE CONT_Personas.id=@id_persona
								END
				
							END

							--Persona Prohibida 
							SET @id_persona_prohibida=0
							SET @es_persona_prohibida=CAST(0 AS BIT)
	   	   
							SET @id_persona_prohibida=dbo.ufnIsPersonaProhibida(@id_persona,@nombre+@paterno+@materno);
							--obteniendo nombre del cliente--
							SET @nombreSocia = '';
							SET @nombreSocia = @nombre;
							SET @tipoListaSocia = '';
							SET @tipoListaSocia = dbo.ufnObtenerTipoListaPersonaProhibida(@id_persona,@nombreSocia+@paterno+@materno);  
							SET @advertencia='La Persona se encuentra en el cat�logo de Personas Bloqueadas: '+@nombre+' '+@paterno+' '+@materno;     
							IF @id_persona_prohibida <> 0
							BEGIN   
	   
        							PRINT 'Se debe generar un reporte'
        							SET @es_persona_prohibida=CAST(1 AS BIT) 
        							UPDATE CONT_Personas SET es_persona_prohibida=@es_persona_prohibida WHERE CONT_Personas.id=@id_persona
        		
        							IF NOT EXISTS (
        								SELECT OTOR_Contratos.*
        								FROM OTOR_SolicitudPrestamos
        								INNER JOIN OTOR_SolicitudPrestamoMonto  ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id AND OTOR_SolicitudPrestamoMonto.id=@intIdSolicitudPrestamoMonto
        								INNER JOIN OTOR_Contratos ON OTOR_SolicitudPrestamos.id=OTOR_Contratos.id_solicitud_prestamo 
        								)   
        							BEGIN
        								SELECT @LASTPerfil = ''
        								SELECT @LASTPerfil = LTRIM(RTRIM(perfil_riesgo)) FROM OTOR_SolicitudPrestamoMonto WHERE id=@intIdSolicitudPrestamoMonto
        			
        								UPDATE OTOR_SolicitudPrestamoMonto SET estatus='RECHAZADO',sub_estatus='RECHAZADO',perfil_riesgo='ALTO RIESGO' WHERE id=@intIdSolicitudPrestamoMonto
        			
        								INSERT INTO SPLD_HistorialSociaPerfilRiesgo(id_solicitud_prestamo_monto,nombre,apellido_paterno,apellido_materno,perfil_anterior,perfil_actual,comentario,forma,creado_por,fecha_creacion,estatus_registro)
	        							SELECT @intIdSolicitudPrestamoMonto,@nombreSocia,@paterno,@materno,@LASTPerfil,'ALTO RIESGO',@advertencia+'.La persona pertenece al tipo Lista denominada: '+@tipoListaSocia,'AUTOMATICA',@uid,GETDATE(),'ACTIVO'
        							END
        		
        							ELSE
        							BEGIN
										INSERT INTO @TablaRetorno
        								SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,'No se rechaz� solicitud, el cliente tiene contrato'
        							END
					
									DELETE FROM @DATOSReporteCNBV	
									DELETE FROM @ResultadoOperacion
									SET @Mensaje=''
									SET @Resultado=''
										
									INSERT INTO @DATOSReporteCNBV
									EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA', '','','01/01/1901','01/01/1901','',@id_persona,0,0
				
									IF(SELECT COUNT(*) FROM @DATOSReporteCNBV)>0
									BEGIN
										UPDATE @DATOSReporteCNBV SET id_tipo_reporte=4, descripcion_reporte=@nombre +'.La persona pertenece al tipo Lista denominada:'+ @tipoListaSocia
					
										INSERT INTO @ResultadoOperacion
										EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV,'CLIE_AsignacionCreditoCliente','INSERT_REPORT_AND_CNBV',@uid
					
										IF(SELECT COUNT(*) FROM @ResultadoOperacion)>0
										BEGIN
						
											SELECT TOP(1) @Resultado=resultado, @Mensaje=mensaje FROM @ResultadoOperacion 
						
											INSERT INTO @TablaRetorno
											SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,@Resultado,'CLIE_AsignacionCreditoCliente',0,@Mensaje
										END
										ELSE
										BEGIN
											INSERT INTO @TablaRetorno
											SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'No se pudo generar el reporte de 24 horas'
					
										END
									END
									ELSE
									BEGIN
										INSERT INTO @TablaRetorno
										SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'No se pudo obtener los datos para generar el reporte de 24 horas'
									END
		
        							INSERT INTO @TablaRetorno
        							SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,@nombre
        							SET @intDetonoAlarma = 1;  
							END
							ELSE
							BEGIN
								--SELECT @nombre=nombre,@paterno=apellido_paterno,@materno=apellido_materno FROM CONT_Personas WHERE id=@id_persona;
								SET @id_persona_prohibida=dbo.ufnPersonasProhibidas(@id_persona,@nombre+@paterno+@materno);
								--obteniendo nombre del cliente--
								SET @nombreSocia = '';
								SET @nombreSocia = @nombre;
								SET @advertencia='La Persona se encuentra en el cat�logo de Personas Bloqueadas: '+@nombre+' '+@paterno+' '+@materno;  
								SET @tipoListaSocia = '';  
								set @tipoListaSocia = dbo.ufnObtenerTipoListaPersonasProhibidas(@id_persona,@nombreSocia+@paterno+@materno);
			 
								IF(@id_persona_prohibida<>0)
								BEGIN
									SET @es_persona_prohibida=CAST(1 AS BIT) 
        							UPDATE CONT_Personas SET es_persona_prohibida=@es_persona_prohibida WHERE CONT_Personas.id=@id_persona
        		
        							IF NOT EXISTS 
        							(
        								SELECT OTOR_Contratos.*
        								FROM OTOR_SolicitudPrestamos
        								INNER JOIN OTOR_SolicitudPrestamoMonto  ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id AND OTOR_SolicitudPrestamoMonto.id=@intIdSolicitudPrestamoMonto
        								INNER JOIN OTOR_Contratos ON OTOR_SolicitudPrestamos.id=OTOR_Contratos.id_solicitud_prestamo 
        							)   
        							BEGIN
        								SELECT @LASTPerfil = ''
        								SELECT @LASTPerfil = LTRIM(RTRIM(perfil_riesgo)) FROM OTOR_SolicitudPrestamoMonto WHERE id = @intIdSolicitudPrestamoMonto
        			
        								UPDATE OTOR_SolicitudPrestamoMonto SET estatus='RECHAZADO',sub_estatus='RECHAZADO',perfil_riesgo='ALTO RIESGO' WHERE id=@intIdSolicitudPrestamoMonto
        			
        								INSERT INTO SPLD_HistorialSociaPerfilRiesgo(id_solicitud_prestamo_monto,nombre,apellido_paterno,apellido_materno,perfil_anterior,perfil_actual,comentario,forma,creado_por,fecha_creacion,estatus_registro)
	        							SELECT @intIdSolicitudPrestamoMonto,@nombreSocia,@paterno,@materno,@LASTPerfil,'ALTO RIESGO',@advertencia+'.La persona pertenece al tipo Lista denominada: '+@tipoListaSocia,'AUTOMATICA',@uid,GETDATE(),'ACTIVO'
        							END
        		
        							ELSE
        							BEGIN
										INSERT INTO @TablaRetorno
        								SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,'No se rechaz� solicitud, el cliente tiene contrato'
        							END
        		
									DELETE FROM @DATOSReporteCNBV	
									DELETE FROM @ResultadoOperacion
									SET @Mensaje=''
									SET @Resultado=''
										
									INSERT INTO @DATOSReporteCNBV
									EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA', '','','01/01/1901','01/01/1901','',@id_persona,0,0
				
									IF(SELECT COUNT(*) FROM @DATOSReporteCNBV)>0
									BEGIN
					
										UPDATE @DATOSReporteCNBV SET id_tipo_reporte=4, descripcion_reporte=@nombre+'.La persona pertenece al tipo Lista denominada: '+ @tipoListaSocia;
					
										INSERT INTO @ResultadoOperacion
										EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV,'CLIE_AsignacionCreditoCliente','INSERT_REPORT_AND_CNBV',@uid
					
										IF(SELECT COUNT(*) FROM @ResultadoOperacion)>0
										BEGIN
						
											SELECT TOP(1) @Resultado=resultado, @Mensaje=mensaje FROM @ResultadoOperacion 
						
											INSERT INTO @TablaRetorno
											SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,@Resultado,'CLIE_AsignacionCreditoCliente',0,@Mensaje
						
										END
										ELSE
										BEGIN
											INSERT INTO @TablaRetorno
											SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'No se pudo generar el reporte de 24 horas'
					
										END
					
									END
									ELSE
									BEGIN
										INSERT INTO @TablaRetorno
										SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'No se pudo obtener los datos para generar el reporte de 24 horas'
									END
		
	        	
        							INSERT INTO @TablaRetorno
        							SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,@nombre
        							SET @intDetonoAlarma = 1;  
								END 
								ELSE
								BEGIN 
									UPDATE CONT_Personas SET CONT_Personas.es_persona_prohibida=0 WHERE CONT_Personas.id=@id_persona
								END
							END
	
							DECLARE @evaluar_perfil_transaccional BIT=0

							IF(
								SELECT COUNT(*) FROM OTOR_SolicitudPrestamoMonto 
								WHERE id=@intIdSolicitudPrestamoMonto
								AND OTOR_SolicitudPrestamoMonto.id_individual=@id_cliente
								AND OTOR_SolicitudPrestamoMonto.estatus='ACEPTADO'
								AND OTOR_SolicitudPrestamoMonto.sub_estatus='PRESTAMO ACTIVO'
								AND OTOR_SolicitudPrestamoMonto.autorizado=1
							)>0
							BEGIN
								SET @evaluar_perfil_transaccional=1
							END

							IF(@evaluar_perfil_transaccional=1)
							BEGIN

								IF NOT EXISTS 
								(
									SELECT * FROM SPLD_DatosCliente 
									WHERE SPLD_DatosCliente.id_persona = @id_persona 
									AND SPLD_DatosCliente.id_cliente = @id_cliente 
									AND SPLD_DatosCliente.id_prestamo_monto = @intIdSolicitudPrestamoMonto
									AND estatus_registro='ACTIVO'
								)
								BEGIN
					
									INSERT INTO SPLD_DatosCliente(id_prestamo_monto,id_persona,id_cliente,id_tipo_operacion,numero_creditos,monto_pago,id_naturaleza_pago,
									id_pais_nacimiento,id_nacionalidad,id_municipio_actual,id_actividad_economica,id_ocupacion,id_profesion,id_destino_credito,es_pep,es_persona_prohibida,
									desempenia_funcion_publica,desempenia_funcion_publica_cargo,desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica,familiar_desempenia_funcion_publica_cargo,
									familiar_desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica_nombre,familiar_desempenia_funcion_publica_paterno,familiar_desempenia_funcion_publica_materno,
									familiar_desempenia_funcion_publica_parentesco,creado_por,fecha_registro,modificado_por,fecha_revision,estatus_registro,id_asentamiento_actual,id_ciudad_actual,id_estado_actual,id_pais_actual,direccion)

									SELECT 
									@intIdSolicitudPrestamoMonto,@id_persona,@id_cliente,1,1,0.0, tIndividual.id_instrumento_monetario,
									tPersonaDireccion.id_pais_nacimiento,tPersonaDireccion.id_nacionalidad,tPersonaDireccion.id_municipio,tIndividual.id_actividad_economica,tIndividual.id_ocupacion,tIndividual.id_profesion,tIndividual.econ_id_destino_credito,
									CASE @evaluar_pep WHEN 0 THEN tPersonaDireccion.es_pep ELSE @es_pep END,@es_persona_prohibida,
									tIndividual.desempenia_funcion_publica,tIndividual.desempenia_funcion_publica_cargo,tIndividual.desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica,tIndividual.familiar_desempenia_funcion_publica_cargo,
									tIndividual.familiar_desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica_nombre,tIndividual.familiar_desempenia_funcion_publica_paterno,tIndividual.familiar_desempenia_funcion_publica_materno,
									tIndividual.familiar_desempenia_funcion_publica_parentesco,@uid,GETDATE(),@uid,GETDATE(),'ACTIVO',tPersonaDireccion.id_asentamiento,tPersonaDireccion.id_ciudad,tPersonaDireccion.id_estado,tPersonaDireccion.id_pais,tPersonaDireccion.direccion
									FROM 
									CLIE_Individual tIndividual
									/*@info_datos_pld Datos_SPLD,
									@info_individual tIndividual*/
									OUTER APPLY
									(
										SELECT 
										ISNULL(CONT_Direcciones.colonia,0) AS id_asentamiento,
										ISNULL(CONT_Direcciones.localidad,0) AS id_ciudad,
										ISNULL(CONT_Direcciones.municipio,0) AS id_municipio,
										ISNULL(CONT_Direcciones.estado,0) AS id_estado,
										ISNULL(CONT_Direcciones.pais,0) AS id_pais,
										LTRIM(RTRIM(ISNULL(CONT_Direcciones.direccion, '')))+' '+'No. Int:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior, '')))+' '+'No. Ext:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior, '')))+' '+'Referencia:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.referencia, ''))) AS direccion,
										ISNULL(CONT_Personas.id_pais_nacimiento,0) AS id_pais_nacimiento ,
										ISNULL(CONT_Personas.id_nacionalidad,0) AS id_nacionalidad,
										ISNULL(CONT_Personas.es_pep,CAST(0 AS BIT)) AS es_pep
										FROM CONT_Personas 
										INNER JOIN CONT_Direcciones ON CONT_Direcciones.id=CONT_Personas.id_direccion AND CONT_Direcciones.estatus_registro = 'ACTIVO' 
										WHERE CONT_Personas.id=tIndividual.id_persona
									) AS tPersonaDireccion
									WHERE tIndividual.id_persona=@id_persona
									AND tIndividual.id_cliente=@id_cliente;
								END
								ELSE
								BEGIN
									SELECT @desempenia_funcion_publicaULTIMO = 0,
									@desempenia_funcion_publicaACTUAL = 0,
									@familiar_desempenia_funcion_publicaULTIMO = 0,
									@familiar_desempenia_funcion_publicaACTUAL = 0,
									@id_naturaleza_pagoULTIMO = 0, @etiqueta_naturaleza_pagoULTIMO = '',
									@id_naturaleza_pagoACTUAL = 0, @etiqueta_naturaleza_pagoACTUAL = '',
									@id_profesionULTIMO = 0,
									@id_profesionACTUAL = 0,
									@id_ocupacionULTIMO=0,
									@id_ocupacionACTUAL=0,
									@id_municipioULTIMO = 0,
									@id_municipioACTUAL = 0,
									@id_destino_creditoULTIMO = 0, @etiqueta_destino_creditoULTIMO = '', 
									@id_destino_creditoACTUAL = 0, @etiqueta_destino_creditoACTUAL = '', 
									@id_actividad_economicaULTIMO = 0, @etiqueta_actividad_economicaULTIMO = '', 
									@id_actividad_economicaACTUAL = 0, @etiqueta_actividad_economicaACTUAL = '', 
									@id_pais_nacimientoULTIMO = 0,
									@id_pais_nacimientoACTUAL = 0,
									@id_nacionalidadULTIMO = 0,
									@id_nacionalidadACTUAL = 0,
									@es_pepULTIMO = 0,  
									@es_pepACTUAL = 0, 
									@es_persona_prohibidaULTIMO = 0, 
									@es_persona_prohibidaACTUAL = 0,
									@HASChange = 0, @INFOCambiosDetectados = '', @DETONAAlarma = 0,
									@id_asentamientoULTIMO =0,
									@id_ciudadULTIMO =0,
									@id_estadoULTIMO =0,
									@id_paisULTIMO =0,
									@direccionULTIMO ='',
									@id_asentamientoACTUAL  = 0, 
									@id_ciudadACTUAL  = 0, 
									@id_estadoACTUAL  = 0, 
									@id_paisACTUAL  = 0, 
									@direccionACTUAL=''
			
									SELECT
									TOP(1) 
									@desempenia_funcion_publicaULTIMO = ISNULL(SPLD_DatosCliente.desempenia_funcion_publica,CAST( 0 AS BIT)),
									@familiar_desempenia_funcion_publicaULTIMO = ISNULL(SPLD_DatosCliente.familiar_desempenia_funcion_publica,CAST( 0 AS BIT)),
									@id_naturaleza_pagoULTIMO = ISNULL(SPLD_DatosCliente.id_naturaleza_pago,1), @etiqueta_naturaleza_pagoULTIMO = ISNULL(SPLD_InstrumentoMonetario.tipo_instrumento, 'NINGUNO'),
									@id_profesionULTIMO = ISNULL(SPLD_DatosCliente.id_profesion,0),
									@id_ocupacionULTIMO = ISNULL(SPLD_DatosCliente.id_ocupacion,0),
									@id_asentamientoULTIMO=ISNULL(SPLD_DatosCliente.id_asentamiento_actual,0), 
									@id_ciudadULTIMO=ISNULL(SPLD_DatosCliente.id_ciudad_actual,0), 
									@id_municipioULTIMO = ISNULL(SPLD_DatosCliente.id_municipio_actual,0), 
									@id_estadoULTIMO=ISNULL(SPLD_DatosCliente.id_estado_actual,0), 
									@id_paisULTIMO=ISNULL(SPLD_DatosCliente.id_pais_actual,0), 
									@direccionULTIMO=ISNULL(SPLD_DatosCliente.direccion,''),  
									@id_destino_creditoULTIMO = ISNULL(SPLD_DatosCliente.id_destino_credito,0), @etiqueta_destino_creditoULTIMO = ISNULL(CATA_destinoCredito.descripcion, 'NINGUNO'),
									@id_actividad_economicaULTIMO = ISNULL(SPLD_DatosCliente.id_actividad_economica,0), @etiqueta_actividad_economicaULTIMO = ISNULL(CATA_ActividadEconomica.etiqueta, 'NINGUNO'),
									@id_pais_nacimientoULTIMO = ISNULL(SPLD_DatosCliente.id_pais_nacimiento,0), 
									@id_nacionalidadULTIMO = ISNULL(SPLD_DatosCliente.id_nacionalidad,0), 
									@es_pepULTIMO = ISNULL(SPLD_DatosCliente.es_pep,0),
									@es_persona_prohibidaULTIMO = ISNULL(SPLD_DatosCliente.es_persona_prohibida,0)
									FROM 
									SPLD_DatosCliente
									LEFT JOIN SPLD_InstrumentoMonetario ON SPLD_InstrumentoMonetario.id = SPLD_DatosCliente.id_naturaleza_pago
									LEFT JOIN CATA_profesion ON CATA_profesion.id = SPLD_DatosCliente.id_profesion
									LEFT JOIN CATA_municipio ON CATA_municipio.id = SPLD_DatosCliente.id_municipio_actual
									LEFT JOIN CATA_destinoCredito ON CATA_destinoCredito.id = SPLD_DatosCliente.id_destino_credito
									LEFT JOIN CATA_ActividadEconomica ON CATA_ActividadEconomica.id = SPLD_DatosCliente.id_actividad_economica
									LEFT JOIN CATA_pais NACIMIENTO ON NACIMIENTO.id = SPLD_DatosCliente.id_pais_nacimiento
									LEFT JOIN CATA_nacionalidad ON CATA_nacionalidad.id = SPLD_DatosCliente.id_nacionalidad
									WHERE 
									SPLD_DatosCliente.id_persona=@id_persona 
									AND SPLD_DatosCliente.id_cliente = @id_cliente
									AND SPLD_DatosCliente.id_prestamo_monto = @intIdSolicitudPrestamoMonto
									AND SPLD_DatosCliente.estatus_registro='ACTIVO'
									ORDER BY SPLD_DatosCliente.id DESC
							
									SELECT
									@id_actividad_economicaACTUAL = CLIE_Individual.id_actividad_economica, @etiqueta_actividad_economicaACTUAL = ISNULL(CATA_ActividadEconomica.etiqueta, 'NINGUNO'),
									@id_profesionACTUAL = CLIE_Individual.id_profesion, 
									@id_ocupacionACTUAL=CLIE_Individual.id_ocupacion,
									@id_destino_creditoACTUAL = CLIE_Individual.econ_id_destino_credito, @etiqueta_destino_creditoACTUAL = ISNULL(CATA_destinoCredito.descripcion, 'NINGUNO'),
									@id_nacionalidadACTUAL = CONT_Personas.id_nacionalidad, 
									@id_pais_nacimientoACTUAL = CONT_Personas.id_pais_nacimiento, 
									@es_pepACTUAL = CONT_Personas.es_pep,
									@es_persona_prohibidaACTUAL = CONT_Personas.es_persona_prohibida,
									@id_municipioACTUAL = CONT_Direcciones.municipio,
									@id_asentamientoACTUAL=ISNULL(CONT_Direcciones.colonia,0), 
									@id_ciudadACTUAL=ISNULL(CONT_Direcciones.localidad,0), 
									@id_estadoACTUAL=ISNULL(CONT_Direcciones.estado,0), 
									@id_paisACTUAL=ISNULL(CONT_Direcciones.pais,0), 
									@direccionACTUAL=LTRIM(RTRIM(ISNULL(CONT_Direcciones.direccion, '')))+' '+'No. Int:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior, '')))+' '+'No. Ext:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior, '')))+' '+'Referencia:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.referencia, '')))
					
									FROM 
									CLIE_Individual
									INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id AND CONT_Personas.id=@id_persona
									INNER JOIN CONT_Direcciones ON CONT_Personas.id_direccion=CONT_Direcciones.id
									LEFT JOIN CATA_profesion ON CATA_profesion.id = CLIE_Individual.id_profesion
									LEFT JOIN CATA_municipio ON CATA_municipio.id = CONT_Direcciones.municipio
									LEFT JOIN CATA_destinoCredito ON CATA_destinoCredito.id = CLIE_Individual.econ_id_destino_credito
									LEFT JOIN CATA_ActividadEconomica ON CATA_ActividadEconomica.id = CLIE_Individual.id_actividad_economica
									LEFT JOIN CATA_pais CATA_pais ON CATA_pais.id = CONT_Personas.id_pais_nacimiento
									LEFT JOIN CATA_nacionalidad ON CATA_nacionalidad.id = CONT_Personas.id_nacionalidad
									WHERE CLIE_Individual.id_cliente=@id_cliente

									SELECT
									@desempenia_funcion_publicaACTUAL = ISNULL(desempenia_funcion_publica, CAST(0 AS BIT)),
									@familiar_desempenia_funcion_publicaACTUAL = ISNULL(familiar_desempenia_funcion_publica, CAST(0 AS BIT)),
									@id_naturaleza_pagoACTUAL = ISNULL(id_instrumento_monetario, 0), @etiqueta_naturaleza_pagoACTUAL = ISNULL(SPLD_InstrumentoMonetario.tipo_instrumento, '')
									FROM 
									CLIE_Individual tIndividual
									/*@info_datos_pld Datos_SPLD*/
									/*LEFT JOIN SPLD_InstrumentoMonetario ON SPLD_InstrumentoMonetario.id = Datos_SPLD.id_instrumento_monetario*/
									LEFT JOIN SPLD_InstrumentoMonetario ON SPLD_InstrumentoMonetario.id = tIndividual.id_instrumento_monetario

									WHERE tIndividual.id_persona=@id_persona
									AND tIndividual.id_cliente=@id_cliente;
									IF @id_actividad_economicaULTIMO <> @id_actividad_economicaACTUAL AND (SELECT COUNT(id) FROM SPLD_DatosCliente WHERE id_cliente=@id_cliente AND id_actividad_economica =@id_actividad_economicaACTUAL AND estatus_registro='ACTIVO') = 0 									
									BEGIN
										SET @INFOCambiosDetectados = (@INFOCambiosDetectados + ' Actividad Econ�mica: ' + @etiqueta_actividad_economicaULTIMO + ' a ' + @etiqueta_actividad_economicaACTUAL + '.')
										SELECT @HASChange = 1, @DETONAAlarma = 1
									END
									IF(@id_profesionULTIMO <> @id_profesionACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_ocupacionULTIMO <> @id_ocupacionACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_destino_creditoULTIMO <> @id_destino_creditoACTUAL)
									BEGIN
										SET @INFOCambiosDetectados = (@INFOCambiosDetectados + ' Destino Cr�dito: ' + @etiqueta_destino_creditoULTIMO + ' a ' + @etiqueta_destino_creditoACTUAL + '.')
										SELECT @HASChange = 1, @DETONAAlarma = 1
									END
									IF(@id_nacionalidadULTIMO <> @id_nacionalidadACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_pais_nacimientoULTIMO <> @id_pais_nacimientoACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_asentamientoULTIMO <> @id_asentamientoACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_ciudadULTIMO <> @id_ciudadACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_municipioULTIMO <> @id_municipioACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_estadoULTIMO <> @id_estadoACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_paisULTIMO <> @id_paisACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(RTRIM(LTRIM(REPLACE(@direccionULTIMO,' ',''))) <> RTRIM(LTRIM(REPLACE(@direccionACTUAL,' ',''))))
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_naturaleza_pagoULTIMO <> @id_naturaleza_pagoACTUAL)
									BEGIN
										SET @INFOCambiosDetectados = (@INFOCambiosDetectados + ' Instrumento Monetario: ' + @etiqueta_naturaleza_pagoULTIMO + ' a ' + @etiqueta_naturaleza_pagoACTUAL + '.')
										SELECT @HASChange = 1, @DETONAAlarma = 1
									END
									IF(@es_pepULTIMO <> @es_pepACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@es_persona_prohibidaULTIMO <> @es_persona_prohibidaACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@desempenia_funcion_publicaULTIMO <> @desempenia_funcion_publicaACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@familiar_desempenia_funcion_publicaULTIMO <> @familiar_desempenia_funcion_publicaACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@HASChange = 0)
									BEGIN
										UPDATE SPLD_DatosCliente
										SET
										desempenia_funcion_publica_cargo=tIndividual.desempenia_funcion_publica_cargo,
										desempenia_funcion_publica_dependencia=tIndividual.desempenia_funcion_publica_dependencia,
										familiar_desempenia_funcion_publica_cargo=tIndividual.familiar_desempenia_funcion_publica_cargo,
										familiar_desempenia_funcion_publica_nombre=tIndividual.familiar_desempenia_funcion_publica_nombre,
										familiar_desempenia_funcion_publica_paterno=tIndividual.familiar_desempenia_funcion_publica_paterno,
										familiar_desempenia_funcion_publica_materno=tIndividual.familiar_desempenia_funcion_publica_materno,
										familiar_desempenia_funcion_publica_parentesco=tIndividual.familiar_desempenia_funcion_publica_parentesco,
										id_ocupacion=tIndividual.id_ocupacion
										FROM
										CLIE_Individual tIndividual
										/*@info_datos_pld Datos_SPLD,
										@info_individual tIndividual
										WHERE SPLD_DatosCliente.id=.Datos_SPLD.id*/
										WHERE 
										SPLD_DatosCliente.id_cliente=@id_cliente
										AND SPLD_DatosCliente.id_persona=@id_persona
										AND SPLD_DatosCliente.id_prestamo_monto=@intIdSolicitudPrestamoMonto;
									END
									ELSE
									BEGIN
										IF(@DETONAAlarma <> 0)
										BEGIN
											DELETE FROM @DATOSReporteCNBV	
											DELETE FROM @ResultadoOperacion
											SET @Mensaje=''
											SET @Resultado=''
						
											INSERT INTO @DATOSReporteCNBV
											EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA', '','','01/01/1901','01/01/1901','',@id_persona,0,0
						
											IF(SELECT COUNT(*) FROM @DATOSReporteCNBV)>0
											BEGIN
												UPDATE @DATOSReporteCNBV 
												SET id_tipo_reporte= 0, 
												descripcion_reporte= 'El Perfil Transaccional del Cliente cambi�:' + @INFOCambiosDetectados
												INSERT INTO @ResultadoOperacion
												EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV,'CLIE_insertarInformacionCliente','INSERT_REPORT_AND_CNBV',@uid
												IF(SELECT COUNT(*) FROM @ResultadoOperacion)>0
												BEGIN
													SELECT TOP(1) @Resultado=resultado, @Mensaje=mensaje FROM @ResultadoOperacion
													INSERT INTO @TablaRetorno
													SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,@Resultado,'CLIE_insertarInformacionCliente',0,@Mensaje
												END
												ELSE
												BEGIN
													INSERT INTO @TablaRetorno
													SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo generar el reporte de perfil transaccional'
												END
											END
											ELSE
											BEGIN
												INSERT INTO @TablaRetorno
												SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'ERROR','CLIE_insertarInformacionCliente',0,'No se pudo obtener los datos para generar el reporte de perfil transaccional'
											END
											INSERT INTO @TablaRetorno
											SELECT @intIdSolicitudPrestamoMonto,@id_cliente,@id_persona,'CORRECTO','CLIE_insertarInformacionCliente',0,'Cambi� el perfil transaccional del cliente'
										END
						
										INSERT INTO SPLD_DatosCliente(id_prestamo_monto,id_persona,id_cliente,id_tipo_operacion,numero_creditos,monto_pago,id_naturaleza_pago,
										id_pais_nacimiento,id_nacionalidad,id_municipio_actual,id_actividad_economica,id_ocupacion,id_profesion,id_destino_credito,es_pep,es_persona_prohibida,
										desempenia_funcion_publica,desempenia_funcion_publica_cargo,desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica,familiar_desempenia_funcion_publica_cargo,
										familiar_desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica_nombre,familiar_desempenia_funcion_publica_paterno,familiar_desempenia_funcion_publica_materno,
										familiar_desempenia_funcion_publica_parentesco,creado_por,fecha_registro,modificado_por,fecha_revision,estatus_registro,id_asentamiento_actual,id_ciudad_actual,id_estado_actual,id_pais_actual,direccion)

										SELECT @intIdSolicitudPrestamoMonto,@id_persona,@id_cliente,1,1,0.0, tIndividual.id_instrumento_monetario,
										tPersonaDireccion.id_pais_nacimiento,tPersonaDireccion.id_nacionalidad,tPersonaDireccion.id_municipio,tIndividual.id_actividad_economica,tIndividual.id_ocupacion,tIndividual.id_profesion,tIndividual.econ_id_destino_credito,CASE @evaluar_pep WHEN 0 THEN tPersonaDireccion.es_pep ELSE @es_pep END,@es_persona_prohibida,
										tIndividual.desempenia_funcion_publica,tIndividual.desempenia_funcion_publica_cargo,tIndividual.desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica,tIndividual.familiar_desempenia_funcion_publica_cargo,
										tIndividual.familiar_desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica_nombre,tIndividual.familiar_desempenia_funcion_publica_paterno,tIndividual.familiar_desempenia_funcion_publica_materno,
										tIndividual.familiar_desempenia_funcion_publica_parentesco,@uid,GETDATE(),@uid,GETDATE(),'ACTIVO',tPersonaDireccion.id_asentamiento,tPersonaDireccion.id_ciudad,tPersonaDireccion.id_estado,tPersonaDireccion.id_pais,tPersonaDireccion.direccion
										-- 'ALGUN DATO CAMBIO',1,GETDATE(),1,GETDATE(),'ACTIVO'
										FROM 
										CLIE_Individual tIndividual
										/*@info_datos_pld Datos_SPLD,
										@info_individual tIndividual*/
				
										OUTER APPLY
										(
											SELECT 
											ISNULL(CONT_Direcciones.colonia,0) AS id_asentamiento,
											ISNULL(CONT_Direcciones.localidad,0) AS id_ciudad,
											ISNULL(CONT_Direcciones.municipio,0) AS id_municipio,
											ISNULL(CONT_Direcciones.estado,0) AS id_estado,
											ISNULL(CONT_Direcciones.pais,0) AS id_pais,
											LTRIM(RTRIM(ISNULL(CONT_Direcciones.direccion, '')))+' '+'No. Int:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior, '')))+' '+'No. Ext:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior, '')))+' '+'Referencia:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.referencia, ''))) AS direccion,
											ISNULL(CONT_Personas.id_pais_nacimiento,0) AS id_pais_nacimiento ,
											ISNULL(CONT_Personas.id_nacionalidad,0) AS id_nacionalidad,
											ISNULL(CONT_Personas.es_pep,CAST(0 AS BIT)) AS es_pep
											FROM CONT_Personas 
											INNER JOIN CONT_Direcciones ON CONT_Direcciones.id=CONT_Personas.id_direccion AND CONT_Direcciones.estatus_registro = 'ACTIVO' 
											WHERE CONT_Personas.id=tIndividual.id_persona 
										) AS tPersonaDireccion
										WHERE tIndividual.id_persona=@id_persona
										AND tIndividual.id_cliente=@id_cliente
									END	
								END

							END
							ELSE
							BEGIN
								IF NOT EXISTS 
								(
									SELECT * FROM SPLD_DatosCliente 
									WHERE SPLD_DatosCliente.id_persona = @id_persona 
									AND SPLD_DatosCliente.id_cliente = @id_cliente 
									AND SPLD_DatosCliente.id_prestamo_monto = @intIdSolicitudPrestamoMonto
									AND estatus_registro='ACTIVO'
								)
								BEGIN
					
									INSERT INTO SPLD_DatosCliente(id_prestamo_monto,id_persona,id_cliente,id_tipo_operacion,numero_creditos,monto_pago,id_naturaleza_pago,
									id_pais_nacimiento,id_nacionalidad,id_municipio_actual,id_actividad_economica,id_ocupacion,id_profesion,id_destino_credito,es_pep,es_persona_prohibida,
									desempenia_funcion_publica,desempenia_funcion_publica_cargo,desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica,familiar_desempenia_funcion_publica_cargo,
									familiar_desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica_nombre,familiar_desempenia_funcion_publica_paterno,familiar_desempenia_funcion_publica_materno,
									familiar_desempenia_funcion_publica_parentesco,creado_por,fecha_registro,modificado_por,fecha_revision,estatus_registro,id_asentamiento_actual,id_ciudad_actual,id_estado_actual,id_pais_actual,direccion)

									SELECT 
									@intIdSolicitudPrestamoMonto,@id_persona,@id_cliente,1,1,0.0, tIndividual.id_instrumento_monetario,
									tPersonaDireccion.id_pais_nacimiento,tPersonaDireccion.id_nacionalidad,tPersonaDireccion.id_municipio,tIndividual.id_actividad_economica,tIndividual.id_ocupacion,tIndividual.id_profesion,tIndividual.econ_id_destino_credito,
									CASE @evaluar_pep WHEN 0 THEN tPersonaDireccion.es_pep ELSE @es_pep END,@es_persona_prohibida,
									tIndividual.desempenia_funcion_publica,tIndividual.desempenia_funcion_publica_cargo,tIndividual.desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica,tIndividual.familiar_desempenia_funcion_publica_cargo,
									tIndividual.familiar_desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica_nombre,tIndividual.familiar_desempenia_funcion_publica_paterno,tIndividual.familiar_desempenia_funcion_publica_materno,
									tIndividual.familiar_desempenia_funcion_publica_parentesco,@uid,GETDATE(),@uid,GETDATE(),'ACTIVO',tPersonaDireccion.id_asentamiento,tPersonaDireccion.id_ciudad,tPersonaDireccion.id_estado,tPersonaDireccion.id_pais,tPersonaDireccion.direccion
									FROM 
									CLIE_Individual tIndividual
									/*@info_datos_pld Datos_SPLD,
									@info_individual tIndividual*/
									OUTER APPLY
									(
										SELECT 
										ISNULL(CONT_Direcciones.colonia,0) AS id_asentamiento,
										ISNULL(CONT_Direcciones.localidad,0) AS id_ciudad,
										ISNULL(CONT_Direcciones.municipio,0) AS id_municipio,
										ISNULL(CONT_Direcciones.estado,0) AS id_estado,
										ISNULL(CONT_Direcciones.pais,0) AS id_pais,
										LTRIM(RTRIM(ISNULL(CONT_Direcciones.direccion, '')))+' '+'No. Int:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior, '')))+' '+'No. Ext:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior, '')))+' '+'Referencia:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.referencia, ''))) AS direccion,
										ISNULL(CONT_Personas.id_pais_nacimiento,0) AS id_pais_nacimiento ,
										ISNULL(CONT_Personas.id_nacionalidad,0) AS id_nacionalidad,
										ISNULL(CONT_Personas.es_pep,CAST(0 AS BIT)) AS es_pep
										FROM CONT_Personas 
										INNER JOIN CONT_Direcciones ON CONT_Direcciones.id=CONT_Personas.id_direccion AND CONT_Direcciones.estatus_registro = 'ACTIVO' 
										WHERE CONT_Personas.id=tIndividual.id_persona
									) AS tPersonaDireccion
									WHERE tIndividual.id_persona=@id_persona
									AND tIndividual.id_cliente=@id_cliente
								END
								ELSE
								BEGIN
									SELECT @desempenia_funcion_publicaULTIMO = 0,
									@desempenia_funcion_publicaACTUAL = 0,
									@familiar_desempenia_funcion_publicaULTIMO = 0,
									@familiar_desempenia_funcion_publicaACTUAL = 0,
									@id_naturaleza_pagoULTIMO = 0, @etiqueta_naturaleza_pagoULTIMO = '',
									@id_naturaleza_pagoACTUAL = 0, @etiqueta_naturaleza_pagoACTUAL = '',
									@id_profesionULTIMO = 0,
									@id_profesionACTUAL = 0,
									@id_ocupacionULTIMO=0,
									@id_ocupacionACTUAL=0,
									@id_municipioULTIMO = 0,
									@id_municipioACTUAL = 0,
									@id_destino_creditoULTIMO = 0, @etiqueta_destino_creditoULTIMO = '', 
									@id_destino_creditoACTUAL = 0, @etiqueta_destino_creditoACTUAL = '', 
									@id_actividad_economicaULTIMO = 0, @etiqueta_actividad_economicaULTIMO = '', 
									@id_actividad_economicaACTUAL = 0, @etiqueta_actividad_economicaACTUAL = '', 
									@id_pais_nacimientoULTIMO = 0,
									@id_pais_nacimientoACTUAL = 0,
									@id_nacionalidadULTIMO = 0,
									@id_nacionalidadACTUAL = 0,
									@es_pepULTIMO = 0,  
									@es_pepACTUAL = 0, 
									@es_persona_prohibidaULTIMO = 0, 
									@es_persona_prohibidaACTUAL = 0,
									@HASChange = 0, @INFOCambiosDetectados = '', @DETONAAlarma = 0,
									@id_asentamientoULTIMO =0,
									@id_ciudadULTIMO =0,
									@id_estadoULTIMO =0,
									@id_paisULTIMO=0,
									@direccionULTIMO ='',
									@id_asentamientoACTUAL  = 0, 
									@id_ciudadACTUAL  = 0, 
									@id_estadoACTUAL  = 0, 
									@id_estadoACTUAL  = 0, 
									@id_paisACTUAL  = 0, 
									@direccionACTUAL=''
			
									SELECT
									TOP(1) 
									@desempenia_funcion_publicaULTIMO = ISNULL(SPLD_DatosCliente.desempenia_funcion_publica,CAST( 0 AS BIT)),
									@familiar_desempenia_funcion_publicaULTIMO = ISNULL(SPLD_DatosCliente.familiar_desempenia_funcion_publica,CAST( 0 AS BIT)),
									@id_naturaleza_pagoULTIMO = ISNULL(SPLD_DatosCliente.id_naturaleza_pago,1), @etiqueta_naturaleza_pagoULTIMO = ISNULL(SPLD_InstrumentoMonetario.tipo_instrumento, 'NINGUNO'),
									@id_profesionULTIMO = ISNULL(SPLD_DatosCliente.id_profesion,0), 
									@id_ocupacionULTIMO = ISNULL(SPLD_DatosCliente.id_ocupacion,0), 
									@id_asentamientoULTIMO=ISNULL(SPLD_DatosCliente.id_asentamiento_actual,0), 
									@id_ciudadULTIMO=ISNULL(SPLD_DatosCliente.id_ciudad_actual,0), 
									@id_municipioULTIMO = ISNULL(SPLD_DatosCliente.id_municipio_actual,0), 
									@id_estadoULTIMO=ISNULL(SPLD_DatosCliente.id_estado_actual,0), 
									@id_paisULTIMO=ISNULL(SPLD_DatosCliente.id_pais_actual,0), 
									@direccionULTIMO=ISNULL(SPLD_DatosCliente.direccion,''), 
									@id_destino_creditoULTIMO = ISNULL(SPLD_DatosCliente.id_destino_credito,0), @etiqueta_destino_creditoULTIMO = ISNULL(CATA_destinoCredito.descripcion, 'NINGUNO'),
									@id_actividad_economicaULTIMO = ISNULL(SPLD_DatosCliente.id_actividad_economica,0), @etiqueta_actividad_economicaULTIMO = ISNULL(CATA_ActividadEconomica.etiqueta, 'NINGUNO'),
									@id_pais_nacimientoULTIMO = ISNULL(SPLD_DatosCliente.id_pais_nacimiento,0), 
									@id_nacionalidadULTIMO = ISNULL(SPLD_DatosCliente.id_nacionalidad,0), 
									@es_pepULTIMO = ISNULL(SPLD_DatosCliente.es_pep,0),
									@es_persona_prohibidaULTIMO = ISNULL(SPLD_DatosCliente.es_persona_prohibida,0)
									FROM 
									SPLD_DatosCliente
									LEFT JOIN SPLD_InstrumentoMonetario ON SPLD_InstrumentoMonetario.id = SPLD_DatosCliente.id_naturaleza_pago
									LEFT JOIN CATA_profesion ON CATA_profesion.id = SPLD_DatosCliente.id_profesion
									LEFT JOIN CATA_municipio ON CATA_municipio.id = SPLD_DatosCliente.id_municipio_actual
									LEFT JOIN CATA_destinoCredito ON CATA_destinoCredito.id = SPLD_DatosCliente.id_destino_credito
									LEFT JOIN CATA_ActividadEconomica ON CATA_ActividadEconomica.id = SPLD_DatosCliente.id_actividad_economica
									LEFT JOIN CATA_pais NACIMIENTO ON NACIMIENTO.id = SPLD_DatosCliente.id_pais_nacimiento
									LEFT JOIN CATA_nacionalidad ON CATA_nacionalidad.id = SPLD_DatosCliente.id_nacionalidad
									WHERE 
									SPLD_DatosCliente.id_persona=@id_persona 
									AND SPLD_DatosCliente.id_cliente = @id_cliente
									AND SPLD_DatosCliente.id_prestamo_monto = @intIdSolicitudPrestamoMonto
									AND SPLD_DatosCliente.estatus_registro='ACTIVO'
									ORDER BY SPLD_DatosCliente.id DESC
							
									SELECT
									@id_actividad_economicaACTUAL = CLIE_Individual.id_actividad_economica, @etiqueta_actividad_economicaACTUAL = ISNULL(CATA_ActividadEconomica.etiqueta, 'NINGUNO'),
									@id_profesionACTUAL = CLIE_Individual.id_profesion, 
									@id_ocupacionACTUAL=CLIE_Individual.id_ocupacion,
									@id_destino_creditoACTUAL = CLIE_Individual.econ_id_destino_credito, @etiqueta_destino_creditoACTUAL = ISNULL(CATA_destinoCredito.descripcion, 'NINGUNO'),
									@id_nacionalidadACTUAL = CONT_Personas.id_nacionalidad, 
									@id_pais_nacimientoACTUAL = CONT_Personas.id_pais_nacimiento, 
									@es_pepACTUAL = CONT_Personas.es_pep,
									@es_persona_prohibidaACTUAL = CONT_Personas.es_persona_prohibida,
									@id_municipioACTUAL = CONT_Direcciones.municipio,
									@id_asentamientoACTUAL=ISNULL(CONT_Direcciones.colonia,0), 
									@id_ciudadACTUAL=ISNULL(CONT_Direcciones.localidad,0), 
									@id_estadoACTUAL=ISNULL(CONT_Direcciones.estado,0), 
									@id_paisACTUAL=ISNULL(CONT_Direcciones.pais,0), 
									@direccionACTUAL=LTRIM(RTRIM(ISNULL(CONT_Direcciones.direccion, '')))+' '+'No. Int:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior, '')))+' '+'No. Ext:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior, '')))+' '+'Referencia:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.referencia, '')))
									FROM 
									CLIE_Individual
									INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id AND CONT_Personas.id=@id_persona
									INNER JOIN CONT_Direcciones ON CONT_Personas.id_direccion=CONT_Direcciones.id
									LEFT JOIN CATA_profesion ON CATA_profesion.id = CLIE_Individual.id_profesion
									LEFT JOIN CATA_municipio ON CATA_municipio.id = CONT_Direcciones.municipio
									LEFT JOIN CATA_destinoCredito ON CATA_destinoCredito.id = CLIE_Individual.econ_id_destino_credito
									LEFT JOIN CATA_ActividadEconomica ON CATA_ActividadEconomica.id = CLIE_Individual.id_actividad_economica
									LEFT JOIN CATA_pais CATA_pais ON CATA_pais.id = CONT_Personas.id_pais_nacimiento
									LEFT JOIN CATA_nacionalidad ON CATA_nacionalidad.id = CONT_Personas.id_nacionalidad
									WHERE CLIE_Individual.id_cliente=@id_cliente

									SELECT
									@desempenia_funcion_publicaACTUAL = ISNULL(desempenia_funcion_publica, CAST(0 AS BIT)),
									@familiar_desempenia_funcion_publicaACTUAL = ISNULL(familiar_desempenia_funcion_publica, CAST(0 AS BIT)),
									@id_naturaleza_pagoACTUAL = ISNULL(id_instrumento_monetario, 0), @etiqueta_naturaleza_pagoACTUAL = ISNULL(SPLD_InstrumentoMonetario.tipo_instrumento, '')
									FROM 
									CLIE_Individual tIndividual
									/*@info_datos_pld Datos_SPLD*/
									LEFT JOIN SPLD_InstrumentoMonetario ON SPLD_InstrumentoMonetario.id =tIndividual.id_instrumento_monetario

									WHERE tIndividual.id_cliente=@id_cliente
									AND tIndividual.id_persona=@id_persona
			
									IF(@id_actividad_economicaULTIMO <> @id_actividad_economicaACTUAL)
									BEGIN
										SELECT @HASChange = 1
									END
									IF(@id_profesionULTIMO <> @id_profesionACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_ocupacionULTIMO <> @id_ocupacionACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_destino_creditoULTIMO <> @id_destino_creditoACTUAL)
									BEGIN
					
										SELECT @HASChange = 1
									END
									IF(@id_nacionalidadULTIMO <> @id_nacionalidadACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_pais_nacimientoULTIMO <> @id_pais_nacimientoACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_asentamientoULTIMO <> @id_asentamientoACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_ciudadULTIMO <> @id_ciudadACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_municipioULTIMO <> @id_municipioACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_estadoULTIMO <> @id_estadoACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@id_paisULTIMO <> @id_paisACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(RTRIM(LTRIM(REPLACE(@direccionULTIMO,' ',''))) <> RTRIM(LTRIM(REPLACE(@direccionACTUAL,' ',''))))
									BEGIN
										SET @HASChange = 1
									END

									IF(@id_naturaleza_pagoULTIMO <> @id_naturaleza_pagoACTUAL)
									BEGIN
										SELECT @HASChange = 1
									END
									IF(@es_pepULTIMO <> @es_pepACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@es_persona_prohibidaULTIMO <> @es_persona_prohibidaACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@desempenia_funcion_publicaULTIMO <> @desempenia_funcion_publicaACTUAL)
									BEGIN
										SET @HASChange = 1
									END
									IF(@familiar_desempenia_funcion_publicaULTIMO <> @familiar_desempenia_funcion_publicaACTUAL)
									BEGIN
										SET @HASChange = 1
									END

									IF(@HASChange = 0)
									BEGIN
										UPDATE SPLD_DatosCliente
										SET
										desempenia_funcion_publica_cargo=tIndividual.desempenia_funcion_publica_cargo,
										desempenia_funcion_publica_dependencia=tIndividual.desempenia_funcion_publica_dependencia,
										familiar_desempenia_funcion_publica_cargo=tIndividual.familiar_desempenia_funcion_publica_cargo,
										familiar_desempenia_funcion_publica_nombre=tIndividual.familiar_desempenia_funcion_publica_nombre,
										familiar_desempenia_funcion_publica_paterno=tIndividual.familiar_desempenia_funcion_publica_paterno,
										familiar_desempenia_funcion_publica_materno=tIndividual.familiar_desempenia_funcion_publica_materno,
										familiar_desempenia_funcion_publica_parentesco=tIndividual.familiar_desempenia_funcion_publica_parentesco,
										id_ocupacion=tIndividual.id_ocupacion
										FROM
										CLIE_Individual tIndividual
										/*@info_datos_pld Datos_SPLD,
										@info_individual tIndividual
										WHERE SPLD_DatosCliente.id=Datos_SPLD.id*/
										WHERE
										SPLD_DatosCliente.id_cliente=@id_cliente
										AND SPLD_DatosCliente.id_persona=@id_persona
										AND SPLD_DatosCliente.id_prestamo_monto=@intIdSolicitudPrestamoMonto;
									END
									ELSE
									BEGIN

						
										INSERT INTO SPLD_DatosCliente(id_prestamo_monto,id_persona,id_cliente,id_tipo_operacion,numero_creditos,monto_pago,id_naturaleza_pago,
										id_pais_nacimiento,id_nacionalidad,id_municipio_actual,id_actividad_economica,id_ocupacion,id_profesion,id_destino_credito,es_pep,es_persona_prohibida,
										desempenia_funcion_publica,desempenia_funcion_publica_cargo,desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica,familiar_desempenia_funcion_publica_cargo,
										familiar_desempenia_funcion_publica_dependencia,familiar_desempenia_funcion_publica_nombre,familiar_desempenia_funcion_publica_paterno,familiar_desempenia_funcion_publica_materno,
										familiar_desempenia_funcion_publica_parentesco,creado_por,fecha_registro,modificado_por,fecha_revision,estatus_registro,id_asentamiento_actual,id_ciudad_actual,id_estado_actual,id_pais_actual,direccion)

										SELECT @intIdSolicitudPrestamoMonto,@id_persona,@id_cliente,1,1,0.0, tIndividual.id_instrumento_monetario,
										tPersonaDireccion.id_pais_nacimiento,tPersonaDireccion.id_nacionalidad,tPersonaDireccion.id_municipio,tIndividual.id_actividad_economica,tIndividual.id_ocupacion,tIndividual.id_profesion,tIndividual.econ_id_destino_credito,CASE @evaluar_pep WHEN 0 THEN tPersonaDireccion.es_pep ELSE @es_pep END,@es_persona_prohibida,
										tIndividual.desempenia_funcion_publica,tIndividual.desempenia_funcion_publica_cargo,tIndividual.desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica,tIndividual.familiar_desempenia_funcion_publica_cargo,
										tIndividual.familiar_desempenia_funcion_publica_dependencia,tIndividual.familiar_desempenia_funcion_publica_nombre,tIndividual.familiar_desempenia_funcion_publica_paterno,tIndividual.familiar_desempenia_funcion_publica_materno,
										tIndividual.familiar_desempenia_funcion_publica_parentesco,@uid,GETDATE(),@uid,GETDATE(),'ACTIVO',tPersonaDireccion.id_asentamiento,tPersonaDireccion.id_ciudad,tPersonaDireccion.id_estado,tPersonaDireccion.id_pais,tPersonaDireccion.direccion
										-- 'ALGUN DATO CAMBIO',1,GETDATE(),1,GETDATE(),'ACTIVO'
										FROM 
										CLIE_Individual	tIndividual
										/*@info_datos_pld Datos_SPLD,
										@info_individual tIndividual*/
										OUTER APPLY
										(
											SELECT 
											ISNULL(CONT_Direcciones.colonia,0) AS id_asentamiento,
											ISNULL(CONT_Direcciones.localidad,0) AS id_ciudad,
											ISNULL(CONT_Direcciones.municipio,0) AS id_municipio,
											ISNULL(CONT_Direcciones.estado,0) AS id_estado,
											ISNULL(CONT_Direcciones.pais,0) AS id_pais,
											LTRIM(RTRIM(ISNULL(CONT_Direcciones.direccion, '')))+' '+'No. Int:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_interior, '')))+' '+'No. Ext:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.numero_exterior, '')))+' '+'Referencia:'+LTRIM(RTRIM(ISNULL(CONT_Direcciones.referencia, ''))) AS direccion,
											ISNULL(CONT_Personas.id_pais_nacimiento,0) AS id_pais_nacimiento ,
											ISNULL(CONT_Personas.id_nacionalidad,0) AS id_nacionalidad,
											ISNULL(CONT_Personas.es_pep,CAST(0 AS BIT)) AS es_pep
											FROM CONT_Personas 
											INNER JOIN CONT_Direcciones ON CONT_Direcciones.id=CONT_Personas.id_direccion AND CONT_Direcciones.estatus_registro = 'ACTIVO' 
											WHERE CONT_Personas.id=tIndividual.id_persona
										) AS tPersonaDireccion

										WHERE tIndividual.id_persona=@id_persona
										AND tIndividual.id_cliente=@id_cliente
									END

								END
							END
			
							INSERT INTO @TablaRetorno
							SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'CORRECTO','CLIE_AsignacionCreditoCliente',0,'La asignaci�n fue guardada exit�samente.';
					 END
					    						
					COMMIT TRANSACTION TranAsignarCreditoCliente;
				END
				ELSE
				BEGIN
					INSERT INTO @TablaRetorno
					SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El cr�dito y el cliente no pertenecen a la misma oficina o el cr�dito tiene un estatus no valido';
				END
			/*END
			ELSE
			BEGIN
				IF(@id_tipo_credito=2)
				BEGIN
					INSERT INTO @TablaRetorno
					SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El cr�dito es de tipo individual y ya tiene asignado un cliente';
				END
				ELSE
				BEGIN 
					INSERT INTO @TablaRetorno
					SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El tipo o estatus del cr�dito no es valido';
				END
			END*/

		END
		ELSE
		BEGIN
			INSERT INTO @TablaRetorno
			SELECT @intIdSolicitudPrestamoMonto,@id_cliente, @id_persona,'ERROR','CLIE_AsignacionCreditoCliente',0,'El cliente que intenta asignar al cr�dito no es un cliente individual';
		END

		--SELECT 
		--	OTOR_SolicitudPrestamoMonto.id_individual,
		--	CONT_personas.id,
		--	CONT_Personas.nombre,
		--	CONT_Personas.apellido_paterno,
		--	CONT_Personas.apellido_materno,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.estatus,'') AS estatus,
		--	OTOR_SolicitudPrestamoMonto.sub_estatus,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.cargo,'') AS cargo,
		--	OTOR_SolicitudPrestamoMonto.monto_solicitado,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.monto_sugerido,0) AS monto_sugerido,
		--	OTOR_SolicitudPrestamoMonto.monto_autorizado,
		--	CLIE_Individual.econ_id_actividad_economica,
		--	(
		--		SELECT COUNT(*)
		--		FROM CONT_IdentificacionOficial 
		--		INNER JOIN CONT_CURP 
		--		ON CONT_IdentificacionOficial.id = CONT_CURP.id_identificacion_oficial
		--		WHERE CONT_IdentificacionOficial.id_persona = CONT_Personas.id
		--		AND LEN(RTRIM(LTRIM(CAST(CONT_CURP.xml_datos_oficiales AS VARCHAR)))) > 0

		--	)AS CURPFisica,
		--	OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.ciclo,0) AS ciclo,
		--	dbo.ufnObtenerMontoAutorizadoAnterior(OTOR_SolicitudPrestamoMonto.id_individual) AS monto_anterior,
		--	dbo.ufnValidaInformacionCliente(CONT_personas.id) AS id_riesgo_pld,--OTOR_SolicitudPrestamoMonto.id_riesgo_pld AS id_riesgo_pld,
		--	OTOR_SolicitudPrestamoMonto.perfil_riesgo AS riesgo_pld,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.id_cata_medio_desembolso,2) as id_cata_medio_desembolso
		--	FROM OTOR_SolicitudPrestamoMonto
		--	INNER JOIN CLIE_Individual
		--	ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
		--	INNER JOIN CONT_Personas
		--	ON CLIE_Individual.id_persona = CONT_Personas.id
		--	WHERE 
		--	OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @id_solicitud_prestamo
		--	AND OTOR_SolicitudPrestamoMonto.id_individual=@id_cliente
		--	AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus,'')  <> 'CANCELADO' 
		--	AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus,'')  <> 'RECHAZADO'
		--	AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO'
		--	ORDER BY CONT_Personas.nombre;

		--	SELECT 
		--	ISNULL(CLIE_DetalleSeguro.id,0) AS id,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo,0)  AS id_solicitud_prestamo,
		--	ISNULL(OTOR_SolicitudPrestamoMonto.id_individual,0) AS id_individual, 
		--	ISNULL(CATA_ProductoSeguro.id_seguro,0) AS id_seguro,
		--	ISNULL(CLIE_DetalleSeguro.id_seguro_asignacion,0) AS id_asignacion_seguro,
		--	CONT_Personas.nombre +' ' +CONT_Personas.apellido_paterno +' ' + CONT_Personas.apellido_materno AS nombre_socia,
		--	ISNULL(CLIE_DetalleSeguro.nombre_beneficiario,'') AS nombre_beneficiario,
		--	ISNULL(CLIE_DetalleSeguro.parentesco,'') AS parentesco,
		--	ISNULL(CLIE_DetalleSeguro.porcentaje, 0.0) AS porcentaje,
		--	ISNULL(CLIE_DetalleSeguro.costo_seguro, 0.0) AS costo_seguro,
		--	ISNULL(CLIE_DetalleSeguro.incluye_saldo_deudor,0) AS incluye_saldo_deudor,
		--	ISNULL(CLIE_DetalleSeguro.activo, 0) AS activo
		--	 FROM OTOR_SolicitudPrestamoMonto
		--	INNER JOIN  CLIE_Individual
		--		ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
		--	LEFT JOIN CLIE_DetalleSeguro
		--		ON CLIE_DetalleSeguro.id_individual = OTOR_SolicitudPrestamoMonto.id_individual
		--		AND CLIE_DetalleSeguro.id_solicitud_prestamo = OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo
		--		AND CLIE_DetalleSeguro.activo = 1
		--	LEFT JOIN CATA_ProductoSeguro
		--		ON CATA_ProductoSeguro.id = CLIE_DetalleSeguro.id_seguro_asignacion
		--		AND CATA_ProductoSeguro.activo = 1
		--	INNER JOIN CONT_Personas
		--		ON CLIE_Individual.id_persona =  CONT_Personas.id
		--	WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @id_solicitud_prestamo
		--	AND OTOR_SolicitudPrestamoMonto.id_individual=@id_cliente
		--	AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus,'')  <> 'CANCELADO' 
		--	AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus,'')  <> 'RECHAZADO'
		--	AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO';

			
		SELECT ISNULL(id_prestamo_monto,0) AS id_prestamo_monto ,id_cliente,ISNULL(id_persona,0) AS id_persona ,mensaje,procedimiento,linea,evento
		FROM @TablaRetorno
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION TranAsignarCreditoCliente;
		DELETE FROM @TablaRetorno
		INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
		SELECT
		ERROR_NUMBER() AS Numero_de_Error,
		ERROR_SEVERITY() AS Gravedad_del_Error,
		ERROR_STATE() AS Estado_del_Error,
		ERROR_PROCEDURE() AS Procedimiento_del_Error,
		ERROR_LINE() AS Linea_de_Error,
		ERROR_MESSAGE() AS Mensaje_de_Error,
		'CLIE_AsignacionCreditoCliente';

		INSERT INTO @TablaRetorno
		SELECT 0,0,0,'ERROR',ERROR_PROCEDURE(),ERROR_LINE(),ERROR_MESSAGE();
		--SELECT * FROM @TablaPrestamoMonto;
		--SELECT * FROM @TablaSeguro;
		SELECT id_prestamo_monto,id_cliente,id_persona,mensaje,procedimiento,linea,evento
		FROM @TablaRetorno
	END CATCH
END
ELSE IF(@etiqueta_opcion = 'BAJA')
BEGIN
	DECLARE @estatus VARCHAR(50);
	DECLARE @sub_estatus VARCHAR(50);

	BEGIN TRY
	

	IF (@tipo_baja = 'CASTIGADO')
	BEGIN
		SET @estatus = 'RECHAZADO';
		SET @sub_estatus = 'CASTIGADO';
	END
	ELSE IF(@tipo_baja = 'CANCELACION')
	BEGIN
		SET @estatus = 'CANCELADO';
		SET @sub_estatus = 'CANCELACION/ABANDONO';
	END
	ELSE IF(@tipo_baja = 'RECHAZADO')
	BEGIN
		SET @estatus = 'RECHAZADO';
		SET @sub_estatus = 'RECHAZADO';
	END
                           
	IF EXISTS ( 
			SELECT *FROM OTOR_SolicitudPrestamoMonto  
			WHERE OTOR_SolicitudPrestamoMonto.id_individual = @id_cliente AND OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @id_solicitud_prestamo
			AND	OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO' AND OTOR_SolicitudPrestamoMonto.estatus = 'TRAMITE')

	BEGIN
		
		BEGIN TRANSACTION TranAsignarCreditoClienteBaja

		UPDATE OTOR_SolicitudPrestamoMonto 
		SET estatus = @estatus,
		sub_estatus = @sub_estatus,
		motivo = @id_motivo,
		modificado_por = @uid,
		fecha_revision = GETDATE()
		OUTPUT INSERTED.id, INSERTED.id_individual, 0, 'CORRECTO','CLIE_AsignacionCreditoCliente',0, 'Se registro la baja correctamente' 
		INTO @TablaRetorno
		WHERE 	OTOR_SolicitudPrestamoMonto.id_individual = @id_cliente
		AND		OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @id_solicitud_prestamo
		AND		OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO';
							
		IF(@estatus='RECHAZADO' AND @sub_estatus='CASTIGADO')
			BEGIN
				UPDATE CLIE_Clientes SET sub_estatus = 'CASTIGADO', CLIE_Clientes.lista_negra = 1, modificado_por = @uid, fecha_revision = GETDATE() WHERE CLIE_Clientes.id = @id_cliente;
				-- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
				UPDATE CLIE_DetalleSeguro 
				SET CLIE_DetalleSeguro.modificado_por = @uid, 
				fecha_modificacion = GETDATE(),
				CLIE_DetalleSeguro.activo = 0 
				WHERE id_individual = @id_cliente 
				AND id_solicitud_prestamo = @id_solicitud_prestamo 
				AND activo = 1;
			END						
			
			-- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
								
			IF(@estatus='CANCELADO' AND @sub_estatus='CANCELACION/ABANDONO')
					BEGIN
							UPDATE CLIE_DetalleSeguro 
								SET CLIE_DetalleSeguro.modificado_por = @uid, 
								fecha_modificacion = GETDATE(),
								CLIE_DetalleSeguro.activo = 0 
								WHERE id_individual = @id_cliente 
								AND id_solicitud_prestamo = @id_solicitud_prestamo 
								AND activo = 1;
					END	
						
						
			IF(@estatus='RECHAZADO' AND @sub_estatus='RECHAZADO')
					BEGIN
							UPDATE CLIE_DetalleSeguro 
								SET CLIE_DetalleSeguro.modificado_por = @uid, 
								fecha_modificacion = GETDATE(),
								CLIE_DetalleSeguro.activo = 0 
								WHERE id_individual = @id_cliente 
								AND id_solicitud_prestamo = @id_solicitud_prestamo 
								AND activo = 1;
					END	

			COMMIT TRANSACTION TranAsignarCreditoClienteBaja

			IF EXISTS ( SELECT * FROM @TablaRetorno WHERE mensaje = 'CORRECTO')
			BEGIN
				SELECT ISNULL(id_prestamo_monto,0) AS id_prestamo_monto ,id_cliente,ISNULL(id_persona,0) AS id_persona ,mensaje,procedimiento,linea,evento
				FROM @TablaRetorno
			END
			ELSE
			BEGIN
				SELECT 0, @id_cliente, 0, 'ERROR', 'CLIE_AsignacionCreditoCliente', 0, 'No se puedo realizar la actualizaci�n del cliente';
			END
	END
	ELSE
	BEGIN
		SELECT 0, @id_cliente, 0, 'ERROR', 'CLIE_AsignacionCreditoCliente', 0, 'El cliente no se encuetra activo en la solicitud';
	END

	
	END TRY
	BEGIN CATCH
			ROLLBACK TRANSACTION TranAsignarCreditoClienteBaja;
			DELETE FROM @TablaRetorno
			INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
			SELECT
			ERROR_NUMBER() AS Numero_de_Error,
			ERROR_SEVERITY() AS Gravedad_del_Error,
			ERROR_STATE() AS Estado_del_Error,
			ERROR_PROCEDURE() AS Procedimiento_del_Error,
			ERROR_LINE() AS Linea_de_Error,
			ERROR_MESSAGE() AS Mensaje_de_Error,
			'CLIE_AsignacionCreditoCliente';

			INSERT INTO @TablaRetorno
			SELECT 0,0,0,'ERROR',ERROR_PROCEDURE(),ERROR_LINE(),ERROR_MESSAGE();
			--SELECT * FROM @TablaPrestamoMonto;
			--SELECT * FROM @TablaSeguro;
			SELECT id_prestamo_monto,id_cliente,id_persona,mensaje,procedimiento,linea,evento
			FROM @TablaRetorno
	END CATCH

	END
END
GO

--#endregion ------------------------------------- FIN PROCEDURE ASIGNAMENT CLIENT A LOAN ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE ASIGNAMENT MONTO A LOAN ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_registrarActualizarSolicitudCliente
@tablaSolicitud UDT_Solicitud READONLY,
@tablaCliente Cliente READONLY,
@tablaGrupo GrupoSolidario READONLY,
@tablaDireccion Direccion READONLY,
@tablaPrestamoMonto UDT_SolicitudDetalle READONLY,
@seguro UDT_CLIE_DetalleSeguro READONLY,
@referencias_personales UDT_CLIE_ReferenciasPersonales READONLY,
@garantias_prendarias UDT_OTOR_GarantiaPrendaria READONLY,
@tabla_TuHogarConConserva UDT_OTOR_TuHogarConConserva READONLY,
@tabla_TuHogarConConservaCoacreditado UDT_CLIE_TuHogarConConservaCoacreditado READONLY,
@idUsuario INT
AS
BEGIN
-- =============================================
-- Alter date: <08/09/2015>
-- Alter Date:  <04/01/2016> <Roberto Chac n> [Se hace la evaluacion de la matriz de riesgo para cada socia seg n la configuraci n SPLD]
-- Alter Date: 12/05/2016    <Se actualiza el campo de id_actividad_economica, se obtiene de CLIE_Individual.id_actividad_economica>
-- Modificado: Junio de 2016 <Sally Gonzalez> [Se agrego nuevos campos y se inserta en la tabla SPLD_HistorialSociaPerfilRiesgo]
-- Alter Date: <Septiembre 2016> <Sally Gonz lez>[Se inserta y modifica sobre la tabla CLIE_DetalleSeguro.]
-- Alter Date: <29/12/2017> <Una vez autorizado el cr dito se inserta en SPLD_HistorialAutorizacionRiesgo con el correspondiente perfil de riesgo>
--							<Se agrega la evaluaci n del criterio pld ft para el p is de nacimiento y pa s de domicilio de la socia una vez autorizado el cr dito>
--Alter Date: <05/04/2018><Se modifica  pdate , para cambiar de estatus de alto riesgo a socia en TRAMITE - POR AUTORIZAR, por medio de id_solicitud y id_individual>
--Alter Date: <18/04/2018><Se modifica la tabla que obtiene el retorno de la evaluacion de matriz de riesgo, ahora la insercci n al historial de perfil de riesgo se hace con los resultado de la evaluaci n, se moficia la cantidad de variables que se le envia a la evaluaci n de la matriz>
--Alter Date: <16/05/2018><Se inserta secci n de codigo para forzar la actualizaci n de perfil de riesgo de la solicitud individual>
--Alter Date: <13/08/2018> Se agrega opcion para cuando No tiene seguro_asignacion desde el cliente
--Alter Date: <08/10/2020> Administraci n de garant as prendarias.
--Alter Date: <22/02/2021> Administraci n de garant as financiadas.
--Alter Date: <12/03/2021> Se actualiza el id_seguro_asigancion en CLIE_DetalleSeguro cuando la solictud de cr dito ya tiene asignada un id_producto.
-- Alter Date:  <31/12/2021> <Roberto Chac n> [Se agrega UDT de Tu Hogar Con Conserva]
--Alter Date: 22/04/2022 Fabian Garcia se separo la latitud y longitud
-- =============================================
  BEGIN TRY
    BEGIN TRAN Tran_RegActSolicitudCliente
    --Variables Solicitud.
    DECLARE @idSolicitud INT
           ,@idClienteSolicitud INT
           ,@idOficialCreditoSolicitud INT
           ,@idProducto INT
           ,@idDisposicion INT
           ,@montoTotalSolicitado MONEY
           ,@montoTotalAutorizado MONEY
           ,@periodicidad VARCHAR(15)
           ,@plazo INT
           ,@estatusSolicitud CHAR(30)
           ,@subEstatusSolicitud CHAR(25)
           ,@fechaPrimerPago DATE
           ,@fechaEntrega DATE
           ,@medioDesembolso CHAR(3)
           ,@garantiaLiquida INT
           ,@fechaCreacion DATE
           ,@idOficinaSollicitud INT
           ,@garantia_liquida_financiable BIT
           ,@id_producto_maestro INT
           ,@tasa_anual DECIMAL(18, 2)
		   ,@id_tuhogar INT;

    --Variables de Cliente.		  
    DECLARE @idCliente INT
           ,@ciclo INT
           ,@cicloIndividual INT
           ,@estatusCliente CHAR(20)
           ,@subEstatusCliente CHAR(25)
           ,@idOficialCreditoCliente INT
           ,@idOficinaCliente INT
           ,@tipoCliente INT;

    --Variables de Grupo.
    DECLARE @idClienteGrupo INT
           ,@nombre VARCHAR(150)
           ,@idDireccionGrupo INT
           ,@reunionDia CHAR(10)
           ,@reunionHora CHAR(10);

    --Variables Direccion.
    DECLARE @idDireccion INT
           ,@calle VARCHAR(150)
           ,@pais INT
           ,@estado INT
           ,@municipio INT
           ,@localidad INT
           ,@colonia INT
           ,@referencia VARCHAR(150)
           ,@numeroExterior VARCHAR(15)
           ,@numeroInterior VARCHAR(15)
           ,@vialidad INT;

    --Variables PrestamoMonto.	
    DECLARE @idIndividual INT
           ,@idSolicitudPrestamoMonto INT
           ,@idPersona INT
           ,@estatus CHAR(30)
           ,@subEstatus CHAR(25)
           ,@cargo CHAR(15)
           ,@montoSolicitado MONEY
           ,@montoSugerido MONEY
           ,@montoAutorizado MONEY
           ,@econIdActividadEconomica INT
           ,@motivo INT
           ,@autorizado INT
           ,@enSolicitud INT
           ,@idCataMedioDesembolso INT
           ,@monto_garantia_financiable DECIMAL(18, 2);

    --Variables SPLD
    DECLARE @IdConfiguracion INT
    DECLARE @MontoMaximoCredito MONEY
    DECLARE @ValorUDI MONEY
    DECLARE @id_prestamo_monto INT
    DECLARE @cambio_perfil BIT
    DECLARE @Dato_SPLD_Datos_Cliente AS TABLE (
      id_catalogo_spld_datos_cliente INT
    )

    --Nuevas variables declaradas para Historial SPLD_HistorialSociaPerfilRiesgo
    DECLARE @perfilActual VARCHAR(100) = ''
           ,@nombreSocia VARCHAR(100) = ''
           ,@apellidoMaterno VARCHAR(60) = ''
           ,@apellidoPaterno VARCHAR(60) = ''
           ,@IdConfiguracionDetalle INT = 0
           ,@nombre_registro VARCHAR(250) = ''
           ,@TipoPersona VARCHAR(100) = ''
           ,@etiquetaConfiguracion VARCHAR(50) = '';

    -- Nuevas variables para Microcredito
    DECLARE @id_asignacion_seguro_UDT INT = 0
           ,@nombre_beneficiario VARCHAR(500) = ''
           ,@parentesco VARCHAR(200) = ''
           ,@costo_seguro MONEY = 0.00
           ,@incluye_saldo_deudor BIT;
    --Variables para evaluaci n de Criterio PLD de Pa s
    DECLARE @id_pais_nacimiento INT = 0
           ,@id_persona INT = 0
           ,@id_pais_domicilio INT = 0
           ,@aplica_regimen_fiscal_preferente BIT = 0
           ,@aplica_medidas_deficientes_pld_ft BIT = 0
           ,@no_tiene_medidas_pld_ft BIT = 0
           ,@pais_spld VARCHAR(200)
           ,@generar_reporte BIT = 0
           ,@evaluar_criterio_pld_ft BIT = 0
           ,@mensaje VARCHAR(MAX) = ''
    DECLARE @SPLD_Pais AS TABLE (
      id_pais INT
     ,etiqueta VARCHAR(200)
     ,aplica_regimen_fiscal_preferente BIT
     ,aplica_medidas_deficientes_pld_ft BIT
     ,no_tiene_medidas_pld_ft BIT
    )
    DECLARE @ResultadoOperacion TABLE (
      id_registro INT
     ,tipo VARCHAR(50)
     ,resultado VARCHAR(50)
     ,mensaje VARCHAR(800)
     ,string_auxiliar VARCHAR(250)
     ,int_auxiliar INT
    )
    DECLARE @DATOSReporteCNBV UDT_SPLD_ReporteCNBV

    DECLARE @ResultEvaluacionMatriz AS TABLE (
      id_solicitud_prestamo_monto INT
     ,total_nivel_riesgo DECIMAL(18, 2)
     ,perfil_evaluacion VARCHAR(50)
     ,comentario VARCHAR(MAX)
    )

    --Variables Referencias Personales.
    DECLARE @idReferencia INT
    --DECLARAMOS LOS UDT
    DECLARE @fecha_garatiaFinanciable DATETIME;
    SET @fecha_garatiaFinanciable = GETDATE();
    DECLARE @UDT_detalle_socias UTD_FinanciamientoGarantiaDetalle;
    DECLARE @UDT_detalle_socias_cancelacion UTD_FinanciamientoGarantiaDetalle;

	
	DECLARE @perfil_evaluacion VARCHAR(20)

    --Obtenemos los datos de la solicitud.
    SELECT
      @idSolicitud = id
     ,@idClienteSolicitud = id_cliente
     ,@idOficialCreditoSolicitud = id_oficial
     ,@idProducto = id_producto
     ,@idDisposicion = id_disposicion
     ,@montoTotalSolicitado = monto_solicitado
     ,@montoTotalAutorizado = monto_autorizado
     ,@periodicidad = periodicidad
     ,@plazo = plazo
     ,@estatusSolicitud = estatus
     ,@subEstatusSolicitud = sub_estatus
     ,@fechaPrimerPago = fecha_primer_pago
     ,@fechaEntrega = fecha_entrega
     ,@medioDesembolso = medio_desembolso
     ,@garantiaLiquida = garantia_liquida
     ,@idOficinaSollicitud = id_oficina
     ,@garantia_liquida_financiable = garantia_liquida_financiable
     ,@id_producto_maestro = id_producto_maestro
     ,@tasa_anual = tasa_anual
    FROM @tablaSolicitud;

    --Obtnemos los datos del Cliente.
    SELECT
      @idCliente = id
     ,@ciclo = ciclo
     ,@estatusCliente = estatus
     ,@subEstatusCliente = sub_estatus
     ,@idOficialCreditoCliente = id_oficial_credito
     ,@idOficinaCliente = id_oficina
     ,@tipoCliente = tipo_cliente
    FROM @tablaCliente

    --Obtenemos los datos del Grupo.
    SELECT
      @idClienteGrupo = id_cliente
     ,@nombre = nombre
     ,@idDireccionGrupo = id_direccion
     ,@reunionDia = reunion_dia
     ,@reunionHora = reunion_hora
    FROM @tablaGrupo;

    --Obtenemos los datos de Direcci n.
    SELECT
      @idDireccion = id
     ,@calle = calle
     ,@pais = pais
     ,@estado = estado
     ,@municipio = municipio
     ,@localidad = localidad
     ,@colonia = colonia
     ,@referencia = referencia
     ,@numeroExterior = numero_exterior
     ,@numeroInterior = numero_interior
     ,@vialidad = vialidad
    FROM @tablaDireccion;

    IF NOT EXISTS (SELECT
          *
        FROM OTOR_SolicitudPrestamos
        WHERE (OTOR_SolicitudPrestamos.id = @idSolicitud
        AND estatus = 'ACEPTADO'
        AND sub_estatus = 'AUTORIZADO')
        OR (OTOR_SolicitudPrestamos.id = @idSolicitud
        AND estatus = 'ACEPTADO'
        AND sub_estatus = 'PRESTAMO ACTIVO'))
    BEGIN


      --Trabajando con la direccion.
      IF (@idDireccion = 0)
      BEGIN
        IF ((SELECT
              COUNT(*)
            FROM CLIE_Grupos
            WHERE CLIE_Grupos.id_cliente = @idCliente)
          = 0)
        BEGIN
          INSERT INTO CONT_Direcciones (direccion, pais, estado, municipio, localidad, colonia,
          referencia, numero_exterior, numero_interior, vialidad, creado_por, modificado_por)
            VALUES (@calle, 1, @estado, @municipio, @localidad, @colonia, @referencia, @numeroExterior, @numeroInterior, @vialidad, @idUsuario, @idUsuario)
          SELECT
            @idDireccion = @@IDENTITY;
        END
      END
      ELSE
      BEGIN
        UPDATE CONT_Direcciones
        SET direccion = @calle
           ,pais = 1
           ,estado = @estado
           ,municipio = @municipio
           ,localidad = @localidad
           ,colonia = @colonia
           ,referencia = @referencia
           ,numero_exterior = @numeroExterior
           ,numero_interior = @numeroInterior
           ,modificado_por = @idUsuario
           ,vialidad = @vialidad
        WHERE CONT_Direcciones.id = @idDireccion;

      END

      --Trabajando con el grupo.
      IF (@idClienteGrupo = 0) --Grupo Nuevo.
      BEGIN
        IF ((SELECT
              COUNT(*)
            FROM CLIE_Grupos
            WHERE CLIE_Grupos.id_cliente = @idCliente)
          = 0)
        BEGIN
          --Creando Grupo
          EXEC spInsGrupo @idCliente
                         ,@nombre
                         ,@idDireccion
                         ,@reunionDia
                         ,@reunionHora;

          UPDATE OTOR_SolicitudPrestamos
          SET estatus = 'TRAMITE'
             ,sub_estatus = 'NUEVO TRAMITE'
          WHERE OTOR_SolicitudPrestamos.id = @idSolicitud;
        END
      END
      ELSE
      BEGIN
        UPDATE CLIE_Grupos
        SET nombre = @nombre
           ,reunion_dia = @reunionDia
           ,reunion_hora = @reunionHora
        WHERE CLIE_Grupos.id_cliente = @idCliente;
      END

      --Corroboramos que realmente vienen medios mixtos
      IF (@medioDesembolso = 'MXO')
      BEGIN
        SET @idCataMedioDesembolso = (SELECT TOP (1)
            id_cata_medio_desembolso
          FROM @tablaPrestamoMonto)

        IF ((SELECT
              COUNT(*)
            FROM @tablaPrestamoMonto)
          = (SELECT
              COUNT(*)
            FROM @tablaPrestamoMonto
            WHERE id_cata_medio_desembolso = @idCataMedioDesembolso)
          )
        BEGIN
          SELECT
            @medioDesembolso = CATA_MedioDesembolso.clave
          FROM CATA_MedioDesembolso
          WHERE CATA_MedioDesembolso.id = @idCataMedioDesembolso;
        END

        SET @idCataMedioDesembolso = 0;
      END

      --Administraci n de Garant as Prendarias
      DECLARE @tResultado TABLE (
        id INT
       ,tipo_garantia VARCHAR(50)
       ,descripcion TEXT
       ,valor_estimado MONEY
       ,id_archivo INT
       ,archivo TEXT
       ,extension VARCHAR(12)
       ,tipo VARCHAR(50)
      );

      DECLARE @tResultadoGP TABLE (
        id_garantia INT
       ,tipo_garantia VARCHAR(50)
       ,id_archivo INT
       ,archivo TEXT
       ,extension VARCHAR(12)
       ,tipo VARCHAR(50)
      );

      --Eliminar garant as prendarias eliminadas en el cliente
      UPDATE ogp
      SET ogp.activo = 0
         ,ogp.modificado_por = @idUsuario
         ,ogp.fecha_modificacion = GETDATE()
      FROM OTOR_GarantiaPrendarias ogp
      INNER JOIN OTOR_Garantias og
        ON ogp.id_garantia = og.id
      LEFT JOIN @garantias_prendarias UDT
        ON og.id = UDT.id
      WHERE og.tipo_garantia = 'PRENDARIA'
      AND ogp.activo = 1
      AND og.id_cliente = @idCliente
      AND og.id_solicitud_prestamo = @idSolicitud
      AND UDT.id IS NULL;

      -- Insertar o Actualizar garant as
      DELETE FROM @tResultado;
      DELETE FROM @tResultadoGP;

      MERGE OTOR_Garantias
      USING (SELECT
          UDT.id
         ,UDT.id_cliente
         ,UDT.id_contrato
         ,UDT.id_solicitud_prestamo
         ,UDT.tipo_garantia
         ,UDT.descripcion
         ,UDT.valor_estimado
         ,UDT.id_archivo
         ,UDT.archivo
         ,UDT.extension
        FROM @garantias_prendarias UDT) AS UDT
      ON OTOR_Garantias.id = UDT.id
      WHEN MATCHED
        THEN UPDATE
          SET OTOR_Garantias.id_cliente = UDT.id_cliente
             ,OTOR_Garantias.id_contrato = UDT.id_contrato
             ,OTOR_Garantias.id_solicitud_prestamo = UDT.id_solicitud_prestamo
             ,OTOR_Garantias.tipo_garantia = UDT.tipo_garantia
      WHEN NOT MATCHED
        THEN INSERT (id_cliente, id_contrato, id_solicitud_prestamo, tipo_garantia)
            VALUES (id_cliente, id_contrato, id_solicitud_prestamo, tipo_garantia)
      OUTPUT INSERTED.id
            ,UDT.tipo_garantia
            ,UDT.descripcion
            ,UDT.valor_estimado
            ,UDT.id_archivo
            ,UDT.archivo
            ,UDT.extension
            ,$ACTION
             INTO @tResultado;

      MERGE OTOR_GarantiaPrendarias
      USING (SELECT
          UDT.id AS id_garantia
         ,UDT.tipo_garantia
         ,UDT.descripcion
         ,UDT.valor_estimado
         ,UDT.id_archivo
         ,UDT.archivo
         ,UDT.extension
        FROM @tResultado UDT) AS UDT
      ON OTOR_GarantiaPrendarias.id_garantia = UDT.id_garantia
      WHEN MATCHED
        THEN UPDATE
          SET OTOR_GarantiaPrendarias.descripcion = UDT.descripcion
             ,OTOR_GarantiaPrendarias.valor_estimado = UDT.valor_estimado
             ,OTOR_GarantiaPrendarias.tipo_garantia = UDT.tipo_garantia
             ,OTOR_GarantiaPrendarias.modificado_por = @idUsuario
             ,OTOR_GarantiaPrendarias.fecha_modificacion = GETDATE()
      WHEN NOT MATCHED
        THEN INSERT (id_garantia, descripcion, valor_estimado, tipo_garantia, creado_por, fecha_creacion, activo)
            VALUES (id_garantia, descripcion, valor_estimado, tipo_garantia, @idUsuario, GETDATE(), 1)
      OUTPUT INSERTED.id_garantia
            ,UDT.tipo_garantia
            ,UDT.id_archivo	
            ,UDT.archivo
            ,UDT.extension
            ,$ACTION
             INTO @tResultadoGP;

      SELECT
        ISNULL(@idCliente, 0)
       ,ISNULL(@idSolicitud, 0)
       ,ISNULL(@nombre, '')
       ,ISNULL(@reunionDia, '')
       ,ISNULL(@reunionHora, 0)

      SELECT
        *
      FROM @tResultadoGP;

	  --Administrar Datos de Tu Hogar Conserva

	  MERGE OTOR_TuHogarConConserva
      USING (SELECT
          UDT_TH.id AS id
         ,UDT_TH.id_solicitud_prestamo
         ,UDT_TH.domicilio_actual
         ,UDT_TH.latitud
		 ,UDT_TH.longitud
         ,UDT_TH.id_tipo_obra_financiar
         ,UDT_TH.tipo_mejora
         ,UDT_TH.total_score
		 ,UDT_TH.id_color_semaforo_fico_score
		 ,UDT_TH.id_origen_ingresos
		 ,UDT_TH.activo
        FROM @tabla_TuHogarConConserva UDT_TH) AS UDT
      ON OTOR_TuHogarConConserva.id = UDT.id AND OTOR_TuHogarConConserva.id_solicitud_prestamo=UDT.id_solicitud_prestamo AND OTOR_TuHogarConConserva.activo=1
      WHEN MATCHED
        THEN UPDATE
          SET OTOR_TuHogarConConserva.id_solicitud_prestamo = UDT.id_solicitud_prestamo
             ,OTOR_TuHogarConConserva.domicilio_actual = UDT.domicilio_actual
             ,OTOR_TuHogarConConserva.geolocalizacion_domicilio = GEOGRAPHY::Point(
							CASE WHEN ISNUMERIC(UDT.longitud) = 1
							THEN
								CONVERT(FLOAT,REPLACE(UDT.longitud, ',', '.'))
							ELSE
								0
							END
							,
							CASE WHEN ISNUMERIC(UDT.latitud) = 1
							THEN
								CONVERT(FLOAT,REPLACE(UDT.latitud, ',', '.'))
							ELSE
								0
							END
							,4326)
			 ,OTOR_TuHogarConConserva.id_tipo_obra_financiar = UDT.id_tipo_obra_financiar
			 ,OTOR_TuHogarConConserva.tipo_mejora = UDT.tipo_mejora
			 ,OTOR_TuHogarConConserva.total_score = UDT.total_score
			 ,OTOR_TuHogarConConserva.id_color_semaforo_fico_score = UDT.id_color_semaforo_fico_score
			 ,OTOR_TuHogarConConserva.id_origen_ingresos = UDT.id_origen_ingresos
             ,OTOR_TuHogarConConserva.modificado_por = @idUsuario
             ,OTOR_TuHogarConConserva.fecha_revision = GETDATE()
			 ,OTOR_TuHogarConConserva.activo=UDT.activo
      WHEN NOT MATCHED
        THEN INSERT (id_solicitud_prestamo, domicilio_actual, geolocalizacion_domicilio, id_tipo_obra_financiar, tipo_mejora, total_score, id_color_semaforo_fico_score, id_origen_ingresos, creado_por, fecha_creacion,modificado_por,fecha_revision, activo)
            VALUES (id_solicitud_prestamo, domicilio_actual, GEOGRAPHY::Point(
							CASE WHEN ISNUMERIC(UDT.longitud) = 1
							THEN
								CONVERT(FLOAT,REPLACE(UDT.longitud, ',', '.'))
							ELSE
								0
							END
							,
							CASE WHEN ISNUMERIC(UDT.latitud) = 1
							THEN
								CONVERT(FLOAT,REPLACE(UDT.latitud, ',', '.'))
							ELSE
								0
							END
							,4326), id_tipo_obra_financiar, tipo_mejora, total_score, id_color_semaforo_fico_score, id_origen_ingresos, @idUsuario, GETDATE(),@idUsuario,GETDATE(), 1);
		SELECT @id_tuhogar = SCOPE_IDENTITY();
		
	  --TU HOGAR CON CONSERVA COACREDITADO

	  IF(ISNULL(@id_tuhogar,0) = 0)
	  BEGIN
		SELECT @id_tuhogar = ISNULL(id,0) FROM @tabla_TuHogarConConserva
	  END

		 MERGE OTOR_TuHogarConConservaCoacreditado
      USING (SELECT
			UDT_THC.id,
          UDT_THC.id_tuhogar_conserva
		 ,UDT_THC.id_coacreditado
         ,UDT_THC.total_score_coacreditado
		 ,UDT_THC.id_color_semaforo_fico_score_coacreditado
		 ,UDT_THC.activo
        FROM @tabla_TuHogarConConservaCoacreditado UDT_THC) AS UDTCH
      ON OTOR_TuHogarConConservaCoacreditado.id = UDTCH.id AND OTOR_TuHogarConConservaCoacreditado.id_tuhogar_conserva = UDTCH.id_tuhogar_conserva 
	  AND  OTOR_TuHogarConConservaCoacreditado.id_persona=UDTCH.id_coacreditado AND 
	  OTOR_TuHogarConConservaCoacreditado.activo=1
      WHEN MATCHED
        THEN UPDATE
          SET OTOR_TuHogarConConservaCoacreditado.id_tuhogar_conserva = UDTCH.id_tuhogar_conserva
			 ,OTOR_TuHogarConConservaCoacreditado.id_persona = UDTCH.id_coacreditado
             ,OTOR_TuHogarConConservaCoacreditado.total_score = UDTCH.total_score_coacreditado
			 ,OTOR_TuHogarConConservaCoacreditado.id_color_semaforo_fico_score = UDTCH.id_color_semaforo_fico_score_coacreditado
             ,OTOR_TuHogarConConservaCoacreditado.modificado_por = @idUsuario
             ,OTOR_TuHogarConConservaCoacreditado.fecha_revision = GETDATE()
			 ,OTOR_TuHogarConConservaCoacreditado.activo=UDTCH.activo
      WHEN NOT MATCHED
        THEN INSERT (id_tuhogar_conserva , id_persona, total_score, id_color_semaforo_fico_score, creado_por, fecha_creacion,modificado_por,fecha_revision, activo)
            VALUES (@id_tuhogar, id_coacreditado, total_score_coacreditado, id_color_semaforo_fico_score_coacreditado, @idUsuario, GETDATE(),@idUsuario, GETDATE(), 1);
		

      --Referencias Personales
      --Insertar/Actualizar Relaciones Personales
      --Insertar
      INSERT INTO CLIE_R_I (id_cliente, id_referencia, ciclo, parentesco, tipo_relacion, tipo, eliminado, delete_motivo, antiguedad, id_conyugue, id_empleado, creado_por, fecha_creacion, modificado_por, fecha_revision)
        SELECT
          @idCliente
         ,id_referencia -- Es el id_personas de la vwCONT_Personas
         ,0
         ,parentesco
         ,tipo_relacion
         ,tipo
         ,eliminado
         ,'NE'
         ,GETDATE()
         ,0
         ,id_empleado
         ,@idUsuario
         ,GETDATE()
         ,@idUsuario
         ,GETDATE()
        FROM @referencias_personales tReferencias
        WHERE tReferencias.id = 0;

      --Actualizar
      SELECT
        @idReferencia = MIN(id)
      FROM @referencias_personales
      WHERE id <> 0;

      WHILE (@idReferencia IS NOT NULL)
      BEGIN
      UPDATE CLIE_R_I
      SET id_cliente = @idCliente
         ,id_referencia = tReferencias.id_referencia
         ,parentesco = tReferencias.parentesco
         ,tipo_relacion = tReferencias.tipo_relacion
         ,tipo = tReferencias.tipo
         ,eliminado = tReferencias.eliminado
         ,id_empleado = tReferencias.eliminado
         ,modificado_por = @idUsuario
         ,fecha_revision = GETDATE()
      FROM @referencias_personales tReferencias
      WHERE CLIE_R_I.id = @idReferencia
      AND tReferencias.id = @idReferencia;

      SELECT
        @idReferencia = MIN(id)
      FROM @referencias_personales
      WHERE id > @idReferencia;
      END


      UPDATE OTOR_SolicitudPrestamos
      SET id_oficial = @idOficialCreditoCliente
         ,id_producto = @idProducto
         ,id_cotizacion = @idProducto
         ,id_disposicion = @idDisposicion
         ,monto_total_solicitado = @montoTotalSolicitado
         ,monto_financial = @montoTotalSolicitado
         ,monto_financiar = @montoTotalSolicitado
         ,monto_total_autorizado = @montoTotalAutorizado
         ,periodicidad = @periodicidad
         ,plazo = @plazo
         ,fecha_primer_pago = @fechaPrimerPago
         ,fecha_entrega = @fechaEntrega
         ,medio_desembolso = @medioDesembolso
         ,garantia_liquida = @garantiaLiquida
         ,estatus = @estatusSolicitud
         ,sub_estatus = @subEstatusSolicitud
         ,id_producto_maestro = @id_producto_maestro
         ,garantia_liquida_financiable = @garantia_liquida_financiable
         ,tasa_anual = @tasa_anual
      WHERE OTOR_SolicitudPrestamos.id = @idSolicitud;

      --Actualizamos al registro de CLIE_Clientes.
      UPDATE CLIE_Clientes
      SET id_oficial_credito = @idOficialCreditoCliente
         ,fecha_revision = GETDATE()
         ,modificado_por = @idUsuario
      WHERE CLIE_Clientes.id = @idCliente;

      IF (@estatusSolicitud = 'ACEPTADO'
        AND @subEstatusSolicitud = 'AUTORIZADO')
      BEGIN
        UPDATE OTOR_SolicitudPrestamos
        SET autorizado_por = @idUsuario
           ,fecha_autorizacion = CAST(GETDATE() AS DATE)
        WHERE OTOR_SolicitudPrestamos.id = @idSolicitud;

        SELECT
          @evaluar_criterio_pld_ft = ISNULL(CAST(valor AS BIT), CAST(0 AS BIT))
        FROM SPLD_Configuracion
        WHERE codigo = 'PLD_FT'
        AND estatus_registro = 'ACTIVO'

      END

      SELECT
        @IdConfiguracion = ISNULL(id, 0)
       ,@MontoMaximoCredito = ISNULL(valor, 0)
      FROM SPLD_Configuracion
      WHERE codigo = 'MATRIZ'
      AND estatus_registro = 'ACTIVO'

      SELECT
        @ValorUDI = dbo.ObtenerTipoCambio('UDI');

      SET @MontoMaximoCredito = @MontoMaximoCredito * @ValorUDI
      ----Trabajando con los datos del PrestamoMonto.
      SET NOCOUNT ON;
      DECLARE cursorSolicitudDetalle CURSOR FOR SELECT
        id_individual
       ,id_solicitud
       ,id_persona
       ,estatus
       ,cargo
       ,monto_solicitado
       ,monto_sugerido
       ,monto_autorizado
       ,econ_id_actividad_economica
       ,motivo
       ,sub_estatus
       ,id_cata_medio_desembolso
       ,monto_garantia_financiable
      FROM @tablaPrestamoMonto
      OPEN cursorSolicitudDetalle
      FETCH NEXT FROM cursorSolicitudDetalle
      INTO @idIndividual, @idSolicitudPrestamoMonto, @idPersona, @estatus, @cargo, @montoSolicitado,
      @montoSugerido, @montoAutorizado, @econIdActividadEconomica, @motivo, @subEstatus, @idCataMedioDesembolso, @monto_garantia_financiable
      WHILE @@FETCH_STATUS = 0
      BEGIN
      --Reset de variables para evaluaci n de Criterio PLD de Pa s
      SET @id_pais_nacimiento = 0
      SET @id_persona = 0
      SET @id_pais_domicilio = 0
      SET @aplica_regimen_fiscal_preferente = 0
      SET @aplica_medidas_deficientes_pld_ft = 0
      SET @no_tiene_medidas_pld_ft = 0
      SET @pais_spld = ''
      SET @generar_reporte = 0
      SET @mensaje = ''
      DELETE FROM @SPLD_Pais
      DELETE FROM @ResultadoOperacion
      DELETE FROM @DATOSReporteCNBV
      DELETE FROM @ResultEvaluacionMatriz
      SET @perfilActual = ''
      DECLARE @perfilSolicitudIndividual VARCHAR(25) = ''

      -- RESETEANDO VARIABLES SEGURO 
      SET @id_asignacion_seguro_UDT = 0;
      SET @nombre_beneficiario = '';
      SET @parentesco = '';
      SET @costo_seguro = 0.00;
      SET @incluye_saldo_deudor = 0;



	   IF(@idProducto=0 OR @idProducto IS NULL)
	   BEGIN
		  --OBTENIENDO LOS VALORES DE LA TABLA
		  SELECT
			@id_asignacion_seguro_UDT = id_seguro_asignacion
		   ,@nombre_beneficiario = nombre_beneficiario
		   ,@parentesco = parentesco
		   ,@costo_seguro = costo_seguro
		   ,@incluye_saldo_deudor = incluye_saldo_deudor
		  FROM @seguro
		  WHERE id_individual = @idIndividual
		  AND id_solicitud = @idSolicitud --AND activo = 1
	  END
	  ELSE IF((SELECT COUNT(*) FROM @seguro)>0 AND @idProducto>0)
	  BEGIN
		
		SELECT @id_asignacion_seguro_UDT=CATA_ProductoSeguro.id FROM CATA_ProductoSeguro WHERE id_producto=@idProducto AND activo=1

		--OBTENIENDO LOS VALORES DE LA TABLA
		  SELECT
		   @nombre_beneficiario = nombre_beneficiario
		   ,@parentesco = parentesco
		   ,@costo_seguro = costo_seguro
		   ,@incluye_saldo_deudor = incluye_saldo_deudor
		  FROM @seguro
		  WHERE id_individual = @idIndividual
		  AND id_solicitud = @idSolicitud 
	  END

      IF (@idSolicitudPrestamoMonto > 0)
      BEGIN
        SET @autorizado = 0;

        ---Consulta para obtener los datos de cada socia					
        SELECT
          @nombreSocia = CONT_Personas.nombre
         ,@apellidoPaterno = CONT_Personas.apellido_paterno
         ,@apellidoMaterno = CONT_Personas.apellido_materno
        FROM OTOR_SolicitudPrestamoMonto
        INNER JOIN CLIE_Individual
          ON CLIE_Individual.id_cliente = OTOR_SolicitudPrestamoMonto.id_individual
        INNER JOIN CONT_Personas
          ON CONT_Personas.id = CLIE_Individual.id_persona
        WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
        AND CLIE_Individual.id_cliente = @idIndividual

        SELECT
          @id_prestamo_monto = ISNULL(OTOR_SolicitudPrestamoMonto.id, 0)
        FROM OTOR_SolicitudPrestamoMonto
        WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
        AND OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud


        IF (@estatus = 'TRAMITE'
          AND @subEstatus = 'POR AUTORIZAR')
        BEGIN
          ------------------------------------------------------------------EVALUACION DE LA MATRIZ DE PERFIL DE RIESGO SPLD---------------------------------------------------------------------------------
          SET @cambio_perfil = CAST(0 AS BIT)

          SET @etiquetaConfiguracion = '';
          ---Consulta para obtener los datos de cada socia					
          SELECT
            @nombreSocia = CONT_Personas.nombre
           ,@apellidoPaterno = CONT_Personas.apellido_paterno
           ,@apellidoMaterno = CONT_Personas.apellido_materno
          FROM OTOR_SolicitudPrestamoMonto
          INNER JOIN CLIE_Individual
            ON CLIE_Individual.id_cliente = OTOR_SolicitudPrestamoMonto.id_individual
          INNER JOIN CONT_Personas
            ON CONT_Personas.id = CLIE_Individual.id_persona
          WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
          AND CLIE_Individual.id_cliente = @idIndividual

          SELECT
            @perfilActual = LTRIM(RTRIM(perfil_riesgo))
          FROM OTOR_SolicitudPrestamoMonto
          WHERE id = @id_prestamo_monto


        ------EVALUACION DE LA NUEVA MATRIZ
        INSERT INTO @ResultEvaluacionMatriz		  
        EXEC MEBR_EvaluarMatriz @id_persona,@idIndividual,@id_prestamo_monto,@idSolicitud,@montoSolicitado,'evaluacion_por_monto_enviado'
		SET @perfil_evaluacion = 'BAJO RIESGO'
		SELECT @perfil_evaluacion = CAST(COALESCE(LTRIM(RTRIM(perfil_evaluacion)), 'BAJO RIESGO') AS VARCHAR(20)) FROM @ResultEvaluacionMatriz
		IF (@perfilActual <> @perfil_evaluacion OR @perfil_evaluacion = 'ALTO RIESGO')
		BEGIN
			UPDATE OTOR_SolicitudPrestamoMonto
			SET OTOR_SolicitudPrestamoMonto.perfil_riesgo = @perfil_evaluacion
			WHERE OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto
			AND id_individual = @idIndividual
			INSERT INTO SPLD_HistorialSociaPerfilRiesgo (id_solicitud_prestamo_monto, nombre, apellido_paterno, apellido_materno, perfil_anterior, perfil_actual, comentario, forma, creado_por, fecha_creacion, estatus_registro)
			SELECT @id_prestamo_monto,@nombreSocia,@apellidoPaterno,@apellidoMaterno,@perfilActual,perfil_evaluacion,comentario,'AUTOMATICO',@idUsuario,GETDATE(),'ACTIVO'
			FROM @ResultEvaluacionMatriz
			SET @cambio_perfil = CAST(1 AS BIT)
		END        

        --------------------------
        --IF(@cambio_perfil=CAST(0 AS BIT))
        --BEGIN
        --	IF NOT EXISTS(
        --		SELECT TOP(1) * FROM SPLD_DatosCliente 
        --		WHERE SPLD_DatosCliente.id_prestamo_monto=@id_prestamo_monto 
        --		AND SPLD_DatosCliente.id_cliente=@idIndividual
        --		AND (SPLD_DatosCliente.es_pep = 1
        --		OR SPLD_DatosCliente.es_persona_prohibida= 1 ) 
        --		AND SPLD_DatosCliente.estatus_registro='ACTIVO' ORDER BY SPLD_DatosCliente.id DESC 
        --		)
        --	BEGIN
        --		SELECT @perfilActual = LTRIM(RTRIM(perfil_riesgo)) FROM OTOR_SolicitudPrestamoMonto where id = @id_prestamo_monto 
        --		IF(@perfilActual <> 'BAJO RIESGO')
        --		BEGIN
        --			UPDATE OTOR_SolicitudPrestamoMonto SET OTOR_SolicitudPrestamoMonto.perfil_riesgo='BAJO RIESGO' WHERE OTOR_SolicitudPrestamoMonto.id=@id_prestamo_monto

        --			INSERT INTO SPLD_HistorialSociaPerfilRiesgo(id_solicitud_prestamo_monto,nombre,apellido_paterno,apellido_materno,perfil_anterior,perfil_actual,comentario,forma,creado_por,fecha_creacion,estatus_registro)
        --  							SELECT @id_prestamo_monto,@nombreSocia,@apellidoPaterno,@apellidoMaterno,@perfilActual,'BAJO RIESGO','El cliente estaba catalogado como Persona Pol ticamente Expuesta y/o Persona Bloqueada,con un valor de nivel de riesgo ALTO.Por el Monto en Pesos de: $ '+ CAST(@montoSugerido AS VARCHAR),'AUTOMATICO',@idUsuario,GETDATE(),'ACTIVO'
        --		END
        --	END

        --END		
        END
        ----------------------------------------------------------------TERMINA EVALUACION DE LA MATRIZ DE PERFIL DE RIESGO---------------------------------------------------------------

        IF (@estatus = 'ACEPTADO'
          AND @subEstatus = 'AUTORIZADO')
        BEGIN
          DECLARE @PerfilRiesgo VARCHAR(30)

          SELECT
            @PerfilRiesgo = ISNULL(OTOR_SolicitudPrestamoMonto.perfil_riesgo, '')
          FROM OTOR_SolicitudPrestamoMonto
          WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
          AND OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto

          /*IF(RTRIM(LTRIM(@PerfilRiesgo))='ALTO RIESGO')
					BEGIN*/
          INSERT INTO SPLD_HistorialAutorizacionRiesgo
            SELECT
              OTOR_SolicitudPrestamoMonto.id
             ,CONT_Personas.id
             ,OTOR_SolicitudPrestamoMonto.id_individual
             ,@idUsuario
             ,GETDATE()
             ,@idUsuario
             ,GETDATE()
             ,'ACTIVO'
             ,@PerfilRiesgo
            FROM OTOR_SolicitudPrestamoMonto
            INNER JOIN CLIE_Individual
              ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
            INNER JOIN CONT_Personas
              ON CLIE_Individual.id_persona = CONT_Personas.id
            WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
            AND OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto
          --END

          ----FORZAMOS LA ACTUALIZACION DEL PERFIL DE RIESGO
          SELECT
            @perfilSolicitudIndividual = perfil_riesgo
          FROM OTOR_SolicitudPrestamoMonto
          WHERE id_individual = @idIndividual
          AND id = @id_prestamo_monto

          IF (LTRIM(RTRIM(@perfilRiesgo)) = 'ALTO RIESGO')
          BEGIN
            IF (@perfilSolicitudIndividual = 'BAJO RIESGO')
            BEGIN
              UPDATE OTOR_SolicitudPrestamoMonto
              SET perfil_riesgo = 'ALTO RIESGO'
              WHERE id_individual = @idIndividual
              AND id = @id_prestamo_monto
            END
          END

          -------------------------------------------------EVALUAR CRITERIO DE PA S PARA REPORTE INUSUAL------------------------------------------------------------
          IF (@evaluar_criterio_pld_ft = 1)
          BEGIN
            /*SELECT  
						@id_persona=ISNULL(SPLD_HistorialAutorizacionRiesgo.id_persona,0)
						FROM SPLD_HistorialAutorizacionRiesgo
						WHERE SPLD_HistorialAutorizacionRiesgo.id_prestamo_monto=@id_prestamo_monto 
						AND SPLD_HistorialAutorizacionRiesgo.estatus_registro='ACTIVO' 
						*/
            SELECT
              @id_persona = Persona.id_persona
            FROM CLIE_Individual
            CROSS APPLY (SELECT TOP (1)
                CONT_Personas.id AS id_persona
              FROM CONT_Personas
              WHERE CONT_Personas.id = CLIE_Individual.id_persona
              ORDER BY CONT_Personas.id DESC) Persona
            WHERE CLIE_Individual.id_cliente = @idIndividual

            SELECT
              @id_pais_nacimiento = ISNULL(CONT_Personas.id_pais_nacimiento, 0)
             ,@id_pais_domicilio = ISNULL(CONT_Direcciones.pais, 0)
            FROM CONT_Personas
            INNER JOIN CONT_Direcciones
              ON CONT_Direcciones.id = CONT_Personas.id_direccion
                AND CONT_Direcciones.estatus_registro = 'ACTIVO'
            WHERE CONT_Personas.id = @id_persona

            INSERT INTO @SPLD_Pais
              SELECT
                id_pais
               ,CATA_pais.etiqueta
               ,aplica_regimen_fiscal_preferente
               ,aplica_medidas_deficientes_pld_ft
               ,no_tiene_medidas_pld_ft
              FROM SPLD_Pais
              INNER JOIN CATA_pais
                ON SPLD_Pais.id_pais = CATA_pais.id
              WHERE SPLD_Pais.id_pais IN (@id_pais_nacimiento, @id_pais_domicilio)
              AND SPLD_Pais.activo = 1

            IF (SELECT
                  COUNT(*)
                FROM @SPLD_Pais
                WHERE id_pais = @id_pais_nacimiento)
              > 0
            BEGIN

              SELECT
                @pais_spld = ISNULL(etiqueta, '')
               ,@aplica_regimen_fiscal_preferente = ISNULL(aplica_regimen_fiscal_preferente, 0)
               ,@aplica_medidas_deficientes_pld_ft = ISNULL(aplica_medidas_deficientes_pld_ft, 0)
               ,@no_tiene_medidas_pld_ft = ISNULL(no_tiene_medidas_pld_ft, 0)
              FROM @SPLD_Pais
              WHERE id_pais = @id_pais_nacimiento

              IF (@aplica_regimen_fiscal_preferente = 1)
              BEGIN
                SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: Aplica R gimen F scal Preferente' + CHAR(13) + CHAR(10)
                SET @generar_reporte = 1
              END
              IF (@aplica_medidas_deficientes_pld_ft = 1)
              BEGIN
                SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: Aplica Medidas Deficientes de PLD/FT' + CHAR(13) + CHAR(10)
                SET @generar_reporte = 1
              END

              IF (@no_tiene_medidas_pld_ft = 1)
              BEGIN
                SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: No Tiene Medidas PLD/FT' + CHAR(13) + CHAR(10)
                SET @generar_reporte = 1
              END

              IF (@generar_reporte = 1)
              BEGIN
                INSERT INTO @DATOSReporteCNBV
                EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA'
                                             ,''
                                             ,''
                                             ,'01/01/1901'
                                             ,'01/01/1901'
                                             ,''
                                             ,@id_persona
                                             ,0
                                             ,0

                UPDATE @DATOSReporteCNBV
                SET id_tipo_reporte = 2
                   ,descripcion_reporte = @mensaje
                   ,monto = @montoAutorizado
                   ,moneda = 'MXN'

                INSERT INTO @ResultadoOperacion
                EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV
                                                       ,'OTOR_registrarActualisarSolicitudGrupoSolidario'
                                                       ,'INSERT_REPORT_AND_CNBV'
                                                       ,@idUsuario
              END
            END

            IF (SELECT
                  COUNT(*)
                FROM @SPLD_Pais
                WHERE id_pais = @id_pais_domicilio)
              > 0
            BEGIN
              SET @aplica_regimen_fiscal_preferente = 0
              SET @aplica_medidas_deficientes_pld_ft = 0
              SET @no_tiene_medidas_pld_ft = 0
              SET @generar_reporte = 0
              SET @pais_spld = ''
              SET @mensaje = ''
              DELETE FROM @DATOSReporteCNBV
              DELETE FROM @ResultadoOperacion

              SELECT
                @pais_spld = ISNULL(etiqueta, '')
               ,@aplica_regimen_fiscal_preferente = ISNULL(aplica_regimen_fiscal_preferente, 0)
               ,@aplica_medidas_deficientes_pld_ft = ISNULL(aplica_medidas_deficientes_pld_ft, 0)
               ,@no_tiene_medidas_pld_ft = ISNULL(no_tiene_medidas_pld_ft, 0)
              FROM @SPLD_Pais
              WHERE id_pais = @id_pais_domicilio

              IF (@aplica_regimen_fiscal_preferente = 1)
              BEGIN
                SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el criterio de PLD: Aplica R gimen F scal Preferente' + CHAR(13) + CHAR(10)
                SET @generar_reporte = 1
              END
              IF (@aplica_medidas_deficientes_pld_ft = 1)
              BEGIN
                SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el siguiente criterio de PLD: Aplica Medidas Deficientes de PLD/FT' + CHAR(13) + CHAR(10)
                SET @generar_reporte = 1
              END

              IF (@no_tiene_medidas_pld_ft = 1)
              BEGIN
                SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el siguiente criterio de PLD: No Tiene Medidas PLD/FT' + CHAR(13) + CHAR(10)
                SET @generar_reporte = 1
              END

              IF (@generar_reporte = 1)
              BEGIN
                INSERT INTO @DATOSReporteCNBV
                EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA'
                                             ,''
                                             ,''
                                             ,'01/01/1901'
                                             ,'01/01/1901'
                                             ,''
                                             ,@id_persona
                                             ,0
                                             ,0

                UPDATE @DATOSReporteCNBV
                SET id_tipo_reporte = 2
                   ,descripcion_reporte = @mensaje
                   ,monto = @montoAutorizado
                   ,moneda = 'MXN'

                INSERT INTO @ResultadoOperacion
                EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV
                                                       ,'OTOR_registrarActualisarSolicitudGrupoSolidario'
                                                       ,'INSERT_REPORT_AND_CNBV'
                                                       ,@idUsuario
              END

            END
          END
          -------------------------------------------------------------------------------------------------------------------------

          SET @autorizado = 1;

        END

        IF ((@estatus = 'RECHAZADO'
          AND @subEstatus = 'CASTIGADO')
          OR (@estatus = 'CANCELADO'
          AND @subEstatus = 'CANCELACION/ABANDONO')
          OR (@estatus = 'RECHAZADO'
          AND @subEstatus = 'RECHAZADO'))
        BEGIN
          IF EXISTS (SELECT
                *
              FROM OTOR_SolicitudPrestamos
              WHERE id = @idSolicitud
              AND garantia_liquida_financiable = 1)
          BEGIN
            INSERT INTO @UDT_detalle_socias_cancelacion
              SELECT
                OTOR_SolicitudPrestamoMonto.id_individual
               ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable AS monto_financiado
              FROM OTOR_SolicitudPrestamoMonto
              WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
              AND id_individual = @idIndividual
              AND autorizado = 1
          END
        END

        UPDATE OTOR_SolicitudPrestamoMonto
        SET cargo = @cargo
           ,monto_solicitado = @montoSolicitado
           ,monto_sugerido = @montoSugerido
           ,monto_autorizado = @montoAutorizado
           ,econ_id_actividad_economica = @econIdActividadEconomica
           ,estatus = @estatus
           ,sub_estatus = @subEstatus
           ,motivo = @motivo
           ,autorizado = @autorizado
           ,id_cata_medio_desembolso = @idCataMedioDesembolso
           ,modificado_por = @idUsuario
           ,monto_garantia_financiable = @monto_garantia_financiable
           ,fecha_revision = GETDATE()
        WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
        AND OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
        AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO';

        -- =========================================================================== Microcreditos ===============================================
        IF NOT EXISTS (SELECT
              *
            FROM CLIE_DetalleSeguro
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1)
        BEGIN
          IF (@id_asignacion_seguro_UDT <> 0)
          BEGIN

            INSERT INTO CLIE_DetalleSeguro (id_solicitud_prestamo, id_individual, id_seguro_asignacion, nombre_beneficiario, parentesco, porcentaje, costo_seguro, incluye_saldo_deudor, creado_por, fecha_creacion, modificado_por, fecha_modificacion, activo)
              VALUES (@idSolicitud, @idIndividual, @id_asignacion_seguro_UDT, @nombre_beneficiario, @parentesco, 100, @costo_seguro, @incluye_saldo_deudor, @idUsuario, GETDATE(), @idUsuario, GETDATE(), 1)

          END
          ELSE
          BEGIN

            DECLARE @id_seguro_asignacion_nuevo INT = 0;

            SELECT TOP 1
              @id_seguro_asignacion_nuevo = CATA_ProductoSeguro.id
            FROM CATA_Productos
            INNER JOIN CATA_ProductoSeguro
              ON CATA_ProductoSeguro.id_producto = CATA_Productos.id
            WHERE CATA_Productos.id = @idProducto

            INSERT INTO CLIE_DetalleSeguro (id_solicitud_prestamo, id_individual, id_seguro_asignacion, nombre_beneficiario, parentesco, porcentaje, costo_seguro, incluye_saldo_deudor, creado_por, fecha_creacion, modificado_por, fecha_modificacion, activo)
              VALUES (@idSolicitud, @idIndividual, @id_seguro_asignacion_nuevo, @nombre_beneficiario, @parentesco, 100, @costo_seguro, @incluye_saldo_deudor, @idUsuario, GETDATE(), @idUsuario, GETDATE(), 1)

          END
        END
        ELSE
        BEGIN
          UPDATE CLIE_DetalleSeguro
          SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
             ,CLIE_DetalleSeguro.nombre_beneficiario = @nombre_beneficiario
             ,CLIE_DetalleSeguro.parentesco = @parentesco
             ,CLIE_DetalleSeguro.modificado_por = @idUsuario
             ,fecha_modificacion = GETDATE()
             ,CLIE_DetalleSeguro.costo_seguro = @costo_seguro
             ,CLIE_DetalleSeguro.incluye_saldo_deudor = @incluye_saldo_deudor
          WHERE id_individual = @idIndividual
          AND id_solicitud_prestamo = @idSolicitud
          AND activo = 1;
        END

        IF (@estatus = 'ACEPTADO'
          AND @subEstatus = 'AUTORIZADO')
        BEGIN
          IF EXISTS (SELECT
                *
              FROM OTOR_SolicitudPrestamos
              WHERE id = @idSolicitud
              AND garantia_liquida_financiable = 1)
          BEGIN
            INSERT INTO @UDT_detalle_socias
              SELECT
                OTOR_SolicitudPrestamoMonto.id_individual
               ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable AS monto_financiado
              FROM OTOR_SolicitudPrestamoMonto
              WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
              AND id_individual = @idIndividual
              AND autorizado = 1
          END

        END

        -- ==============Termina Microcreditos
        IF (@estatus = 'RECHAZADO'
          AND @subEstatus = 'CASTIGADO')
        BEGIN
          UPDATE CLIE_Clientes
          SET sub_estatus = 'CASTIGADO'
             ,CLIE_Clientes.lista_negra = 1
             ,modificado_por = @idUsuario
             ,fecha_revision = GETDATE()
          WHERE CLIE_Clientes.id = @idIndividual;
          -- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
          UPDATE CLIE_DetalleSeguro
          SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
             ,CLIE_DetalleSeguro.modificado_por = @idUsuario
             ,fecha_modificacion = GETDATE()
             ,CLIE_DetalleSeguro.activo = 0
          WHERE id_individual = @idIndividual
          AND id_solicitud_prestamo = @idSolicitud
          AND activo = 1;
        END

        -- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS

        IF (@estatus = 'CANCELADO'
          AND @subEstatus = 'CANCELACION/ABANDONO')
        BEGIN
          UPDATE CLIE_DetalleSeguro
          SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
             ,CLIE_DetalleSeguro.modificado_por = @idUsuario
             ,fecha_modificacion = GETDATE()
             ,CLIE_DetalleSeguro.activo = 0
          WHERE id_individual = @idIndividual
          AND id_solicitud_prestamo = @idSolicitud
          AND activo = 1
        END

        IF (@estatus = 'RECHAZADO'
          AND @subEstatus = 'RECHAZADO')
        BEGIN
          UPDATE CLIE_DetalleSeguro
          SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
             ,CLIE_DetalleSeguro.modificado_por = @idUsuario
             ,fecha_modificacion = GETDATE()
             ,CLIE_DetalleSeguro.activo = 0
          WHERE id_individual = @idIndividual
          AND id_solicitud_prestamo =
          @idSolicitud
          AND activo = 1
        END

      END
      ELSE
      BEGIN
        IF (@econIdActividadEconomica = 0)
        BEGIN
          SELECT
            @econIdActividadEconomica =
            CASE
              WHEN CLIE_Individual.id_actividad_economica IS NULL OR
                CLIE_Individual.id_actividad_economica = 0 THEN ISNULL(CLIE_Individual.econ_id_actividad_economica, 0)
              ELSE CLIE_Individual.id_actividad_economica
            END
          FROM CLIE_Individual
          WHERE CLIE_Individual.id_cliente = @idIndividual;

        END

        --Verificamos si la socia est  en esta solicitud
        SELECT
          @enSolicitud = COUNT(*)
        FROM OTOR_SolicitudPrestamoMonto
        WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
        AND OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual

        IF (@enSolicitud = 0)
        BEGIN
          SET @autorizado = 0;
          IF (@estatus = 'ACEPTADO'
            AND @subEstatus = 'AUTORIZADO')
          BEGIN
            SET @autorizado = 1;
          END


          SELECT
            @cicloIndividual = ISNULL(MAX(OTOR_SolicitudPrestamoMonto.ciclo), 0)
          FROM OTOR_SolicitudPrestamos
          INNER JOIN OTOR_SolicitudPrestamoMonto
            ON OTOR_SolicitudPrestamos.id = OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo
          WHERE id_individual = @idIndividual
          AND autorizado = 1
          AND OTOR_SolicitudPrestamos.tipo_cliente = 1;

          INSERT INTO OTOR_SolicitudPrestamoMonto (id_individual, monto_autorizado, monto_solicitado,
          monto_sugerido, estatus, sub_estatus, motivo, econ_id_actividad_economica, cargo,
          id_solicitud_prestamo, autorizado, id_cata_medio_desembolso, estatus_registro,
          creado_por, fecha_registro, modificado_por, fecha_revision, ciclo, perfil_riesgo, monto_garantia_financiable)
            VALUES (@idIndividual, @montoAutorizado, @montoSolicitado, @montoSugerido, @estatus, @subEstatus, @motivo, @econIdActividadEconomica, @cargo, @idSolicitud, @autorizado, @idCataMedioDesembolso, 'ACTIVO', @idUsuario, GETDATE(), @idUsuario, GETDATE(), @cicloIndividual, 'BAJO RIESGO', @monto_garantia_financiable)
          SET @idSolicitudPrestamoMonto = SCOPE_IDENTITY()


          SELECT
            @id_prestamo_monto = ISNULL(OTOR_SolicitudPrestamoMonto.id, 0)
          FROM OTOR_SolicitudPrestamoMonto
          WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
          AND OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud

          IF (@estatus = 'TRAMITE'
            AND @subEstatus = 'POR AUTORIZAR')
          BEGIN
            ------------------------------------------------------------------EVALUACION DE LA MATRIZ DE PERFIL DE RIESGO SPLD---------------------------------------------------------------------------------

            SELECT
              @IdConfiguracion = ISNULL(id, 0)
             ,@MontoMaximoCredito = ISNULL(valor, 0)
            FROM SPLD_Configuracion
            WHERE codigo = 'MATRIZ'
            AND estatus_registro = 'ACTIVO'

            SET @cambio_perfil = CAST(0 AS BIT)

            SET @etiquetaConfiguracion = '';
            ---Consulta para obtener los datos de cada socia					
            SELECT
              @nombreSocia = CONT_Personas.nombre
             ,@apellidoPaterno = CONT_Personas.apellido_paterno
             ,@apellidoMaterno = CONT_Personas.apellido_materno
            FROM OTOR_SolicitudPrestamoMonto
            INNER JOIN CLIE_Individual
              ON CLIE_Individual.id_cliente = OTOR_SolicitudPrestamoMonto.id_individual
            INNER JOIN CONT_Personas
              ON CONT_Personas.id = CLIE_Individual.id_persona
            WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
            AND CLIE_Individual.id_cliente = @idIndividual

            SELECT
              @perfilActual = LTRIM(RTRIM(perfil_riesgo))
            FROM OTOR_SolicitudPrestamoMonto
            WHERE id = @id_prestamo_monto

            -----------EVALUACION DE LA NUEVA MATRIZ
            INSERT INTO @ResultEvaluacionMatriz
            EXEC MEBR_EvaluarMatriz @id_persona,@idIndividual,@id_prestamo_monto,@idSolicitud,@montoSolicitado,'evaluacion_por_monto_enviado'
			SET @perfil_evaluacion = 'BAJO RIESGO'
			SELECT TOP 1 @perfil_evaluacion = CAST(COALESCE(LTRIM(RTRIM(perfil_evaluacion)), 'BAJO RIESGO') AS VARCHAR(20)) FROM @ResultEvaluacionMatriz
			IF (@perfilActual <> @perfil_evaluacion OR @perfil_evaluacion = 'ALTO RIESGO')
			BEGIN
				UPDATE OTOR_SolicitudPrestamoMonto
				SET OTOR_SolicitudPrestamoMonto.perfil_riesgo = @perfil_evaluacion
				WHERE OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto
				AND id_individual = @idIndividual
				INSERT INTO SPLD_HistorialSociaPerfilRiesgo (id_solicitud_prestamo_monto, nombre, apellido_paterno, apellido_materno, perfil_anterior, perfil_actual, comentario, forma, creado_por, fecha_creacion, estatus_registro)
				SELECT @id_prestamo_monto,@nombreSocia,@apellidoPaterno,@apellidoMaterno,@perfilActual,perfil_evaluacion,comentario,'AUTOMATICO',@idUsuario,GETDATE(),'ACTIVO'
				FROM @ResultEvaluacionMatriz
				SET @cambio_perfil = CAST(1 AS BIT)
			END			

          --IF(@cambio_perfil=CAST(0 AS BIT))
          --BEGIN
          --	IF NOT EXISTS(
          --		SELECT TOP(1) * FROM SPLD_DatosCliente 
          --		WHERE SPLD_DatosCliente.id_prestamo_monto=@id_prestamo_monto 
          --		AND SPLD_DatosCliente.id_cliente=@idIndividual
          --		AND (SPLD_DatosCliente.es_pep = 1
          --		OR SPLD_DatosCliente.es_persona_prohibida= 1 ) 
          --		AND SPLD_DatosCliente.estatus_registro='ACTIVO' ORDER BY SPLD_DatosCliente.id DESC 
          --		)
          --	BEGIN
          --		SELECT @perfilActual = LTRIM(RTRIM(perfil_riesgo)) FROM OTOR_SolicitudPrestamoMonto where id = @id_prestamo_monto 
          --		IF(@perfilActual <> 'BAJO RIESGO')
          --		BEGIN
          --			UPDATE OTOR_SolicitudPrestamoMonto SET OTOR_SolicitudPrestamoMonto.perfil_riesgo='BAJO RIESGO' WHERE OTOR_SolicitudPrestamoMonto.id=@id_prestamo_monto

          --			INSERT INTO SPLD_HistorialSociaPerfilRiesgo(id_solicitud_prestamo_monto,nombre,apellido_paterno,apellido_materno,perfil_anterior,perfil_actual,comentario,forma,creado_por,fecha_creacion,estatus_registro)
          -- 								SELECT @id_prestamo_monto,@nombreSocia,@apellidoPaterno,@apellidoMaterno,@perfilActual,'BAJO RIESGO','El cliente estaba catalogado como Persona Pol ticamente Expuesta y/o Persona Bloqueada,con un valor de nivel de riesgo ALTO.Por el Monto en Pesos de: $ '+ CAST(@montoSugerido AS VARCHAR),'AUTOMATICO',@idUsuario,GETDATE(),'ACTIVO'
          --		END
          --	END

          --END		
          END
          ----------------------------------------------------------------TERMINA EVALUACION DE LA MATRIZ DE PERFIL DE RIESGO---------------------------------------------------------------

          IF (@estatus = 'ACEPTADO'
            AND @subEstatus = 'AUTORIZADO')
          BEGIN

            /*IF(RTRIM(LTRIM(@PerfilRiesgo))='ALTO RIESGO')
						BEGIN*/
            INSERT INTO SPLD_HistorialAutorizacionRiesgo
              SELECT
                OTOR_SolicitudPrestamoMonto.id
               ,CONT_Personas.id
               ,OTOR_SolicitudPrestamoMonto.id_individual
               ,@idUsuario
               ,GETDATE()
               ,@idUsuario
               ,GETDATE()
               ,'ACTIVO'
               ,@PerfilRiesgo
              FROM OTOR_SolicitudPrestamoMonto
              INNER JOIN CLIE_Individual
                ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
              INNER JOIN CONT_Personas
                ON CLIE_Individual.id_persona = CONT_Personas.id
              WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
              AND OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto
            --END

            ----FORZAMOS LA ACTUALIZACION DEL PERFIL DE RIESGO
            SELECT
              @perfilSolicitudIndividual = perfil_riesgo
            FROM OTOR_SolicitudPrestamoMonto
            WHERE id_individual = @idIndividual
            AND id = @id_prestamo_monto

            IF (LTRIM(RTRIM(@perfilRiesgo)) = 'ALTO RIESGO')
            BEGIN
              IF (@perfilSolicitudIndividual = 'BAJO RIESGO')
              BEGIN
                UPDATE OTOR_SolicitudPrestamoMonto
                SET perfil_riesgo = 'ALTO RIESGO'
                WHERE id_individual = @idIndividual
                AND id = @id_prestamo_monto
              END
            END
            --Se llena Tabla Para Generacion de Garantia Financiable
            IF EXISTS (SELECT
                  *
                FROM OTOR_SolicitudPrestamos
                WHERE id = @idSolicitud
                AND garantia_liquida_financiable = 1)
            BEGIN
              INSERT INTO @UDT_detalle_socias
                SELECT
                  OTOR_SolicitudPrestamoMonto.id_individual
                 ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable AS monto_financiado
                FROM OTOR_SolicitudPrestamoMonto
                WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
                AND id_individual = @idIndividual
                AND autorizado = 1
            END

            -------------------------------------------------EVALUAR CRITERIO DE PA S PARA REPORTE INUSUAL------------------------------------------------------------
            IF (@evaluar_criterio_pld_ft = 1)
            BEGIN
              /*SELECT  
							@id_persona=ISNULL(SPLD_HistorialAutorizacionRiesgo.id_persona,0)
							FROM SPLD_HistorialAutorizacionRiesgo
							WHERE SPLD_HistorialAutorizacionRiesgo.id_prestamo_monto=@id_prestamo_monto 
							AND SPLD_HistorialAutorizacionRiesgo.estatus_registro='ACTIVO' 
							*/

              SELECT
                @id_persona = Persona.id_persona
              FROM CLIE_Individual
              CROSS APPLY (SELECT TOP (1)
                  CONT_Personas.id AS id_persona
                FROM CONT_Personas
                WHERE CONT_Personas.id = CLIE_Individual.id_persona
                ORDER BY CONT_Personas.id DESC) Persona
              WHERE CLIE_Individual.id_cliente = @idIndividual

              SELECT
                @id_pais_nacimiento = ISNULL(CONT_Personas.id_pais_nacimiento, 0)
               ,@id_pais_domicilio = ISNULL(CONT_Direcciones.pais, 0)
              FROM CONT_Personas
              INNER JOIN CONT_Direcciones
                ON CONT_Direcciones.id = CONT_Personas.id_direccion
                  AND CONT_Direcciones.estatus_registro = 'ACTIVO'
              WHERE CONT_Personas.id = @id_persona

              INSERT INTO @SPLD_Pais
                SELECT
                  id_pais
                 ,CATA_pais.etiqueta
                 ,aplica_regimen_fiscal_preferente
                 ,aplica_medidas_deficientes_pld_ft
                 ,no_tiene_medidas_pld_ft
                FROM SPLD_Pais
                INNER JOIN CATA_pais
                  ON SPLD_Pais.id_pais = CATA_pais.id
                WHERE SPLD_Pais.id_pais IN (@id_pais_nacimiento, @id_pais_domicilio)
                AND SPLD_Pais.activo = 1

              IF (SELECT
                    COUNT(*)
                  FROM @SPLD_Pais
                  WHERE id_pais = @id_pais_nacimiento)
                > 0
              BEGIN

                SELECT
                  @pais_spld = ISNULL(etiqueta, '')
                 ,@aplica_regimen_fiscal_preferente = ISNULL(aplica_regimen_fiscal_preferente, 0)
                 ,@aplica_medidas_deficientes_pld_ft = ISNULL(aplica_medidas_deficientes_pld_ft, 0)
                 ,@no_tiene_medidas_pld_ft = ISNULL(no_tiene_medidas_pld_ft, 0)
                FROM @SPLD_Pais
                WHERE id_pais = @id_pais_nacimiento

                IF (@aplica_regimen_fiscal_preferente = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: Aplica R gimen F scal Preferente' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END
                IF (@aplica_medidas_deficientes_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: Aplica Medidas Deficientes de PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@no_tiene_medidas_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: No Tiene Medidas PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@generar_reporte = 1)
                BEGIN
                  INSERT INTO @DATOSReporteCNBV
                  EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA'
                                               ,''
                                               ,''
                                               ,'01/01/1901'
                                               ,'01/01/1901'
                                               ,''
                                               ,@id_persona
                                               ,0
                                               ,0

                  UPDATE @DATOSReporteCNBV
                  SET id_tipo_reporte = 2
                     ,descripcion_reporte = @mensaje
                     ,monto = @montoAutorizado
                     ,moneda = 'MXN'

                  INSERT INTO @ResultadoOperacion
                  EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV
                                                         ,'OTOR_registrarActualisarSolicitudGrupoSolidario'
                                                         ,'INSERT_REPORT_AND_CNBV'
                                                         ,@idUsuario
                END
              END

              IF (SELECT
                    COUNT(*)
                  FROM @SPLD_Pais
                  WHERE id_pais = @id_pais_domicilio)
                > 0
              BEGIN
                SET @aplica_regimen_fiscal_preferente = 0
                SET @aplica_medidas_deficientes_pld_ft = 0
                SET @no_tiene_medidas_pld_ft = 0
                SET @generar_reporte = 0
                SET @pais_spld = ''
                SET @mensaje = ''
                DELETE FROM @DATOSReporteCNBV
                DELETE FROM @ResultadoOperacion

                SELECT
                  @pais_spld = ISNULL(etiqueta, '')
                 ,@aplica_regimen_fiscal_preferente = ISNULL(aplica_regimen_fiscal_preferente, 0)
                 ,@aplica_medidas_deficientes_pld_ft = ISNULL(aplica_medidas_deficientes_pld_ft, 0)
                 ,@no_tiene_medidas_pld_ft = ISNULL(no_tiene_medidas_pld_ft, 0)
                FROM @SPLD_Pais
                WHERE id_pais = @id_pais_domicilio

                IF (@aplica_regimen_fiscal_preferente = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el criterio de PLD: Aplica R gimen F scal Preferente' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END
                IF (@aplica_medidas_deficientes_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el siguiente criterio de PLD: Aplica Medidas Deficientes de PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@no_tiene_medidas_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el siguiente criterio de PLD: No Tiene Medidas PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@generar_reporte = 1)
                BEGIN
                  INSERT INTO @DATOSReporteCNBV
                  EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA'
                                               ,''
                                               ,''
                                               ,'01/01/1901'
                                               ,'01/01/1901'
                                               ,''
                                               ,@id_persona
                                               ,0
                                               ,0

                  UPDATE @DATOSReporteCNBV
                  SET id_tipo_reporte = 2
                     ,descripcion_reporte = @mensaje
                     ,monto = @montoAutorizado
                     ,moneda = 'MXN'

                  INSERT INTO @ResultadoOperacion
                  EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV
                                                         ,'OTOR_registrarActualisarSolicitudGrupoSolidario'
                                                         ,'INSERT_REPORT_AND_CNBV'
                                                         ,@idUsuario
                END

              END
            END
          -------------------------------------------------------------------------------------------------------------------------


          END

          IF (@estatus = 'RECHAZADO'
            AND @subEstatus = 'CASTIGADO')
          BEGIN
            UPDATE CLIE_Clientes
            SET sub_estatus = 'CASTIGADO'
               ,CLIE_Clientes.lista_negra = 1
               ,modificado_por = @idUsuario
               ,fecha_revision = GETDATE()
            WHERE CLIE_Clientes.id = @idIndividual;

            -- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.activo = 0
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo =
            @idSolicitud
            AND activo = 1;
          END
          --Se llena Tabla para Cancelacion de Garantia Financiable
          IF ((@estatus = 'RECHAZADO'
            AND @subEstatus = 'CASTIGADO')
            OR (@estatus = 'CANCELADO'
            AND @subEstatus = 'CANCELACION/ABANDONO')
            OR (@estatus = 'RECHAZADO'
            AND @subEstatus = 'RECHAZADO'))
          BEGIN
            IF EXISTS (SELECT
                  *
                FROM OTOR_SolicitudPrestamos
                WHERE id = @idSolicitud
                AND garantia_liquida_financiable = 1)
            BEGIN
              INSERT INTO @UDT_detalle_socias_cancelacion
                SELECT
                  OTOR_SolicitudPrestamoMonto.id_individual
                 ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable AS monto_financiado
                FROM OTOR_SolicitudPrestamoMonto
                WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
                AND id_individual = @idIndividual
                AND autorizado = 1
            END
          END
          -- =========================================================================== Microcreditos ===============================================
          IF NOT EXISTS (SELECT
                *
              FROM CLIE_DetalleSeguro
              WHERE id_individual = @idIndividual
              AND id_solicitud_prestamo = @idSolicitud
              AND activo = 1)
          BEGIN
            IF (@id_asignacion_seguro_UDT <> 0)
            BEGIN
              INSERT INTO CLIE_DetalleSeguro (id_solicitud_prestamo, id_individual, id_seguro_asignacion, nombre_beneficiario, parentesco, porcentaje, costo_seguro, incluye_saldo_deudor, creado_por, fecha_creacion, modificado_por, fecha_modificacion, activo)
                VALUES (@idSolicitud, @idIndividual, @id_asignacion_seguro_UDT, @nombre_beneficiario, @parentesco, 100, @costo_seguro, @incluye_saldo_deudor, @idUsuario, GETDATE(), @idUsuario, GETDATE(), 1)

            END
          END
          ELSE
          BEGIN
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.nombre_beneficiario = @nombre_beneficiario
               ,CLIE_DetalleSeguro.parentesco = @parentesco
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.costo_seguro = @costo_seguro
               ,CLIE_DetalleSeguro.incluye_saldo_deudor = @incluye_saldo_deudor
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1
          END
          -- ==============Termina Microcreditos

          -- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
          IF (@estatus = 'CANCELADO'
            AND @subEstatus = 'CANCELACION/ABANDONO')
          BEGIN
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.activo = 0
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1
          END

          IF (@estatus = 'RECHAZADO'
            AND @subEstatus = 'RECHAZADO')
          BEGIN
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.activo = 0
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1
          END

        END
        ELSE
        BEGIN

          SELECT
            @id_prestamo_monto = ISNULL(OTOR_SolicitudPrestamoMonto.id, 0)
          FROM OTOR_SolicitudPrestamoMonto
          WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
          AND OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual

          SET @autorizado = 0;

          IF (@estatus = 'TRAMITE'
            AND @subEstatus = 'POR AUTORIZAR')
          BEGIN
            ------------------------------------------------------------------EVALUACION DE LA MATRIZ DE PERFIL DE RIESGO SPLD---------------------------------------------------------------------------------

            SELECT
              @IdConfiguracion = ISNULL(id, 0)
             ,@MontoMaximoCredito = ISNULL(valor, 0)
            FROM SPLD_Configuracion
            WHERE codigo = 'MATRIZ'
            AND estatus_registro = 'ACTIVO'

            SET @cambio_perfil = CAST(0 AS BIT)

            SET @etiquetaConfiguracion = '';
            ---Consulta para obtener los datos de cada socia					
            SELECT
              @nombreSocia = CONT_Personas.nombre
             ,@apellidoPaterno = CONT_Personas.apellido_paterno
             ,@apellidoMaterno = CONT_Personas.apellido_materno
            FROM OTOR_SolicitudPrestamoMonto
            INNER JOIN CLIE_Individual
              ON CLIE_Individual.id_cliente = OTOR_SolicitudPrestamoMonto.id_individual
            INNER JOIN CONT_Personas
              ON CONT_Personas.id = CLIE_Individual.id_persona
            WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
            AND CLIE_Individual.id_cliente = @idIndividual

            SELECT
              @perfilActual = LTRIM(RTRIM(perfil_riesgo))
            FROM OTOR_SolicitudPrestamoMonto
            WHERE id = @id_prestamo_monto

            -----------EVALUACION DE MATRIZ
            INSERT INTO @ResultEvaluacionMatriz
			EXEC MEBR_EvaluarMatriz @id_persona,@idIndividual,@id_prestamo_monto,@idSolicitud,@montoSolicitado,'evaluacion_por_monto_enviado'            
			SET @perfil_evaluacion = 'BAJO RIESGO'
			SELECT TOP 1 @perfil_evaluacion = CAST(COALESCE(LTRIM(RTRIM(perfil_evaluacion)), 'BAJO RIESGO') AS VARCHAR(20)) FROM @ResultEvaluacionMatriz
			IF (@perfilActual <> @perfil_evaluacion OR @perfil_evaluacion = 'ALTO RIESGO')
			BEGIN
				UPDATE OTOR_SolicitudPrestamoMonto
				SET OTOR_SolicitudPrestamoMonto.perfil_riesgo = @perfil_evaluacion
				WHERE OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto
				AND id_individual = @idIndividual
				INSERT INTO SPLD_HistorialSociaPerfilRiesgo (id_solicitud_prestamo_monto, nombre, apellido_paterno, apellido_materno, perfil_anterior, perfil_actual, comentario, forma, creado_por, fecha_creacion, estatus_registro)
				SELECT @id_prestamo_monto,@nombreSocia,@apellidoPaterno,@apellidoMaterno,@perfilActual,perfil_evaluacion,comentario,'AUTOMATICO',@idUsuario,GETDATE(),'ACTIVO'
				FROM @ResultEvaluacionMatriz
				SET @cambio_perfil = CAST(1 AS BIT)
			END

          -----------------

          --IF(@cambio_perfil=CAST(0 AS BIT))
          --BEGIN
          --	IF NOT EXISTS(
          --		SELECT TOP(1) * FROM SPLD_DatosCliente 
          --		WHERE SPLD_DatosCliente.id_prestamo_monto=@id_prestamo_monto 
          --		AND SPLD_DatosCliente.id_cliente=@idIndividual
          --		AND (SPLD_DatosCliente.es_pep = 1
          --		OR SPLD_DatosCliente.es_persona_prohibida= 1 ) 
          --		AND SPLD_DatosCliente.estatus_registro='ACTIVO' ORDER BY SPLD_DatosCliente.id DESC 
          --		)
          --	BEGIN
          --		SELECT @perfilActual = LTRIM(RTRIM(perfil_riesgo)) FROM OTOR_SolicitudPrestamoMonto where id = @id_prestamo_monto 
          --		IF(@perfilActual <> 'BAJO RIESGO')
          --		BEGIN
          --			UPDATE OTOR_SolicitudPrestamoMonto SET OTOR_SolicitudPrestamoMonto.perfil_riesgo='BAJO RIESGO' WHERE OTOR_SolicitudPrestamoMonto.id=@id_prestamo_monto

          --			INSERT INTO SPLD_HistorialSociaPerfilRiesgo(id_solicitud_prestamo_monto,nombre,apellido_paterno,apellido_materno,perfil_anterior,perfil_actual,comentario,forma,creado_por,fecha_creacion,estatus_registro)
          -- 								SELECT @id_prestamo_monto,@nombreSocia,@apellidoPaterno,@apellidoMaterno,@perfilActual,'BAJO RIESGO','El cliente estaba catalogado como Persona Pol ticamente Expuesta y/o Persona Bloqueada.Por el Monto en Pesos de: $ '+ CAST(@montoSugerido AS VARCHAR),'AUTOMATICO',@idUsuario,GETDATE(),'ACTIVO'
          --		END
          --	END

          --END		
          END
          ----------------------------------------------------------------TERMINA EVALUACION DE LA MATRIZ DE PERFIL DE RIESGO---------------------------------------------------------------


          IF (@estatus = 'ACEPTADO'
            AND @subEstatus = 'AUTORIZADO')
          BEGIN

            SELECT
              @PerfilRiesgo = ISNULL(OTOR_SolicitudPrestamoMonto.perfil_riesgo, '')
            FROM OTOR_SolicitudPrestamoMonto
            WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
            AND OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto

            /*IF(RTRIM(LTRIM(@PerfilRiesgo))='ALTO RIESGO')
						BEGIN*/
            INSERT INTO SPLD_HistorialAutorizacionRiesgo
              SELECT
                OTOR_SolicitudPrestamoMonto.id
               ,CONT_Personas.id
               ,OTOR_SolicitudPrestamoMonto.id_individual
               ,@idUsuario
               ,GETDATE()
               ,@idUsuario
               ,GETDATE()
               ,'ACTIVO'
               ,@PerfilRiesgo
              FROM OTOR_SolicitudPrestamoMonto
              INNER JOIN CLIE_Individual
                ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
              INNER JOIN CONT_Personas
                ON CLIE_Individual.id_persona = CONT_Personas.id
              WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
              AND OTOR_SolicitudPrestamoMonto.id = @id_prestamo_monto

            ----FORZAMOS LA ACTUALIZACION DEL PERFIL DE RIESGO
            SELECT
              @perfilSolicitudIndividual = perfil_riesgo
            FROM OTOR_SolicitudPrestamoMonto
            WHERE id_individual = @idIndividual
            AND id = @id_prestamo_monto

            IF (LTRIM(RTRIM(@perfilRiesgo)) = 'ALTO RIESGO')
            BEGIN
              IF (@perfilSolicitudIndividual = 'BAJO RIESGO')
              BEGIN
                UPDATE OTOR_SolicitudPrestamoMonto
                SET perfil_riesgo = 'ALTO RIESGO'
                WHERE id_individual = @idIndividual
                AND id = @id_prestamo_monto
              END
            END

            -------------------------------------------------EVALUAR CRITERIO DE PA S PARA REPORTE INUSUAL------------------------------------------------------------

            IF (@evaluar_criterio_pld_ft = 1)
            BEGIN
              /*SELECT  
							@id_persona=ISNULL(SPLD_HistorialAutorizacionRiesgo.id_persona,0)
							FROM SPLD_HistorialAutorizacionRiesgo
							WHERE SPLD_HistorialAutorizacionRiesgo.id_prestamo_monto=@id_prestamo_monto 
							AND SPLD_HistorialAutorizacionRiesgo.estatus_registro='ACTIVO' 
							*/
              SELECT
                @id_persona = Persona.id_persona
              FROM CLIE_Individual
              CROSS APPLY (SELECT TOP (1)
                  CONT_Personas.id AS id_persona
                FROM CONT_Personas
                WHERE CONT_Personas.id = CLIE_Individual.id_persona
                ORDER BY CONT_Personas.id DESC) Persona
              WHERE CLIE_Individual.id_cliente = @idIndividual

              SELECT
                @id_pais_nacimiento = ISNULL(CONT_Personas.id_pais_nacimiento, 0)
               ,@id_pais_domicilio = ISNULL(CONT_Direcciones.pais, 0)
              FROM CONT_Personas
              INNER JOIN CONT_Direcciones
                ON CONT_Direcciones.id = CONT_Personas.id_direccion
                  AND CONT_Direcciones.estatus_registro = 'ACTIVO'
              WHERE CONT_Personas.id = @id_persona

              INSERT INTO @SPLD_Pais
                SELECT
                  id_pais
                 ,CATA_pais.etiqueta
                 ,aplica_regimen_fiscal_preferente
                 ,aplica_medidas_deficientes_pld_ft
                 ,no_tiene_medidas_pld_ft
                FROM SPLD_Pais
                INNER JOIN CATA_pais
                  ON SPLD_Pais.id_pais = CATA_pais.id
                WHERE SPLD_Pais.id_pais IN (@id_pais_nacimiento, @id_pais_domicilio)
                AND SPLD_Pais.activo = 1

              IF (SELECT
                    COUNT(*)
                  FROM @SPLD_Pais
                  WHERE id_pais = @id_pais_nacimiento)
                > 0
              BEGIN

                SELECT
                  @pais_spld = ISNULL(etiqueta, '')
                 ,@aplica_regimen_fiscal_preferente = ISNULL(aplica_regimen_fiscal_preferente, 0)
                 ,@aplica_medidas_deficientes_pld_ft = ISNULL(aplica_medidas_deficientes_pld_ft, 0)
                 ,@no_tiene_medidas_pld_ft = ISNULL(no_tiene_medidas_pld_ft, 0)
                FROM @SPLD_Pais
                WHERE id_pais = @id_pais_nacimiento

                IF (@aplica_regimen_fiscal_preferente = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: Aplica R gimen F scal Preferente' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END
                IF (@aplica_medidas_deficientes_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: Aplica Medidas Deficientes de PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@no_tiene_medidas_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de nacimiento del cliente: ' + @pais_spld + ', se encuentra en el siguiente criterio de PLD: No Tiene Medidas PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@generar_reporte = 1)
                BEGIN
                  INSERT INTO @DATOSReporteCNBV
                  EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA'
                                               ,''
                                               ,''
                                               ,'01/01/1901'
                                               ,'01/01/1901'
                                               ,''
                                               ,@id_persona
                                               ,0
                                               ,0

                  UPDATE @DATOSReporteCNBV
                  SET id_tipo_reporte = 2
                     ,descripcion_reporte = @mensaje
                     ,monto = @montoAutorizado
                     ,moneda = 'MXN'

                  INSERT INTO @ResultadoOperacion
                  EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV
                                                         ,'OTOR_registrarActualisarSolicitudGrupoSolidario'
                                                         ,'INSERT_REPORT_AND_CNBV'
                                                         ,@idUsuario
                END
              END

              IF (SELECT
                    COUNT(*)
                  FROM @SPLD_Pais
                  WHERE id_pais = @id_pais_domicilio)
                > 0
              BEGIN
                SET @aplica_regimen_fiscal_preferente = 0
                SET @aplica_medidas_deficientes_pld_ft = 0
                SET @no_tiene_medidas_pld_ft = 0
                SET @generar_reporte = 0
                SET @pais_spld = ''
                SET @mensaje = ''
                DELETE FROM @DATOSReporteCNBV
                DELETE FROM @ResultadoOperacion

                SELECT
                  @pais_spld = ISNULL(etiqueta, '')
                 ,@aplica_regimen_fiscal_preferente = ISNULL(aplica_regimen_fiscal_preferente, 0)
                 ,@aplica_medidas_deficientes_pld_ft = ISNULL(aplica_medidas_deficientes_pld_ft, 0)
                 ,@no_tiene_medidas_pld_ft = ISNULL(no_tiene_medidas_pld_ft, 0)
                FROM @SPLD_Pais
                WHERE id_pais = @id_pais_domicilio

                IF (@aplica_regimen_fiscal_preferente = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el criterio de PLD: Aplica R gimen F scal Preferente' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END
                IF (@aplica_medidas_deficientes_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el siguiente criterio de PLD: Aplica Medidas Deficientes de PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@no_tiene_medidas_pld_ft = 1)
                BEGIN
                  SET @mensaje = @mensaje + 'El pa s de domicilio del cliente: ' + @pais_spld + ' se encuentra en el siguiente criterio de PLD: No Tiene Medidas PLD/FT' + CHAR(13) + CHAR(10)
                  SET @generar_reporte = 1
                END

                IF (@generar_reporte = 1)
                BEGIN
                  INSERT INTO @DATOSReporteCNBV
                  EXEC SPLD_ObtenerDatosReporte 'BUSCAR_PERSONA'
                                               ,''
                                               ,''
                                               ,'01/01/1901'
                                               ,'01/01/1901'
                                               ,''
                                               ,@id_persona
                                               ,0
                                               ,0

                  UPDATE @DATOSReporteCNBV
                  SET id_tipo_reporte = 2
                     ,descripcion_reporte = @mensaje
                     ,monto = @montoAutorizado
                     ,moneda = 'MXN'

                  INSERT INTO @ResultadoOperacion
                  EXEC SPLD_AdministracionAlarmasReportes @DATOSReporteCNBV
                                                         ,'OTOR_registrarActualisarSolicitudGrupoSolidario'
                                                         ,'INSERT_REPORT_AND_CNBV'
                                                         ,@idUsuario
                END

              END
            END
            -------------------------------------------------------------------------------------------------------------------------


            SET @autorizado = 1;

          END
          --Llenado de Tablas de Cancelacion de Garantia Financiable
          IF ((@estatus = 'RECHAZADO'
            AND @subEstatus = 'CASTIGADO')
            OR (@estatus = 'CANCELADO'
            AND @subEstatus = 'CANCELACION/ABANDONO')
            OR (@estatus = 'RECHAZADO'
            AND @subEstatus = 'RECHAZADO'))
          BEGIN
            IF EXISTS (SELECT
                  *
                FROM OTOR_SolicitudPrestamos
                WHERE id = @idSolicitud
                AND garantia_liquida_financiable = 1)
            BEGIN
              INSERT INTO @UDT_detalle_socias_cancelacion
                SELECT
                  OTOR_SolicitudPrestamoMonto.id_individual
                 ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable AS monto_financiado
                FROM OTOR_SolicitudPrestamoMonto
                WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
                AND id_individual = @idIndividual
                AND autorizado = 1
            END
          END
          UPDATE OTOR_SolicitudPrestamoMonto
          SET cargo = @cargo
             ,monto_solicitado = @montoSolicitado
             ,monto_sugerido = @montoSugerido
             ,monto_autorizado = @montoAutorizado
             ,econ_id_actividad_economica = @econIdActividadEconomica
             ,estatus = @estatus
             ,sub_estatus = @subEstatus
             ,motivo = @motivo
             ,autorizado = @autorizado
             ,id_cata_medio_desembolso = @idCataMedioDesembolso
             ,modificado_por = @idUsuario
             ,monto_garantia_financiable = @monto_garantia_financiable
             ,fecha_revision = GETDATE()
          WHERE OTOR_SolicitudPrestamoMonto.id_individual = @idIndividual
          AND OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
          AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO';
          --LLenado de Tablas de Garantia Financiable
          IF (@estatus = 'ACEPTADO'
            AND @subEstatus = 'AUTORIZADO')
          BEGIN
            IF EXISTS (SELECT
                  *
                FROM OTOR_SolicitudPrestamos
                WHERE id = @idSolicitud
                AND garantia_liquida_financiable = 1)
            BEGIN
              INSERT INTO @UDT_detalle_socias
                SELECT
                  OTOR_SolicitudPrestamoMonto.id_individual
                 ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable AS monto_financiado
                FROM OTOR_SolicitudPrestamoMonto
                WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
                AND id_individual = @idIndividual
                AND autorizado = 1
            END

          END
          -- =========================================================================== Microcreditos ===============================================
          IF NOT EXISTS (SELECT
                *
              FROM CLIE_DetalleSeguro
              WHERE id_individual = @idIndividual
              AND id_solicitud_prestamo = @idSolicitud
              AND activo = 1)
          BEGIN
            IF (@id_asignacion_seguro_UDT <> 0)
            BEGIN
              INSERT INTO CLIE_DetalleSeguro (id_solicitud_prestamo, id_individual, id_seguro_asignacion, nombre_beneficiario, parentesco, porcentaje, costo_seguro, incluye_saldo_deudor, creado_por, fecha_creacion, modificado_por, fecha_modificacion, activo)
                VALUES (@idSolicitud, @idIndividual, @id_asignacion_seguro_UDT, @nombre_beneficiario, @parentesco, 100, @costo_seguro, @incluye_saldo_deudor, @idUsuario, GETDATE(), @idUsuario, GETDATE(), 1)

            END
          END
          ELSE
          BEGIN
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.nombre_beneficiario = @nombre_beneficiario
               ,CLIE_DetalleSeguro.parentesco = @parentesco
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,CLIE_DetalleSeguro.fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.costo_seguro = @costo_seguro
               ,CLIE_DetalleSeguro.incluye_saldo_deudor = @incluye_saldo_deudor
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1
          END
          -- ==============Termina Microcreditos

          IF (@estatus = 'RECHAZADO'
            AND @subEstatus = 'CASTIGADO')
          BEGIN
            UPDATE CLIE_Clientes
            SET sub_estatus = 'CASTIGADO'
               ,CLIE_Clientes.lista_negra = 1
               ,modificado_por = @idUsuario
               ,fecha_revision = GETDATE()
            WHERE CLIE_Clientes.id = @idIndividual;
            -- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.activo = 0
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1;
          END

          -- ====== UPDATE A CLIE_DetalleSeguro PARA MICROSEGUROS
          IF (@estatus = 'CANCELADO'
            AND @subEstatus = 'CANCELACION/ABANDONO')
          BEGIN
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.activo = 0
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1
          END

          IF (@estatus = 'RECHAZADO'
            AND @subEstatus = 'RECHAZADO')
          BEGIN
            UPDATE CLIE_DetalleSeguro
            SET CLIE_DetalleSeguro.id_seguro_asignacion = @id_asignacion_seguro_UDT
               ,CLIE_DetalleSeguro.modificado_por = @idUsuario
               ,fecha_modificacion = GETDATE()
               ,CLIE_DetalleSeguro.activo = 0
            WHERE id_individual = @idIndividual
            AND id_solicitud_prestamo = @idSolicitud
            AND activo = 1
          END
        END
      END

      FETCH NEXT FROM cursorSolicitudDetalle
      INTO @idIndividual, @idSolicitudPrestamoMonto, @idPersona, @estatus, @cargo, @montoSolicitado,
      @montoSugerido, @montoAutorizado, @econIdActividadEconomica, @motivo, @subEstatus, @idCataMedioDesembolso, @monto_garantia_financiable
      END

      IF (@estatus = 'ACEPTADO'
        AND @subEstatus = 'AUTORIZADO')
      BEGIN

        INSERT INTO OTOR_HistorialAutorizacion
          SELECT
            @idSolicitud
           ,COUNT(OTOR_SolicitudPrestamoMonto.id)
           ,SUM(monto_autorizado)
           ,'AUTORIZACION'
           ,@idUsuario
           ,GETDATE()
           ,@idUsuario
           ,GETDATE()
           ,'ACTIVO'
          FROM OTOR_SolicitudPrestamoMonto
          WHERE OTOR_SolicitudPrestamoMonto.autorizado = 1
          AND OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitud
          AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO';
      END

      IF ((SELECT
            COUNT(*)
          FROM @UDT_detalle_socias)
        > 0)
      BEGIN
        --Llamamos al PS FinanciamientoGarantiaOperativo
        EXEC OTOR_ManagerFinanciamientoGarantiaLiquida 'PROVISION'
                                                      ,@idSolicitud
                                                      ,0
                                                      ,@fecha_garatiaFinanciable
                                                      ,@UDT_detalle_socias
                                                      ,0
      END
      IF ((SELECT
            COUNT(*)
          FROM @UDT_detalle_socias_cancelacion)
        > 0)
      BEGIN
        --Llamamos al PS FinanciamientoGarantiaOperativo
        EXEC OTOR_ManagerFinanciamientoGarantiaLiquida 'CANCELACION'
                                                      ,@idSolicitud
                                                      ,0
                                                      ,@fecha_garatiaFinanciable
                                                      ,@UDT_detalle_socias_cancelacion
                                                      ,0
      END

    END
    ELSE
    BEGIN
      SELECT
        ISNULL(@idCliente, 0)
       ,ISNULL(@idSolicitud, 0)
       ,ISNULL(@nombre, '')
       ,ISNULL(@reunionDia, '')
       ,ISNULL(@reunionHora, '')
    END

    COMMIT TRAN Tran_RegActSolicitudCliente;
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN Tran_RegActSolicitudCliente;

    INSERT INTO SYST_ErrorLog (numero, gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
      SELECT
        ERROR_NUMBER() AS Numero_de_Error
       ,ERROR_SEVERITY() AS Gravedad_del_Error
       ,ERROR_STATE() AS Estado_del_Error
       ,ERROR_PROCEDURE() AS Procedimiento_del_Error
       ,ERROR_LINE() AS Linea_de_Error
       ,ERROR_MESSAGE() AS Mensaje_de_Error
       ,'OTOR_registrarActualizarSolicitudCliente' AS Procedimiento_Origen;
  END CATCH
END
GO

--#endregion ------------------------------------- FIN PROCEDURE ASIGNAMENT MONTO A LOAN ------------------------------------------ 

--#region ---------------------------------------- PROCEDURE GET DETAILS LOAN ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_CLIE_ObtenerSolicitudClienteServicioFinanciero_V2
@id_solicitud INT,
@id_oficina INT
AS
BEGIN
-- =============================================
-- Alter date: <Enero de 2016>
-- Description:	<se agrega actualiza columna a la consulta de retorno, columna que indica el el perfil de Riesgo,  ALTO RIESGO o BAJO RIESGO>
-- Alter date: <Septiembre 2016> <Sally Gonz lez> <Se agrega la consulta para que se obtenga el seguro de los clientes.>
-- Alter date: <Octubre 2016> <Celso Vazquez> <Se reutiliza el campo id_riesgo_pld para indicar si el cliente le falta capturar datos>
-- Alter Date: <30/07/2017> <Se modifica para devolver empleos diferente de puesto "due o">
-- Alter Date <16/03/2018> <Eduardo Cordova><Se modifica la consulta para obtener los ciclos de OTOR_contratos, ya que mostraba infomraci n de una tabla que ya no se aimenta>
-- Alter Date 29/08/2019> Andres Montes: Se correigen detalles del seguro deudor para grupos nuevos
-- Alter Date 08/10/2020> Andres Montes: Obtenci n de garant as prendarias para grupos
--Alter Date Enero 2022 Fabian G. Se agregaron los datos de tu hogar con conserva
--Alter Date 22 Abril 2022, By Fabian Garcia Toledo, se separo la latitud y la longitud
-- =============================================
  DECLARE @tipoCliente INT;
  DECLARE @idDireccion INT;
  DECLARE @ciclo INT = 0;
  DECLARE @idServicioFinanciero INT;
  DECLARE @id_oficial_credito INT = 0;
  DECLARE @id_cliente INT = 0;

  SELECT
    @id_cliente = ISNULL(id_cliente, 0)
   ,@id_oficial_credito = ISNULL(OTOR_SolicitudPrestamos.id_oficial, 0)
  FROM OTOR_SolicitudPrestamos
  WHERE OTOR_SolicitudPrestamos.id = @id_solicitud

  --Informaci n de la solicitud.
  SELECT
    OTOR_SolicitudPrestamos.id
   ,OTOR_SolicitudPrestamos.id_cliente
   ,OTOR_SolicitudPrestamos.id_oficial
   ,ISNULL(OTOR_SolicitudPrestamos.id_oficina, 0) AS id_oficina
   ,OTOR_SolicitudPrestamos.id_producto
   ,OTOR_SolicitudPrestamos.id_disposicion
   ,OTOR_SolicitudPrestamos.monto_total_solicitado
   ,OTOR_SolicitudPrestamos.monto_total_autorizado
   ,OTOR_SolicitudPrestamos.periodicidad
   ,OTOR_SolicitudPrestamos.plazo
   ,OTOR_SolicitudPrestamos.estatus
   ,OTOR_SolicitudPrestamos.fecha_primer_pago
   ,OTOR_SolicitudPrestamos.fecha_entrega
   ,(CASE OTOR_SolicitudPrestamos.medio_desembolso
      WHEN '' THEN 'ORP'
      ELSE ISNULL(OTOR_SolicitudPrestamos.medio_desembolso, 'ORP')
    END) AS medio_desembolso
   ,OTOR_SolicitudPrestamos.garantia_liquida
   ,OTOR_SolicitudPrestamos.fecha_creacion
   ,OTOR_SolicitudPrestamos.sub_estatus
   ,OTOR_SolicitudPrestamos.tipo_cliente
   ,OTOR_SolicitudPrestamos.creado_por
   ,OTOR_SolicitudPrestamos.id_producto_maestro
   ,OTOR_SolicitudPrestamos.garantia_liquida_financiable
   ,OTOR_SolicitudPrestamos.tasa_anual
  FROM OTOR_SolicitudPrestamos
  WHERE OTOR_SolicitudPrestamos.id = @id_solicitud

  --Nueva obtencion de ciclos
  SELECT
    @ciclo = ISNULL(MAX(OTOR_contratos.ciclo), 0)
  FROM OTOR_Contratos
  WHERE OTOR_Contratos.id_cliente = @id_cliente
  AND estatus IN ('DESEMBOLSADO', 'FINALIZADO')

  SELECT
    CLIE_Clientes.id
   ,@ciclo AS ciclo
   ,CLIE_Clientes.estatus
   ,CLIE_Clientes.sub_estatus
   ,@id_oficial_credito AS id_oficial_credito
   ,CLIE_Clientes.id_oficina
  FROM CLIE_Clientes
  WHERE CLIE_Clientes.id = @id_cliente;

  --Informaci n del Grupo
  SELECT
    id_cliente
   ,nombre
   ,id_direccion
   ,reunion_dia
   ,reunion_hora
  FROM CLIE_Grupos
  WHERE CLIE_Grupos.id_cliente = (CASE
    WHEN @id_cliente = 0 THEN NULL
    ELSE @id_cliente
  END);

  --Informaci n de la direcci n del Grupo.
  SELECT
    @idDireccion = ISNULL(CLIE_Grupos.id_direccion, 0)
  FROM CLIE_Grupos
  WHERE CLIE_Grupos.id_cliente = (CASE
    WHEN @id_cliente = 0 THEN NULL
    ELSE @id_cliente
  END);

  SELECT
    CONT_Direcciones.id
   ,CONT_Direcciones.direccion
   ,CONT_Direcciones.vialidad /*CONT_Direcciones.pais*/
   ,CONT_Direcciones.estado
   ,CONT_Direcciones.municipio
   ,CONT_Direcciones.localidad
   ,CONT_Direcciones.colonia
   ,ISNULL(CONT_Direcciones.referencia, '') AS referencia
   ,ISNULL(CONT_Direcciones.numero_exterior, '') AS numero_exterior
   ,ISNULL(CONT_Direcciones.numero_interior, '') AS numero_interior
  FROM CONT_Direcciones
  WHERE CONT_Direcciones.id = @idDireccion

  --Miembros de los miembros de la solicitud.
  SELECT
    OTOR_SolicitudPrestamoMonto.id_individual
   ,CONT_personas.id
   ,CONT_Personas.nombre
   ,CONT_Personas.apellido_paterno
   ,CONT_Personas.apellido_materno
   ,ISNULL(OTOR_SolicitudPrestamoMonto.estatus, '') AS estatus
   ,OTOR_SolicitudPrestamoMonto.sub_estatus
   ,ISNULL(OTOR_SolicitudPrestamoMonto.cargo, '') AS cargo
   ,OTOR_SolicitudPrestamoMonto.monto_solicitado
   ,ISNULL(OTOR_SolicitudPrestamoMonto.monto_sugerido, 0) AS monto_sugerido
   ,OTOR_SolicitudPrestamoMonto.monto_autorizado
   ,CLIE_Individual.econ_id_actividad_economica
   ,(SELECT
        COUNT(*)
      FROM CONT_IdentificacionOficial
      INNER JOIN CONT_CURP
        ON CONT_IdentificacionOficial.id = CONT_CURP.id_identificacion_oficial
      WHERE CONT_IdentificacionOficial.id_persona = CONT_Personas.id
      AND LEN(RTRIM(LTRIM(CAST(CONT_CURP.xml_datos_oficiales AS VARCHAR)))) > 0)
    AS CURPFisica
   ,OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo
   ,ISNULL(OTOR_SolicitudPrestamoMonto.ciclo, 0) AS ciclo
   ,dbo.ufnObtenerMontoAutorizadoAnterior(OTOR_SolicitudPrestamoMonto.id_individual) AS monto_anterior
   ,dbo.ufnValidaInformacionCliente(CONT_personas.id) AS id_riesgo_pld
   ,OTOR_SolicitudPrestamoMonto.perfil_riesgo riesgo_pld
   ,ISNULL(OTOR_SolicitudPrestamoMonto.id_cata_medio_desembolso, 2) AS id_cata_medio_desembolso
   ,OTOR_SolicitudPrestamoMonto.monto_garantia_financiable
  FROM OTOR_SolicitudPrestamoMonto
  INNER JOIN CLIE_Individual
    ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
  INNER JOIN CONT_Personas
    ON CLIE_Individual.id_persona = CONT_Personas.id
  WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @id_solicitud
  AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus, '') <> 'CANCELADO'
  AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus, '') <> 'RECHAZADO'
  AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO'
  ORDER BY OTOR_SolicitudPrestamoMonto.id_individual ASC

  -- === Informacion de seguros
  SELECT
    ISNULL(CLIE_DetalleSeguro.id, 0) AS id
   ,ISNULL(OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo, 0) AS id_solicitud_prestamo
   ,ISNULL(OTOR_SolicitudPrestamoMonto.id_individual, 0) AS id_individual
   ,ISNULL(CATA_ProductoSeguro.id_seguro, 0) AS id_seguro
   ,ISNULL(CLIE_DetalleSeguro.id_seguro_asignacion, 0) AS id_asignacion_seguro
   ,CONT_Personas.nombre + ' ' + CONT_Personas.apellido_paterno + ' ' + CONT_Personas.apellido_materno AS nombre_socia
   ,ISNULL(CLIE_DetalleSeguro.nombre_beneficiario, '') AS nombre_beneficiario
   ,ISNULL(CLIE_DetalleSeguro.parentesco, '') AS parentesco
   ,ISNULL(CLIE_DetalleSeguro.porcentaje, 0.0) AS porcentaje
   ,ISNULL(CLIE_DetalleSeguro.costo_seguro, 0.0) AS costo_seguro
   ,ISNULL(CLIE_DetalleSeguro.incluye_saldo_deudor, 0) AS incluye_saldo_deudor
   ,ISNULL(CLIE_DetalleSeguro.activo, 0) AS activo
  FROM OTOR_SolicitudPrestamoMonto
  INNER JOIN CLIE_Individual
    ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
  LEFT JOIN CLIE_DetalleSeguro
    ON CLIE_DetalleSeguro.id_individual = OTOR_SolicitudPrestamoMonto.id_individual
      AND CLIE_DetalleSeguro.id_solicitud_prestamo = OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo
      AND CLIE_DetalleSeguro.activo = 1
  LEFT JOIN CATA_ProductoSeguro
    ON CATA_ProductoSeguro.id = CLIE_DetalleSeguro.id_seguro_asignacion
      AND CATA_ProductoSeguro.activo = 1
  INNER JOIN CONT_Personas
    ON CLIE_Individual.id_persona = CONT_Personas.id

  WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @id_solicitud
  AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus, '') <> 'CANCELADO'
  AND ISNULL(OTOR_SolicitudPrestamoMonto.estatus, '') <> 'RECHAZADO'
  AND OTOR_SolicitudPrestamoMonto.estatus_registro <> 'ELIMINADO'
  ORDER BY OTOR_SolicitudPrestamoMonto.id_individual ASC


  --Garantia Prendaria
  SELECT
    OTOR_Garantias.id
   ,OTOR_Garantias.id_cliente
   ,OTOR_Garantias.id_contrato
   ,OTOR_Garantias.id_solicitud_prestamo
   ,OTOR_Garantias.tipo_garantia
   ,OTOR_GarantiaPrendarias.descripcion
   ,OTOR_GarantiaPrendarias.valor_estimado
   ,OTOR_GarantiaPrendarias.tipo_garantia
   ,ISNULL(OTOR_GarantiaArchivo.id, 0)
   ,ISNULL(OTOR_GarantiaArchivo.extension, '')
  FROM OTOR_Garantias
  INNER JOIN OTOR_GarantiaPrendarias
    ON OTOR_Garantias.id = OTOR_GarantiaPrendarias.id_garantia
  LEFT JOIN OTOR_GarantiaArchivo
    ON OTOR_GarantiaPrendarias.id_garantia = OTOR_GarantiaArchivo.id_garantia
  WHERE OTOR_Garantias.id_cliente = @id_cliente
  AND OTOR_Garantias.id_solicitud_prestamo = @id_solicitud
  AND OTOR_Garantias.tipo_garantia = 'PRENDARIA'
  AND OTOR_GarantiaPrendarias.activo = 1

  --Referencias personales , EN GRUPOS NO TRAERA NADA
  SELECT
    CLIE_R_I.id
   ,CLIE_R_I.id_cliente
   ,CLIE_R_I.id_referencia
   ,CLIE_R_I.id_empleado
   ,ISNULL((SELECT
        CONT_Personas.nombre
      FROM CONT_Personas
      WHERE CONT_Personas.id = CLIE_R_I.id_referencia)
    , '') AS nombre
   ,ISNULL((SELECT
        CONT_Personas.apellido_paterno
      FROM CONT_Personas
      WHERE CONT_Personas.id = CLIE_R_I.id_referencia)
    , '') AS apellido_paterno
   ,ISNULL((SELECT
        CONT_Personas.apellido_materno
      FROM CONT_Personas
      WHERE CONT_Personas.id = CLIE_R_I.id_referencia)
    , '') AS apellido_materno
   ,ISNULL(TELEFONO.Id_Telefono_1,0) AS id_telefono
   ,ISNULL(TELEFONO.Telefono_1,'') AS idcel_telefono
   ,ISNULL(CLIE_R_I.parentesco, '') AS parentesco
   ,ISNULL(CLIE_R_I.tipo_relacion, '') AS tipo_relacion
   ,ISNULL(CLIE_R_I.eliminado, 0) AS eliminado
  FROM CLIE_R_I
  INNER JOIN CLIE_Clientes
    ON CLIE_R_I.id_cliente = CLIE_Clientes.id
  INNER JOIN CLIE_Individual
    ON CLIE_Clientes.id = CLIE_Individual.id_cliente
  INNER JOIN CONT_Personas
    ON CLIE_Individual.id_persona = CONT_Personas.id
  LEFT JOIN (SELECT
      TelefonosPersona.id_persona
     ,Telefono_1.id AS Id_Telefono_1
     ,ISNULL(Telefono_1.idcel_telefono, '') AS Telefono_1
    FROM (SELECT
        TelefonosPersona.id_persona
       ,MIN(Telefonos.id) AS id_telefono_1
      FROM CONT_TelefonosPersona TelefonosPersona
      INNER JOIN CONT_Telefonos Telefonos
        ON TelefonosPersona.id_telefono = Telefonos.id
        AND Telefonos.estatus_registro = 'ACTIVO'
      GROUP BY TelefonosPersona.id_persona) TelefonosPersona
    LEFT JOIN CONT_Telefonos Telefono_1
      ON Telefono_1.id = TelefonosPersona.id_telefono_1) TELEFONO
    ON TELEFONO.id_persona =  CLIE_R_I.id_referencia
  WHERE CONT_Personas.id = (SELECT
      ISNULL(CLIE_Individual.id_persona, 0)
    FROM CLIE_Individual
    WHERE CLIE_Individual.id_cliente = @id_cliente)
  AND ISNULL(CLIE_R_I.eliminado, 0) = 0
  ORDER BY CLIE_R_I.id
  --Informacion Tu Hogar Con Conserva
  SELECT 
  OTOR_TuHogarConConserva.id,
  OTOR_TuHogarConConserva.id_solicitud_prestamo,
  OTOR_TuHogarConConserva.domicilio_actual,
  OTOR_TuHogarConConserva.geolocalizacion_domicilio.Lat as lat,
  OTOR_TuHogarConConserva.geolocalizacion_domicilio.Long as lat,
  OTOR_TuHogarConConserva.id_tipo_obra_financiar,
  OTOR_TuHogarConConserva.tipo_mejora,
  OTOR_TuHogarConConserva.total_score,
  OTOR_TuHogarConConserva.id_color_semaforo_fico_score,
  OTOR_TuHogarConConserva.id_origen_ingresos,
  OTOR_TuHogarConConserva.activo
  FROM OTOR_TuHogarConConserva 
  WHERE OTOR_TuHogarConConserva.id_solicitud_prestamo = @id_solicitud AND OTOR_TuHogarConConserva.activo=1

  SELECT 
  OTOR_TuHogarConConservaCoacreditado.id,
  OTOR_TuHogarConConservaCoacreditado.id_tuhogar_conserva,
  OTOR_TuHogarConConservaCoacreditado.id_persona,
  OTOR_TuHogarConConservaCoacreditado.total_score,
  OTOR_TuHogarConConservaCoacreditado.id_color_semaforo_fico_score,
  OTOR_TuHogarConConservaCoacreditado.activo
  FROM OTOR_TuHogarConConserva INNER JOIN  OTOR_TuHogarConConservaCoacreditado  ON OTOR_TuHogarConConserva.id = OTOR_TuHogarConConservaCoacreditado.id_tuhogar_conserva
  WHERE OTOR_TuHogarConConserva.id_solicitud_prestamo = @id_solicitud AND OTOR_TuHogarConConserva.activo=1
END
GO

--#endregion ------------------------------------- FIN PROCEDURE GET DETAILS LOAN ------------------------------------------ 

--#region ------------------------------------- PROCEDURE GET MASTER PRODUCT INDIVIDUAL ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_ObtenerInformacionProductos
AS
BEGIN
	DECLARE @ProductosMaestrosConfiguracion TABLE
(
    id INT,
	tipo_amortizacion VARCHAR(15),
	tipo_ano VARCHAR(15),
	opcion_redondeo INT,
	opcion_impuesto INT,
	periodicidades VARCHAR(8000),
	periodo_min INT,
	periodo_max INT,
	tasa_anual_min DECIMAL(12, 4),
	tasa_anual_max DECIMAL(12, 4),
	impuesto INT,
	bonificacion DECIMAL(12, 4),
	bonificacion_configuracion text,
	garantia_liquida INT,
	fecha_inicio DATETIME,
	fecha_caducidad DATETIME,
    nombre VARCHAR(100),
	estatus VARCHAR(20),
	monto_redondeo DECIMAL(3,2),
	tipo_cliente INT,
    tipo_credito INT,
    requiere_seguro BIT,
	id_tipo_contrato INT,
	garantia_liquida_financiable BIT,
	creado_por INT,
	modificado_por INT,
	fecha_creacion DATETIME,
	fecha_modificacion DATETIME,
	fico BIT NULL, -- SOLO FUNCIONA EN HBMFS
	configuracion VARCHAR(50),
	valor_minimo DECIMAL(12,4),
	valor_maximo DECIMAL(12,4)
);

	INSERT INTO @ProductosMaestrosConfiguracion
	SELECT CATA_ProductosMaestrosConfiguracion.*,
	CATA_ProductoPoliticas.configuracion,
	CATA_ProductoPoliticas.valor_minimo,
	CATA_ProductoPoliticas.valor_maximo
	FROM CATA_ProductosMaestrosConfiguracion
	INNER JOIN CATA_ProductoPoliticas ON CATA_ProductoPoliticas.id_producto = 4
	WHERE CATA_ProductosMaestrosConfiguracion.id = 4

	INSERT INTO @ProductosMaestrosConfiguracion
	SELECT CATA_ProductosMaestrosConfiguracion.*,
	CATA_ProductoPoliticas.configuracion,
	CATA_ProductoPoliticas.valor_minimo,
	CATA_ProductoPoliticas.valor_maximo
	FROM CATA_ProductosMaestrosConfiguracion
	INNER JOIN CATA_ProductoPoliticas ON CATA_ProductoPoliticas.id_producto = 5
	WHERE CATA_ProductosMaestrosConfiguracion.id = 5

	INSERT INTO @ProductosMaestrosConfiguracion
	SELECT CATA_ProductosMaestrosConfiguracion.*,
	CATA_ProductoPoliticas.configuracion,
	CATA_ProductoPoliticas.valor_minimo,
	CATA_ProductoPoliticas.valor_maximo
	FROM CATA_ProductosMaestrosConfiguracion
	INNER JOIN CATA_ProductoPoliticas ON CATA_ProductoPoliticas.id_producto = 12
	WHERE CATA_ProductosMaestrosConfiguracion.id = 12



	SELECT * FROM @ProductosMaestrosConfiguracion
	-- INSERT INTO @ProductosMaestrosConfiguracion SELECT * FROM CATA_ProductosMaestrosConfiguracion WHERE id = 12
	-- INSERT INTO @ProductosMaestrosConfiguracion SELECT * FROM CATA_ProductosMaestrosConfiguracion WHERE id = 5

	--SELECT P.*,
	--PER.etiqueta as 'periodicidad_etiqueta',
	--PER.codigo as 'periodicidad_codigo',
	--PER.abreviatura as 'periodicidad_abreviatura'
	--FROM CATA_ProductosMaestros AS PM
	--INNER JOIN CATA_Productos AS P ON P.id = PM.id
	--LEFT JOIN CATA_periodicidad AS PER ON UPPER(RTRIM(P.periodicidad)) = UPPER(RTRIM(PER.etiqueta))
	--INNER JOIN FUND_ProductosFondeadores AS PF ON PF.id_producto = P.id
	--WHERE P.status = 'Activo' AND PM.tipo_producto = 'CR�D-INDIVI' AND P.tipo_cliente = 2
END
GO

--#endregion ------------------------------------- FIN PROCEDURE GET MASTER PRODUCT INDIVIDUAL ------------------------------------------ 

--#region ------------------------------------- PROCEDURE GET ACCOUNT STATUS ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_obtenerEstadoCuenta
	@id_cliente INT
AS
BEGIN
	DECLARE @idContrato INT;  
	
	DECLARE @PagosRealizados TABLE (
		id INT,
		id_plan_pago_detalle INT,
		fecha_vencimiento DATE,
		fecha_pago DATE,
		monto_reembolso MONEY,
		monto_principal MONEY,
		monto_interes MONEY,
		monto_impuesto MONEY,
		monto_reembolso_pagado MONEY,
		monto_principal_pagado MONEY,
		monto_interes_pagado MONEY,
		monto_impuesto_pagado MONEY,
		estatus VARCHAR(20), 
		numero_pago INT,
		diasDiferencia INT,
		nombreBanco VARCHAR(50), 
		id_reembolso INT	
	)
	
	DECLARE @PagosPendientes TABLE (
		PEN_id INT,
		PEN_id_plan_pago_detalle INT,
		PEN_fecha_vencimiento DATE,
		PEN_fecha_pago DATE,
		PEN_monto_reembolso MONEY,
		PEN_monto_principal MONEY,
		PEN_monto_interes MONEY,
		PEN_monto_impuesto MONEY,
		PEN_monto_reembolso_pagado MONEY,
		PEN_monto_principal_pagado MONEY,
		PEN_monto_interes_pagado MONEY,
		PEN_monto_impuesto_pagado MONEY,
		PEN_estatus VARCHAR(20), 
		PEN_numero_pago INT,
		PEN_diasDiferencia INT,
		PEN_nombreBranco VARCHAR(50), 
		PEN_id_reembolso INT	
	)
	
	SELECT @idContrato=MAX(id) 
	FROM OTOR_Contratos
	WHERE (id_cliente = @id_cliente )
	AND (estatus = 'DESEMBOLSADO' OR estatus = 'CASTIGADO');	
	 
	--Pagos realizados 
	INSERT INTO @PagosRealizados
	SELECT 
	OTOR_HistorialPlanPagos.id,
	OTOR_HistorialPlanPagos.id_plan_pago_detalle,
	OTOR_DetallePlanPagos.fecha_vencimiento,
	OTOR_HistorialPlanPagos.fecha_pago,
	OTOR_DetallePlanPagos.monto_reembolso_original,
	OTOR_DetallePlanPagos.monto_principal_original,
	OTOR_DetallePlanPagos.monto_interes_original,
	OTOR_DetallePlanPagos.monto_impuesto_original,	
	OTOR_HistorialPlanPagos.monto_reembolso_pagado,
	OTOR_HistorialPlanPagos.monto_principal_pagado,
	OTOR_HistorialPlanPagos.monto_interes_pagado,
	OTOR_HistorialPlanPagos.monto_impuesto_pagado,
	OTOR_HistorialPlanPagos.estatus, 
	OTOR_DetallePlanPagos.numero_pago,
	(
		CASE WHEN OTOR_HistorialPlanPagos.estatus <> 'PARCIAL' 
		THEN datediff(d, fecha_vencimiento, OTOR_HistorialPlanPagos.fecha_pago) 
		ELSE 0 
		END
	) AS diasDiferencia,
	ACCO_Bancos.nombre AS nombreBanco, 
	OTOR_HistorialPlanPagos.id_reembolso
	FROM OTOR_HistorialPlanPagos
	INNER JOIN OTOR_DetallePlanPagos
	ON OTOR_HistorialPlanPagos.id_plan_pago_detalle = OTOR_DetallePlanPagos.id
	INNER JOIN RECU_ContratoEventos 
	ON OTOR_HistorialPlanPagos.id_reembolso = RECU_ContratoEventos.id
	INNER JOIN OTOR_PlanPagos
	ON OTOR_DetallePlanPagos.id_plan_pago = OTOR_PlanPagos.id
	INNER JOIN RECU_Reembolsos 
	ON OTOR_HistorialPlanPagos.id_reembolso = RECU_Reembolsos.id_contrato_evento
	INNER JOIN REPA_DepositoLiquidosBanco 
	ON RECU_Reembolsos.id_deposito_liquido = REPA_DepositoLiquidosBanco.id_deposito_liquido
	INNER JOIN REPA_EstadoCuenta 
	ON REPA_DepositoLiquidosBanco.id_estado_cuenta = REPA_EstadoCuenta.id
	INNER JOIN ACCO_Bancos 
	ON REPA_EstadoCuenta.id_cuenta = ACCO_Bancos.id	  
	WHERE OTOR_PlanPagos.id_contrato = @idContrato 
	AND RECU_ContratoEventos.revertido = 0 
	-- AND OTOR_HistorialPlanPagos.id_plan_pago_detalle IS NULL
	
	--Pagos Pendientes
	INSERT INTO @PagosPendientes	
	SELECT 0, 
	OTOR_DetallePlanPagos.id, 
	fecha_vencimiento, 
	fecha_vencimiento,
	OTOR_DetallePlanPagos.monto_reembolso_original,
	OTOR_DetallePlanPagos.monto_principal_original,
	OTOR_DetallePlanPagos.monto_interes_original,
	OTOR_DetallePlanPagos.monto_impuesto_original,
	monto_reembolso, 
	monto_principal,
	monto_interes, 
	monto_impuesto,	
	'PENDIENTE', 
	OTOR_DetallePlanPagos.numero_pago, 
	0, 
	'', 
	0 
	FROM OTOR_DetallePlanPagos
	INNER JOIN OTOR_PlanPagos
	ON OTOR_DetallePlanPagos.id_plan_pago = OTOR_PlanPagos.id
	LEFT JOIN OTOR_HistorialPlanPagos
	ON OTOR_HistorialPlanPagos.id_plan_pago_detalle = OTOR_DetallePlanPagos.id
	LEFT JOIN RECU_ContratoEventos
	ON OTOR_HistorialPlanPagos.id_reembolso = RECU_ContratoEventos.id 
	WHERE OTOR_PlanPagos.id_contrato = @idContrato 
	AND (OTOR_HistorialPlanPagos.id_plan_pago_detalle IS NULL
	OR OTOR_DetallePlanPagos.numero_pago 
	NOT IN ( SELECT numero_pago FROM @PagosRealizados))
	
	SELECT * FROM @PagosRealizados
	UNION 
	SELECT * FROM @PagosPendientes
	ORDER BY numero_pago

END
GO


--#endregion ------------------------------------- FIN PROCEDURE GET ACCOUNT STATUS ------------------------------------------ 

--#region ------------------------------------- PROCEDURE INSERT CONTRACT  ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_InsertContrato
	@idSolicitudPrestamo INT,
	@idContratoInsertado INT OUTPUT
AS
BEGIN

	BEGIN TRY
		BEGIN TRAN T_PRINCIPAL

		
			--Declaraci�n de variables.
			DECLARE @idContrato INT,
					@idProducto INT,
					@id_cliente INT,
					@idOficialCredito INT = 0,
					@fechaPrimerPago DATE,
					@fechaUltimoPago DATE = '1987-10-06',
					@fechaDesembolso DATE,
					@MontoTotalAutorizado MONEY,
					@montoReembolso MONEY,
					@montoReembolsoLetras VARCHAR(255),
					@montoTotal MONEY,
					@montoTotalLetras VARCHAR(255),
					@autorizadoPor INT,
					@fechaAutorizacion DATE,
					@estatus VARCHAR(12),
					@creadoPor INT,
					@fechaCreacion DATE,
					@subEstatus VARCHAR(12) = 'VIGENTE',
					@idFondeador INT,
					@fondeador VARCHAR(500),
					@idLineaCredito INT,
					@idDisposicion INT,
					@idTipoCliente INT,
					@idAval INT,
					@idServicioFinanciero INT,
					@idOficinaFinanciera INT,
					@id_historial_creacion_contrato INT = 0,
					@monto_garantia_liquida MONEY = 0,
					@monto_bonificacion_estimado MONEY = 0,
					--Variables de Plan pagos
					@opcionRedondeo INT,
					@redondeoFraccion DECIMAL(8, 5),
					@plazo INT,
					@tasaAnual DECIMAL(8, 5),
					@periodicidad VARCHAR(255),
					@opcionImpuesto INT,
					@tasaImpuesto DECIMAL(8, 5),
					@opcionDiasAnio VARCHAR(255),
					@opcionAmortizacionTipo VARCHAR(255),
					@tipoDevengo VARCHAR(255),
					@porcentajeGarantiaLiquida INT,
					@requierenSeguro INT = 0,
					@monto_garantia_liquida_disponible MONEY = 0,
					@monto_asegurado MONEY = 0,
					@monto_prima_seguro_calculado MONEY = 0,
					@seguro_vida MONEY = 0,
					@seguro_vida_deudor MONEY = 0,
					@seguro_vida_total MONEY = 0,
					@monto_asegurado_conserva MONEY = 0,
					@monto_saldo_deudor MONEY = 0,
					@id_individual_min INT = 0,
					@integrantes_saldo_deudor VARCHAR(1000)= '',
					@nombre_aseguradora VARCHAR(500) = 'NO APLICA',
					@monto_adeudo_asegurado MONEY = 0,
					@monto_adeudo_asegurado_conyuge MONEY = 0,
					@idPlanPago INT = 0,
					@diasAnio INT = 0, 
					@idPlanPagoDetalle INT = 0, 
					@fechaInicio DATE, 
					@saldoVigenteAnterior MONEY,
					@_numero_pago INT,
					@_fecha_pago DATE,
					@_monto_reembolso MONEY,
					@_interes MONEY,
					@_impuesto MONEY,
					@_capital MONEY,
					@_saldo_vigente MONEY,
					@numeroTipoAmortizacion INT,
					@minNumero INT,
					@maxNumero INT,
					@tipoPlazo VARCHAR(255) = '',
					@direccion VARCHAR(255) = '',
					@nombre_acreditado VARCHAR(255) = '',
					@id_direccion_acreditado INT = 0,
					@fecha_inicio DATETIME,
					@tipo_contrato VARCHAR(50),
					@cat DECIMAL(6,2) = 0.0,
					@cat_garantia_incluido BIT = 1,
					@cat_bonificacion_incluido BIT = 1,
					@reca VARCHAR(30) = '',
					@bonificacion VARCHAR(500) = '',
					@contrato_declaracion_inciso_c VARCHAR(MAX) = 'NO APLICA.';
		
			DECLARE @_plan_pago_detalle TABLE
			(
				numero_pago INT,
				fecha_pago DATE,
				monto_reembolso MONEY,
				interes MONEY,
				impuesto MONEY,
				capital MONEY,
				saldo_vigente MONEY
			);
			
			DECLARE @_integrantes TABLE
			(
				id_individual INT,
				id_solicitud_prestamo INT,
				nombre VARCHAR(500),
				cargo VARCHAR(255),
				perfil_riesgo VARCHAR(100)
			);

			DECLARE @politicas TABLE
			(
				id INT IDENTITY,
				tasa FLOAT,
				inicio INT,
				fin INT
			);

			DECLARE @TB_Reca TABLE
			(
				reca VARCHAR(30)
			);
			
			SET @fecha_inicio = GETDATE();
   
			--Obtenci�n de datos de la solicitud, fondos y promotor.
			SELECT  @idAval = OTOR_SolicitudPrestamos.id_aval,
					@idProducto = OTOR_SolicitudPrestamos.id_producto,
					@id_cliente = OTOR_SolicitudPrestamos.id_cliente,
					@idOficialCredito = OTOR_SolicitudPrestamos.id_oficial,
					@fechaDesembolso = OTOR_SolicitudPrestamos.fecha_entrega,
					@MontoTotalAutorizado = OTOR_SolicitudPrestamos.monto_financiar,
					@montoReembolso = 0,
					@montoTotal = OTOR_SolicitudPrestamos.monto_total_autorizado,
					@autorizadoPor = OTOR_SolicitudPrestamos.autorizado_por,
					@estatus = 'TRANSITO',
					@creadoPor = OTOR_SolicitudPrestamos.creado_por,
					@subEstatus = '',
					@idDisposicion = OTOR_SolicitudPrestamos.id_disposicion,
					@idServicioFinanciero = OTOR_SolicitudPrestamos.id_servicio_financiero,
					@idTipoCliente = OTOR_SolicitudPrestamos.tipo_cliente,
					@fechaAutorizacion = OTOR_SolicitudPrestamos.fecha_autorizacion,
					@idOficinaFinanciera = OTOR_SolicitudPrestamos.id_oficina,
					@opcionRedondeo = opcion_redondeo,
					@redondeoFraccion = monto_redondeo,
					@plazo = periodos,
					@tasaAnual = tasa_anual,
					@periodicidad = periodicidad,
					@opcionImpuesto = opcion_impuesto,
					@tasaImpuesto =impuesto,
					@opcionDiasAnio = tipo_ano,
					@opcionAmortizacionTipo = tipo_amortizacion,
					@tipoDevengo = ''
			FROM OTOR_SolicitudPrestamos
			WHERE OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo;

			SELECT @idLineaCredito = FUND_LineaCredito.id,
				   @idFondeador = FUND_LineaCredito.id_fondeador,
				   @fondeador = FUND_Fondeadores.nombre_del_fondo
			FROM FUND_Disposicion
			INNER JOIN FUND_LineaCredito
			ON FUND_Disposicion.id_lineacredito = FUND_LineaCredito.id
			INNER JOIN FUND_Fondeadores
			ON FUND_LineaCredito.id_fondeador = FUND_Fondeadores.id
			WHERE FUND_Disposicion.id = @idDisposicion;

			IF(@idOficialCredito = 0)
			BEGIN
				SELECT @idOficialCredito = CLIE_Clientes.id_oficial_credito
				FROM CLIE_Clientes
				WHERE CLIE_Clientes.id = @id_cliente;
			END
			
			--Registro de contrato.
			INSERT INTO OTOR_Contratos(id_solicitud_prestamo, id_producto, id_cliente, id_oficial_credito, fecha_desembolso, monto_total_autorizado, monto_reembolso, monto_total, autorizado_por, 
									   estatus, creado_por, sub_estatus,id_fondeador, id_linea_credito, id_disposicion, id_tipo_cliente, fecha_creacion, fecha_autorizacion)
			VALUES	(@idSolicitudPrestamo, @idProducto, @id_cliente, @idOficialCredito, @fechaDesembolso, @montoTotal, @montoReembolso, @montoTotal, @autorizadoPor, @estatus, @creadoPor, @subEstatus, 
					 @idFondeador, @idLineaCredito, @idDisposicion, @idTipoCliente, GETDATE(), @fechaAutorizacion)
			
			SET @idContrato = SCOPE_IDENTITY();
			SET @idContratoInsertado = @idContrato;
			
			--Registro de auditor�a para verificar horas pico de creaci�n de paquetes.
			/**INSERT INTO OTOR_HistorialCreacionContrato (fecha_creacion,id_contrato,fecha_clr,fecha_bono,fecha_cat,fecha_modificacion)
			VALUES (GETDATE(), @idContrato, NULL, NULL, NULL, NULL)*/
			
			SET @id_historial_creacion_contrato = SCOPE_IDENTITY()
		
			--Obtenci�n de datos del producto.
			SELECT	@opcionRedondeo = CATA_Productos.opcion_redondeo,
					@redondeoFraccion = CATA_Productos.monto_redondeo,
					@plazo = CATA_Productos.periodos,
					@tasaAnual = CATA_Productos.tasa_anual,
					@periodicidad = CATA_Productos.periodicidad,
					@opcionImpuesto = CATA_Productos.opcion_impuesto,
					@tasaImpuesto = CATA_Productos.impuesto,
					@opcionDiasAnio = CATA_Productos.tipo_ano,
					@opcionAmortizacionTipo = CATA_Productos.tipo_amortizacion, 
					@tipoDevengo = '',
					@porcentajeGarantiaLiquida = CATA_Productos.garantia_liquida,
					@diasAnio = (CASE CATA_Productos.tipo_ano WHEN '52 Semanas' THEN 52 * 7 WHEN 'Comercial' THEN 360 WHEN 'Natural' THEN 365 ELSE 1 END),
					@tipo_contrato = CATA_Productos.tipo_contrato
			FROM CATA_Productos
			WHERE CATA_Productos.id = @idProducto;

			--Obtenci�n de tipo de amortizaci�n
			IF(@opcionAmortizacionTipo = 'PI BA/PD')
			BEGIN
				SET @numeroTipoAmortizacion = 0;
				SET @opcionAmortizacionTipo = 'Pagos Iguales (Base Anual/Promedio de Días en el Periodo)';
			END
			IF(@opcionAmortizacionTipo = 'PI BA/DE')
			BEGIN
				SET @numeroTipoAmortizacion = 1;
				SET @opcionAmortizacionTipo = 'Pagos Iguales (Base Anual/Promedio de Días en el Periodo)';
			END
			IF(@opcionAmortizacionTipo = 'PV BA/PD')
			BEGIN
				SET @numeroTipoAmortizacion = 2;
				SET @opcionAmortizacionTipo = 'Pagos Variables (Base Anual/Promedio de Días en el Periodo)';
			END
			IF(@opcionAmortizacionTipo = 'PV BA/DE')
			BEGIN
				SET @numeroTipoAmortizacion = 3;
				SET @opcionAmortizacionTipo = 'Pagos Variables (Base Anual/Días Efectivamente Transcurridos en el Periodo)';
			END

	
			--Obteneci�n del calendario de pagos.
			INSERT INTO @_plan_pago_detalle
			EXEC uspGenerarCalendarioPagos @opcionRedondeo, 0, @redondeoFraccion, @plazo, @tasaAnual, @periodicidad, @montoTotal, @fechaDesembolso,
											@opcionImpuesto, @tasaImpuesto, @opcionDiasAnio, @numeroTipoAmortizacion, 0, 'Ninguna', 0

			
			--Si existen registros se continua con el proceso.
			IF((SELECT COUNT(numero_pago) FROM @_plan_pago_detalle) > 0)				    
			BEGIN							
				INSERT INTO OTOR_PlanPagos(id_contrato, opcion_redondeo_pagos, opcion_redondeo_ultimo, redondeo_fraccion, plazo, tasa_anual, tasa_diaria, periodicidad, 
										   monto_total_autorizado, fecha_desembolso, opcion_impuesto, tasa_impuesto, opcion_dias_anio, opcion_amortizacion_tipo) 
				VALUES(@idContrato, @opcionRedondeo, 0, @redondeoFraccion, @plazo, @tasaAnual, (@tasaAnual/CAST(@diasAnio AS DECIMAL)), @periodicidad, @montoTotal, @fechaDesembolso,
					   @opcionImpuesto, @tasaImpuesto, @opcionDiasAnio,@numeroTipoAmortizacion);
				
				SET @idPlanPago = SCOPE_IDENTITY();	   
				SET @fechaInicio = @fechaDesembolso;
				SET @saldoVigenteAnterior = @montoTotal;
				DECLARE @dia_global INT=0;
				
				SET NOCOUNT ON;
				DECLARE crs_plan_pago_detalle CURSOR FOR
					SELECT   numero_pago, fecha_pago, monto_reembolso, interes,	impuesto, capital, saldo_vigente
					FROM	 @_plan_pago_detalle   
				OPEN crs_plan_pago_detalle
				FETCH NEXT FROM crs_plan_pago_detalle
					INTO @_numero_pago,	@_fecha_pago, @_monto_reembolso, @_interes,	@_impuesto,	@_capital, @_saldo_vigente
				WHILE (@@FETCH_STATUS = 0)
				BEGIN 
					SET @idPlanPagoDetalle = 0;
					
					INSERT INTO OTOR_DetallePlanPagos (id_plan_pago, numero_pago, estatus, monto_reembolso_original, monto_principal_original, monto_interes_original, monto_impuesto_original, monto_capital_vivo_original, fecha_vencimiento, monto_reembolso,
							monto_principal, monto_interes, monto_impuesto, monto_capital_vivo, fecha_pago, tasa_impuesto, monto_reembolso_pagado, monto_principal_pagado, monto_interes_pagado, monto_impuesto_pagado, devengado, vencido, devengo_contable, vencido_contable) 
					VALUES(@idPlanPago, @_numero_pago, 'PENDIENTE', @_monto_reembolso, @_capital, @_interes, @_impuesto, @_saldo_vigente, @_fecha_pago, @_monto_reembolso, @_capital, @_interes, @_impuesto, @_saldo_vigente, NULL, @tasaImpuesto, 0, 0, 0, 0, 0, 0, 0, 0);
					
					SET @idPlanPagoDetalle = SCOPE_IDENTITY();
					
					INSERT INTO OTOR_PlanPagosDiario(id_plan_pago_detalle, id_dia, id_dia_ciclo, estatus, monto_reembolso_original, monto_principal_original, monto_interes_original, monto_impuesto_original, monto_capital_vivo_anterior_original, fecha_vencimiento, monto_reembolso,
													 monto_principal, monto_interes, monto_impuesto, monto_capital_vivo_anterior, tasa_impuesto) 
					SELECT @idPlanPagoDetalle,
						   no_dia_global,
						   no_dia_periodo,
						   'PENDIENTE',
						   monto_reembolso,
						   monto_capital,
						   monto_interes,
						   monto_impuesto,
						   monto_capital_vivo_anterior,
						   fecha_vencimiento,
						   monto_reembolso,
						   monto_capital,
						   monto_interes,
						   monto_impuesto,
						   monto_capital_vivo_anterior,
						   @tasaImpuesto
					FROM dbo.ufnGenerarCalendarioPagosDetalle(@dia_global, @fechaInicio, @_fecha_pago, @_monto_reembolso, @_capital, @_interes, @_impuesto, @saldoVigenteAnterior);
					
					SELECT @dia_global=MAX(id_dia) FROM OTOR_PlanPagosDiario WHERE id_plan_pago_detalle=@idPlanPagoDetalle;

					SET @fechaInicio = @_fecha_pago;
					SET @saldoVigenteAnterior = @_saldo_vigente;
					    
					FETCH NEXT FROM crs_plan_pago_detalle
					INTO @_numero_pago,	@_fecha_pago, @_monto_reembolso, @_interes,	@_impuesto,	@_capital, @_saldo_vigente
				END  							    
				CLOSE crs_plan_pago_detalle;  
				DEALLOCATE crs_plan_pago_detalle;  					    
			END	
			
			--Validaci�n para el detalle del calendario de pagos.	    
			IF ((SELECT COUNT(OTOR_PlanPagosDiario.id) FROM OTOR_PlanPagosDiario INNER JOIN OTOR_DetallePlanPagos ON OTOR_PlanPagosDiario.id_plan_pago_detalle = OTOR_DetallePlanPagos.id WHERE OTOR_DetallePlanPagos.id_plan_pago = @idPlanPago) = 0)
			BEGIN
				ROLLBACK TRAN T_PRINCIPAL
				PRINT 'ERROR: No se obtuvo el calendario de pagos.';
				INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
				VALUES (@idContrato, 11, 2, 'uspGenerarCalendarioPagos', 0, 'No se obtuvo el calendario de pagos.', 'OTOR_InsertContrato');
				RETURN;
			END

			--Obtenci�n de las fechas de primer y �ltmimo pago y del monto reembolso.
			SELECT @fechaPrimerPago = MIN(OTOR_DetallePlanPagos.fecha_vencimiento),
				   @fechaUltimoPago = MAX(OTOR_DetallePlanPagos.fecha_vencimiento),
				   @minNumero = MIN(OTOR_DetallePlanPagos.numero_pago)
			FROM OTOR_DetallePlanPagos
			WHERE OTOR_DetallePlanPagos.id_plan_pago = @idPlanPago;
			
			SELECT @montoReembolso = OTOR_DetallePlanPagos.monto_reembolso
			FROM OTOR_DetallePlanPagos
			WHERE OTOR_DetallePlanPagos.id_plan_pago = @idPlanPago
			AND OTOR_DetallePlanPagos.numero_pago = @minNumero;
			
			--Actualizaci�n del contrato.
			UPDATE OTOR_Contratos
			SET OTOR_Contratos.fecha_primer_pago = @fechaPrimerPago,
				OTOR_Contratos.fecha_ultimo_pago = @fechaUltimoPago,
				OTOR_Contratos.monto_reembolso = @montoReembolso
			WHERE OTOR_Contratos.id = @idContrato;
			
			--Obtenemos los montos en letras.
			SET @montoTotalLetras = dbo.convertirCantidadLetras(@montoTotal, 1);
			SET @montoReembolsoLetras = dbo.convertirCantidadLetras(@montoReembolso, 1);
			
			--Aclaracion de Periodicidad y numero de periodos*/
			SET @tipoPlazo = CASE @periodicidad
							 WHEN 'Diario' THEN ' Días'
							 WHEN 'Semanal' THEN ' Semanas'
							 WHEN 'Catorcenal' THEN ' Catorcenas'
							 WHEN 'Quincenal' THEN ' Quincenas'
							 WHEN 'Mensual' THEN ' Meses'
							 WHEN 'Bimestral' THEN ' Bimestral'
							 WHEN 'Trimestral' THEN ' Trimestres'
							 WHEN 'Cuatrimestral' THEN ' Cuatrimestres'
							 WHEN 'Semestral' THEN ' Semestres'
							 WHEN 'Anual' THEN ' Años'
							 ELSE @periodicidad END;

			--Obtenci�n de integrantes.
			INSERT INTO @_integrantes
			SELECT 
					OTOR_SolicitudPrestamoMonto.id_individual,
					OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo,
					(CONT_Personas.nombre + ' ' + CONT_Personas.apellido_paterno + ' ' + CONT_Personas.apellido_materno) AS nombre,
					OTOR_SolicitudPrestamoMonto.cargo,
					OTOR_SolicitudPrestamoMonto.perfil_riesgo
			FROM CONT_Personas
			INNER JOIN CLIE_Individual
			ON CLIE_Individual.id_persona = CONT_Personas.id
			INNER JOIN OTOR_SolicitudPrestamoMonto
			ON CLIE_Individual.id_cliente = OTOR_SolicitudPrestamoMonto.id_individual
			WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = @idSolicitudPrestamo
			AND OTOR_SolicitudPrestamoMonto.autorizado = 1;

			--Obtenci�n del inciso c del contrato.
			IF(@idFondeador = 19)--FINAFIM
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 14 DE JULIO DEL 2008 Y 1 DE JUNIO DEL 2009, CELEBRO CONTRATO DE CRÉDITO SIMPLE CON GARANTÍA PRENDARIA CON NACIONAL FINANCIERA, SOCIEDAD NACIONAL DE CRÉDITO, COMO FIDUCIARIA EN EL FIDEICOMISO DEL PROGRAMA NACIONAL DE FINANCIAMIENTO AL MICROEMPRESARIO.';
			END	
			ELSE IF(@idFondeador = 20) --FET
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 31 DE JULIO DEL 2008 Y 17 DE MAYO DEL 2010 , CELEBRO CONVENIO MODIFICATORIO AL CONTRATO DE APERTURA DE  CRÉDITO SIMPLE CON GARANTÍA PRENDARIA, CON NACIONAL FINANCIERA S.N.C., COMO FIDUCIARIA DEL FIDEICOMISO DENOMINADO FONDO EMPRESARIAL DE TABASCO, PARA OBTENER FINANCIAMIENTO Y PODER OTORGAR CRÉDITOS A EMPRESA ESTABLECIDAS O POR ESTABLECERSE EN EL ESTADO DE TABASCO.';
			END	
			ELSE IF(@idFondeador = 21) --RECURSOS PROPIOS
			BEGIN
				SET @contrato_declaracion_inciso_c = 'NO APLICA.';
			END	
			ELSE IF(@idFondeador = 24) --BAJIO
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 25 DE OCTUBRE DE 2011 CELEBRÓ CONTRATO DE APERTURA DE CRÉDITO EN CUENTA CORRIENTE CON BANCO DEL BAJIO, SOCIEDAD ANÓNIMA, INSTITUCIÓN DE BANCA MÚLTIPLE, MISMO QUE SE RATIFICA ANTE LA FE DEL NOTARIO PUBLICO NÚMERO 240 EN LEGAL EJERCICIO EN LA CIUDAD DE MÉXICO, DISTRITO FEDERAL, CUYO DESTINO ES EL OTORGAMIENTO DE CRÉDITOS PARA CAPITAL DE TRABAJO EN ACTIVIDADES AGRÍCOLAS, PECUARIAS, PESQUERAS, PEQUEÑO COMERCIO, SERVICIOS Y TRANSFORMACIÓN (MICROCRÉDITO PARA EL MEDIO RURAL), EN FAVOR DE PRODUCTORES PERTENECIENTES A LOS ESTRATOS PD1 Y/O PD2 Y/O PD3, DE CONFORMIDAD CON LA NORMATIVIDAD DE LOS FIDEICOMISOS INSTITUIDOS EN RELACIÓN CON LA AGRICULTURA (FIRA).';
			END	
			IF(@idFondeador = 25) --MIFEL
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 23 DE AGOSTO DEL 2010 CELEBRÓ CONTRATO DE APERTURA DE CRÉDITO EN CUENTA CORRIENTE CON BANCA MIFEL S.A INSTITUCION DE BANCA MULTIPLE GRUPO FINANCIERO MIFEL, MISMO QUE SE RATIFICA ANTE LA FE DEL NOTARIO PÚBLICO NÚMERO 18 EL LICENCIADO JOSE ANTONIO GONZALEZ SOLORZANO EN LEGAL EJERCICIO EN LA CIUDAD DE TUXTLA GUTIERREZ CHIAPAS, CUYO DESTINO ES EL OTORGAMIENTO DE CRÉDITOS DE HABILITACIÓN O AVÍO PARA CAPITAL DE TRABAJO (PARA ADQUISICIÓN DE MATERIA PRIMA, MANO DE OBRA, CUENTAS POR COBRAR.';
			END	
			ELSE IF(@idFondeador = 26) --RESPONSABILITY
			BEGIN
				SET @contrato_declaracion_inciso_c = 'NO APLICA.';
			END
			ELSE IF(@idFondeador = 29) --FINANCIERA RURAL
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 06 DE NOVIEMBRE DEL 2012 CELEBRÓ CONTRATO DE LINEA DE CRÉDITO EN CUENTA CORRIENTE PARA GENERACIÓN DE CARTERA CON FINANCIERA RURAL, RATIFICADO ANTE EL LICENCIADO WENCESLAO CAMACHO CAMACHO, TITULAR DE LA NOTARÍA PÚBLICA NÚMERO 25 DE LA CIUDAD DE TUXTLA GUTIÉRREZ.';
			END
			ELSE IF(@idFondeador = 30) --GLOBAL PARTNERSHIPS
			BEGIN
				SET @contrato_declaracion_inciso_c = 'NO APLICA.';
			END
			IF(@idFondeador = 31)-- FOMMUR
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 06 DE JULIO DE 2017, CELEBRO CONTRATO DE CRÉDITO ESTRATÉGICO SIMPLE CON GARANTÍA LÍQUIDA, PRENDARIA Y OBLIGACIÓN SOLIDARIA CON NACIONAL FINANCIERA,SOCIEDAD NACIONAL DE CRÉDITO, INSTITUCIÓN DE BANCA DE DESARROLLO, COMO FIDUCIARIA EN EL FIDEICOMISO DEL FONDO DE MICROFINANCIAMIENTO A MUJERES RURALES. ';
			END	
			IF(@idFondeador = 32)--BANSEFI
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 20 DE JULIO DE 2018 CELEBRÓ CONTRATO DE LÍNEA DE CRÉDITO EN CUENTA CORRIENTE PARA GENERACIÓN DE CARTERA CON BANCO DEL AHORRO NACIONAL Y SERVICIOS FINANCIEROS, SOCIEDAD NACIONAL DE CRÉDITO, INSTITUCIÓN DE BANCA DE DESARROLLO, CUYO DESTINO ES EL OTORGAMIENTO DE CRÉDITOS PARA CAPITAL DE TRABAJO EN CUALQUIER ACTIVIDAD ECONÓMICA LÍCITA, EXCEPTO ACTIVIDADES PRIMARIAS.';
			END
			IF(@idFondeador = 33)--SOCIEDAD HIPOTECARIA FEDERAL
			BEGIN
				SET @contrato_declaracion_inciso_c = 'CON FECHA 22 DE DICIEMBRE DE 2021 CELEBRÓ CONTRATO DE LÍNEA DE CRÉDITO CON SOCIEDAD HIPOTECARIA FEDERAL, SOCIEDAD NACIONAL DE CRÉDITO, INSTITUCIÓN DE BANCA DE DESARROLLO CUYO DESTINO ES EL OTORGAMIENTO DE CRÉDITO PARA MEJORA DE VIVIENDA.';
			END

			--Obtememos el Reca Segun el tipo de cliente
			INSERT INTO @TB_Reca 
			EXEC HF_uspObtenerDatosReca @idTipoCliente,@tipo_contrato,1
			
			SELECT @reca = reca FROM @TB_Reca

			--Cliente: Grupo Solidario
			IF(@idTipoCliente = 1)
			BEGIN
				--Declarar variables 
				DECLARE @nombresIntegrantes VARCHAR(1000) = '',
						@noIntegrantes INT = 0,
						@presidenta VARCHAR(255) = '',
						@secretaria VARCHAR(255) = '',
						@tesorera VARCHAR(255) = '',
						@areaEnEstado VARCHAR(255) = '',
						@idClienteFormato VARCHAR(100) = @id_cliente,
						@referenciaBancaria VARCHAR(100) = @id_cliente,
						@plazoPagos VARCHAR(100) = '',
						@numeroCuenta VARCHAR(100) = @id_cliente,
						@dia VARCHAR(10) = 'día',
						@mes VARCHAR(20) = @fechaDesembolso,
						@anio VARCHAR(10) = 'año',
						@banco VARCHAR(50) = @id_cliente,
						@direccionOficinaFinanciera VARCHAR(255) = '';
					
						

				--Inicializacion de los campos
				--SET   @reca = '1662-140-015799/01-00991-0314';--2015
				--SET   @reca = '1662?140?015799/02?10304?1215';--2016
				--SET	@reca='1662-140-015799/03-03632-1016'--Octubre 2016
				--SET	@reca='1662-140-015799/05-05458-1017'--Mayo 2017
				--SET	@reca='1662-140-015799/06-03531-0718' -- Julio 2018

				--SET	@reca='1662-140-015799/07-03512-0819' --Agosto 2019

				--SET @reca='1662-140-015799/08-02870-0820' --1 de Septiembre de 2020

				--IF(@tipo_contrato = 'CONSERVA TE ACTIVA' OR @tipo_contrato = 'CONSERVA T ACTIVA')
				--BEGIN
				--	SET @reca = '1662-140-033701/01-03551-1020' -- Octubre de 2020
				--END

				SET @cat_garantia_incluido = 1; --Se incluye el monto de garant�a l�quida en la generaci�n del cat.
				SET @cat_bonificacion_incluido = 1; --Se incluye el monto estimado de bonificaci�n l�quida en la generaci�n del cat.
				SET @nombre_acreditado = '';
				
				--Obtenci�n de los datos del grupo.
				SELECT @nombre_acreditado = CLIE_Grupos.nombre,
					   @id_direccion_acreditado = CLIE_Grupos.id_direccion
				FROM CLIE_Grupos
				WHERE CLIE_Grupos.id_cliente = @id_cliente;
				
				SELECT @nombresIntegrantes = @nombresIntegrantes + nombre + ', '
				FROM @_integrantes
				
				--Obtenci�n de la mesa directiva.
				SELECT @presidenta = nombre
				FROM @_integrantes 
				WHERE cargo = 'Presidenta(e)';
				
				SELECT @secretaria = nombre
				FROM @_integrantes 
				WHERE cargo = 'Secretaria(o)';
				
				SELECT @tesorera = nombre
				FROM @_integrantes 
				WHERE cargo = 'Tesorera(o)';
				
				SELECT @noIntegrantes = COUNT(nombre)
				FROM @_integrantes;
				
				--Obtenci�n de los datos de direcci�n
				SELECT	@direccion = CONT_Direcciones.direccion, 
						@areaEnEstado = CATA_ciudad_localidad.etiqueta
				FROM CONT_Direcciones
				INNER JOIN CATA_ciudad_localidad
				ON CONT_Direcciones.localidad = CATA_ciudad_localidad.id
				WHERE CONT_Direcciones.id = @id_direccion_acreditado;
				
				--Obtenemos la direccion de la oficina financiera
				SELECT @direccionOficinaFinanciera = UPPER(CONT_Direcciones.direccion) + ', ' + ISNULL(CATA_TipoVialidad.descripcion,'') + '. ' + UPPER(CATA_ciudad_localidad.etiqueta) + ', ' + UPPER(CATA_estado.etiqueta)
				FROM CONT_Direcciones
				INNER JOIN CONT_Oficinas
				ON CONT_Direcciones.id = CONT_Oficinas.id_direccion
				INNER JOIN CORP_OficinasFinancieras
				ON CONT_Oficinas.id = CORP_OficinasFinancieras.id_oficina
				INNER JOIN CATA_ciudad_localidad
				ON CONT_Direcciones.localidad = CATA_ciudad_localidad.id
				INNER JOIN CATA_estado
				ON CONT_Direcciones.estado = CATA_estado.id
				LEFT JOIN CATA_TipoVialidad 
				ON CONT_Direcciones.vialidad = CATA_TipoVialidad.id
				WHERE CORP_OficinasFinancieras.id = @idOficinaFinanciera;

				--Obtenemos el monto de garant�a l�quida.
				IF(@cat_garantia_incluido = 1)
				BEGIN
					--SELECT @monto_garantia_liquida = OTOR_Contratos.monto_total_autorizado * (CAST(@porcentajeGarantiaLiquida AS DECIMAL) / 100)
					--FROM OTOR_Contratos
					--WHERE OTOR_Contratos.id = @idContrato;

					SELECT @monto_garantia_liquida = SUM(( PMONTO.monto_autorizado - PMONTO.monto_garantia_financiable )* (CAST(@porcentajeGarantiaLiquida AS DECIMAL) / 100))
					FROM OTOR_Contratos
					INNER JOIN OTOR_SolicitudPrestamoMonto PMONTO ON PMONTO.id_solicitud_prestamo = OTOR_Contratos.id_solicitud_prestamo
					WHERE OTOR_Contratos.id = @idContrato
					AND PMONTO.autorizado = 1;					
				END

				--Obtenci�n del seguro
				SELECT @requierenSeguro = dbo.ufnGetNoSociasAseguradas(@idSolicitudPrestamo)


				IF(@requierenSeguro > 0)
				BEGIN
					SELECT
					@seguro_vida = --SUM(ISNULL(CATA_ProductoSeguro.monto_prima_seguro_calculado,0))
					COALESCE(SUM
					(
						CATA_ProductoSeguro.monto_prima_seguro_calculado
					),0)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE
					OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					GROUP BY
					OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo

					SELECT
					@seguro_vida_deudor = --SUM(ISNULL(CATA_ProductoSeguro.monto_prima_seguro_calculado,0))
					COALESCE(SUM
					(
						CATA_ProductoSeguro.monto_saldo_deudor
					),0)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE
					OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					AND CLIE_DetalleSeguro.incluye_saldo_deudor = 1
					GROUP BY
					OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo

					SELECT TOP(1)
						   @monto_asegurado=ISNULL(CATA_ProductoSeguro.monto_asegurado,0),
						   @monto_prima_seguro_calculado=ISNULL(CATA_ProductoSeguro.monto_prima_seguro_calculado,0),
						   @monto_asegurado_conserva = ISNULL(CATA_ProductoSeguro.monto_asegurado_conserva,0),
						   @monto_saldo_deudor = ISNULL(CATA_ProductoSeguro.monto_saldo_deudor,0)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CATA_seguros ON CATA_seguros.id = CATA_ProductoSeguro.id_seguro
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE
					OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					ORDER BY OTOR_SolicitudPrestamoMonto.id DESC

					SET @seguro_vida_total = @seguro_vida_deudor + @seguro_vida

					/*TABLA CON LAS INTEGRANTES DEL GRUPO QUE TIENEN SEGURO DEUDOR*/
					SELECT @id_individual_min = MIN(OTOR_SolicitudPrestamoMonto.id_individual)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CATA_seguros ON CATA_seguros.id = CATA_ProductoSeguro.id_seguro
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE
					OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					AND CLIE_DetalleSeguro.incluye_saldo_deudor = 1
					
					WHILE (@id_individual_min IS NOT NULL)
					BEGIN
					
						SELECT @integrantes_saldo_deudor = @integrantes_saldo_deudor + ', ' + nombre_cliente FROM vwCLIE_Clientes WHERE id_cliente = @id_individual_min

						--SELECT @integrantes_saldo_deudor;

						SELECT @id_individual_min = MIN(OTOR_SolicitudPrestamoMonto.id_individual)
						FROM OTOR_SolicitudPrestamoMonto
						INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
						AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
						INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
						INNER JOIN CATA_seguros ON CATA_seguros.id = CATA_ProductoSeguro.id_seguro
						INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
						INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
						INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
						WHERE
						OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
						AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
						AND OTOR_SolicitudPrestamoMonto.autorizado = 1
						AND CLIE_DetalleSeguro.incluye_saldo_deudor = 1
						AND OTOR_SolicitudPrestamoMonto.id_individual > @id_individual_min
					
					END

					SELECT @integrantes_saldo_deudor = SUBSTRING (@integrantes_saldo_deudor,2,1000)
					
					SET @requierenSeguro=1
				END

				/*SELECT @monto_garantia_liquida_disponible=ISNULL(OTOR_GarantiaLiquidas.monto,0) FROM OTOR_GarantiaLiquidas
				INNER JOIN OTOR_Garantias ON OTOR_GarantiaLiquidas.id_garantia=OTOR_Garantias.id AND RTRIM(LTRIM(OTOR_Garantias.tipo_garantia))='LIQUIDA'
				AND OTOR_Garantias.id_cliente=@idGrupo*/

				--Obtenemos el monto de bonificaci�n estimado para el grupo.
				IF(@cat_bonificacion_incluido = 1)
				BEGIN
					IF EXISTS (SELECT PACK_Ciclos.id FROM PACK_Ciclos WHERE PACK_Ciclos.id_producto = @idProducto AND PACK_Ciclos.tipo_politica = 'BONIFICACION')
					BEGIN
						--Si es un producto que tiene pol�ticas, sumamos los montos de cada socia.
						SELECT @monto_bonificacion_estimado = COALESCE(SUM(monto_bonificacion_socia),0)-- + SUM(monto_impuesto_bonificacion_socia)
						FROM dbo.ufnSimularEstimacionBonificacion(@idContrato)
					END
					ELSE
					BEGIN
						--Si es un producto que no tiene pol�ticas, sumamos los montos globales.
						SELECT @monto_bonificacion_estimado = COALESCE(SUM(monto_bonificacion_global),0)-- + SUM(monto_impuesto_bonificacion_global)
						FROM dbo.ufnSimularEstimacionBonificacion(@idContrato)
					END
					
					/*UPDATE OTOR_HistorialCreacionContrato SET fecha_bono=GETDATE() WHERE id=@id_historial_creacion_contrato*/
			
				END

				--C�lculo del CAT.
				SELECT @cat = CAST(dbo.ufnCalcularCAT(@idContrato, 0, 0, @seguro_vida_total, 0, @monto_garantia_liquida-@seguro_vida_total, @monto_bonificacion_estimado) AS DECIMAL(6,2))

				--Validaci�n de variables.
				IF (@cat IS NULL OR @cat <=0) 
				BEGIN
					ROLLBACK TRAN T_PRINCIPAL
					PRINT 'ERROR: No se obtuvo un valor de CAT valido.';
					INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
					VALUES (@idContrato, 11, 2, 'uspGenerarCalendarioPagos', 0, 'No se obtuvo un valor de CAT valido:' + CAST(@cat AS VARCHAR(5)) , 'OTOR_InsertContrato');
					RETURN;
					--SET @cat = 0;
				END

				IF @monto_bonificacion_estimado IS NULL
				BEGIN
					SET @monto_bonificacion_estimado = 0;
				END

				/*Insertamos los datos en OTOR_ContratoGrupal*/
				INSERT INTO OTOR_ContratoGrupal(no_folio,grp_nombre,nombres_integrantes,no_integrantes,presidenta,secretaria,tesorera,direccion,area_en_estado,id_cliente_formato,referencia_bancaria,monto_solicitado,monto_solicitado_letras,
												plazo_pagos,frecuencia_pagos,monto_reembolso,monto_reembolso_letras,plazo,tipo_plazo,numero_cuenta,tasa_capa,dia, mes, anio, banco, direccion_contrato, porcentaje_garantia_liquida, reca, 
												monto_bonificacion_estimado, cat, cat_garantia_incluido, cat_bonificacion_incluido,nombre_fondeador
												,monto_asegurado
												,monto_prima_seguro
												,monto_prima_seguro_grupal
												,monto_garantia
												,requiere_seguro
												,monto_asegurado_conserva
												,monto_saldo_deudor
												,integrantes_seguro_deudor
												,monto_saldo_deudor_grupo )
				VALUES (@idContrato,@nombre_acreditado,@nombresIntegrantes,@noIntegrantes,@presidenta,@secretaria,@tesorera,@direccion,@areaEnEstado,@idClienteFormato,@referenciaBancaria,@montoTotal,@montoTotalLetras,@plazoPagos,@periodicidad,
						@montoReembolso,@montoReembolsoLetras,@plazo,@tipoPlazo,@numeroCuenta,@tasaAnual,@dia,@mes,@anio,@banco, @direccionOficinaFinanciera,@porcentajeGarantiaLiquida, @reca, @monto_bonificacion_estimado, @cat,
						@cat_garantia_incluido, @cat_bonificacion_incluido,@fondeador
						,@monto_asegurado
						,@monto_prima_seguro_calculado
						,@seguro_vida
						--,@monto_garantia_liquida-@seguro_vida_total
						,CASE WHEN @porcentajeGarantiaLiquida > 0 THEN @monto_garantia_liquida-@seguro_vida_total ELSE 0 END
						,CAST(@requierenSeguro AS BIT)
						,@monto_asegurado_conserva
						,@monto_saldo_deudor
						,@integrantes_saldo_deudor
						,@seguro_vida_deudor );
			
			END
			
			--Cliente: Individual
			ELSE IF(@idTipoCliente = 2)
			BEGIN
				
				--SET @reca = '1662-439-031480/01-01704-0419';

				--IF(@tipo_contrato = 'INDIVIDUAL HOGAR' OR @tipo_contrato = 'TU HOGAR CON CONSERVA')
				--BEGIN
				--	SET @reca = '1662-439-035706/01-00048-0122' -- Enero 06 2022
				--END

				SET @cat_garantia_incluido = 1; --Se incluye el monto de garant�a l�quida en la generaci�n del cat.
				SET @cat_bonificacion_incluido = 1; --Se incluye el monto estimado de bonificaci�n l�quida en la generaci�n del cat.

				--Obtenci�n de bonificaci�n
				INSERT INTO @politicas 
				SELECT PACK_CiclosDetalles.tasa,
					   PACK_CiclosDetalles.inicio,
					   PACK_CiclosDetalles.fin
				FROM PACK_CiclosDetalles 
				INNER JOIN PACK_Ciclos ON PACK_CiclosDetalles.id_pack_ciclo = PACK_Ciclos.id
				WHERE PACK_Ciclos.tipo_politica = 'BONIFICACION'
				AND PACK_Ciclos.id_producto = @idProducto;

				IF((SELECT COUNT(*) FROM @politicas) = 0)
				BEGIN
					SET @bonificacion =  'NO APLICA'
				END
				ELSE
				BEGIN
					DECLARE @NoRow INT = 1, @INICIO INT = 0, @FIN INT = 0, @TASA MONEY = 0.0;
					WHILE @NoRow <= (SELECT COUNT(*) FROM @politicas)
					BEGIN
						SELECT @INICIO = inicio, @FIN = fin, @TASA = tasa FROM @politicas WHERE id = @NoRow
						IF(@INICIO = 0)
						BEGIN
							SET @INICIO = 1
						END
						SET @bonificacion = (@bonificacion + ' DEL CICLO ' + CAST(@INICIO AS VARCHAR(2)) + ' AL ' + CAST(@FIN AS VARCHAR(2)) + ': ' + CAST(@TASA AS VARCHAR(20)) + '%. ');
						SET @NoRow = (@NoRow + 1)
					END
				END

				--Obtenemos el monto de garant�a l�quida.
				IF(@cat_garantia_incluido = 1)
				BEGIN
					
					--SELECT @monto_garantia_liquida = OTOR_Contratos.monto_total_autorizado * (CAST(@porcentajeGarantiaLiquida AS DECIMAL) / 100)
					--FROM OTOR_Contratos
					--WHERE OTOR_Contratos.id = @idContrato;

					SELECT @monto_garantia_liquida = SUM(( PMONTO.monto_autorizado - PMONTO.monto_garantia_financiable )* (CAST(@porcentajeGarantiaLiquida AS DECIMAL) / 100))
					FROM OTOR_Contratos
					INNER JOIN OTOR_SolicitudPrestamoMonto PMONTO ON PMONTO.id_solicitud_prestamo = OTOR_Contratos.id_solicitud_prestamo
					WHERE OTOR_Contratos.id = @idContrato
					AND PMONTO.autorizado = 1;
        

				END

				--Obtenemos el monto de bonificaci�n estimado para el grupo.
				IF(@cat_bonificacion_incluido = 1)
				BEGIN
					IF EXISTS (SELECT PACK_Ciclos.id FROM PACK_Ciclos WHERE PACK_Ciclos.id_producto = @idProducto AND PACK_Ciclos.tipo_politica = 'BONIFICACION')
					BEGIN
						--Si es un producto que tiene pol�ticas, sumamos los montos de cada socia.
						SELECT @monto_bonificacion_estimado = ISNULL(SUM(monto_bonificacion_socia), 0)-- + SUM(monto_impuesto_bonificacion_socia)
						FROM dbo.ufnSimularEstimacionBonificacion(@idContrato)
					END
					/*REVISAR COMO CORREGIR EL PORCENTAJE DE BONO GLOBAL*/
					
					ELSE
					BEGIN
						--Si es un producto que no tiene pol�ticas, sumamos los montos globales.
						SELECT @monto_bonificacion_estimado = ISNULL(SUM(monto_bonificacion_global), 0)-- + SUM(monto_impuesto_bonificacion_global)
						FROM dbo.ufnSimularEstimacionBonificacion(@idContrato)
					END
					
				END

				--Obteci�n del seguro
				SELECT @requierenSeguro = dbo.ufnGetNoSociasAseguradas(@idSolicitudPrestamo)

				IF(@requierenSeguro > 0)
				BEGIN
					SELECT @seguro_vida = SUM(CATA_ProductoSeguro.monto_prima_seguro_calculado)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					GROUP BY OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo;

					SELECT @seguro_vida_deudor =  SUM(CATA_ProductoSeguro.monto_saldo_deudor)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					AND CLIE_DetalleSeguro.incluye_saldo_deudor = 1
					GROUP BY OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo;

					SELECT TOP(1)
							@monto_asegurado = ISNULL(CATA_ProductoSeguro.monto_asegurado, 0),
							@monto_prima_seguro_calculado = ISNULL(CATA_ProductoSeguro.monto_prima_seguro_calculado, 0),
							@monto_asegurado_conserva = ISNULL(CATA_ProductoSeguro.monto_asegurado_conserva, 0),
							@monto_saldo_deudor = ISNULL(CATA_ProductoSeguro.monto_saldo_deudor, 0),
							@nombre_aseguradora = ISNULL(CATA_seguros.nombre, ''),
							@monto_adeudo_asegurado = ISNULL(CATA_seguros.monto_adeudo_asegurado, 0),
							@monto_adeudo_asegurado_conyuge = ISNULL(CATA_seguros.monto_adeudo_asegurado_conyuge, 0)
					FROM OTOR_SolicitudPrestamoMonto
					INNER JOIN CLIE_DetalleSeguro ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=CLIE_DetalleSeguro.id_solicitud_prestamo
					AND OTOR_SolicitudPrestamoMonto.id_individual=CLIE_DetalleSeguro.id_individual AND CLIE_DetalleSeguro.activo=1
					INNER JOIN CATA_ProductoSeguro ON CLIE_DetalleSeguro.id_seguro_asignacion=CATA_ProductoSeguro.id AND CATA_ProductoSeguro.activo=1
					INNER JOIN CATA_seguros ON CATA_seguros.id = CATA_ProductoSeguro.id_seguro
					INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual=CLIE_Individual.id_cliente
					INNER JOIN CONT_Personas ON CLIE_Individual.id_persona=CONT_Personas.id
					INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo=OTOR_SolicitudPrestamos.id
					WHERE OTOR_SolicitudPrestamos.id = @idSolicitudPrestamo
					AND OTOR_SolicitudPrestamos.id_cliente = @id_cliente
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
					ORDER BY OTOR_SolicitudPrestamoMonto.id DESC;

					SET @seguro_vida_total = @seguro_vida_deudor + @seguro_vida;

					SET @requierenSeguro = 1;
				END


				--C�lculo del CAT.
				SELECT @cat = ISNULL(CAST(dbo.ufnCalcularCAT(@idContrato, 0, 0, @seguro_vida_total, 0, @monto_garantia_liquida-@seguro_vida_total, @monto_bonificacion_estimado) AS DECIMAL(6,2)), 0);

				IF (@cat IS NULL OR @cat <=0) 
				BEGIN
					ROLLBACK TRAN T_PRINCIPAL
					PRINT 'ERROR: No se obtuvo un valor de CAT valido.';
					INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
					VALUES (@idContrato, 11, 2, 'uspGenerarCalendarioPagos', 0, 'No se obtuvo un valor de CAT valido:' + CAST(@cat AS VARCHAR(5)) , 'OTOR_InsertContrato');
					RETURN;
				END

				--Actualizacion del id_contrato en la tabla otor_garantias
				UPDATE OTOR_Garantias
				SET OTOR_Garantias.id_contrato = @idContrato
				WHERE OTOR_Garantias.id_solicitud_prestamo = @idSolicitudPrestamo;

				--Insertamos los datos en OTOR_ContratoIndividual
				INSERT INTO OTOR_ContratoIndividual
				SELECT	@idContrato AS id_contrato,
						OTOR_Contratos.id_cliente,
						UPPER(ISNULL(CONT_Personas.nombre, '') + ' ' + ISNULL(CONT_Personas.apellido_paterno, '') + ' ' + ISNULL(CONT_Personas.apellido_materno, '')) AS nombre_acreditado,
						UPPER(CLIENTE_DIRECCION.vialidad + ' ' + CLIENTE_DIRECCION.direccion + (CASE WHEN CLIENTE_DIRECCION.num_exterior IN (0) THEN '' ELSE ' No.' + CLIENTE_DIRECCION.num_exterior END) + (CASE WHEN CLIENTE_DIRECCION.numero_exterior IN ('S/N','SN') THEN '' ELSE ' ' + CLIENTE_DIRECCION.numero_exterior END) + (CASE WHEN CLIENTE_DIRECCION.num_interior IN (0) THEN '' ELSE ' INT. ' + CLIENTE_DIRECCION.num_interior END) + (CASE WHEN CLIENTE_DIRECCION.numero_interior IN ('S/N','SN') THEN '' ELSE ' ' + CLIENTE_DIRECCION.numero_interior END)) AS direccion,
						--UPPER(ISNULL(CLIENTE_DIRECCION.vialidad + ' ' + CLIENTE_DIRECCION.direccion + (CASE WHEN CLIENTE_DIRECCION.numero_exterior IN ('S/N','SN') THEN ' S/N' ELSE ' No. ' + CLIENTE_DIRECCION.numero_exterior END), '')) AS direccion,
						UPPER(CLIENTE_DIRECCION.codigo_postal) AS codigo_postal,
						UPPER(CLIENTE_DIRECCION.asentamiento) AS asentamiento, 
						UPPER(CLIENTE_DIRECCION.ciudad_localidad) AS localidad,
						UPPER(CLIENTE_DIRECCION.municipio) AS municipio,
						UPPER(CLIENTE_DIRECCION.estado) AS estado,
						ISNULL(TELEFONO.Telefono, '') AS telefono,
						OTOR_Contratos.monto_total_autorizado,
						PLANPAGOS.Total_interes AS monto_total_interes,
						PLANPAGOS.Total_impuesto AS monto_total_impuesto,
						PLANPAGOS.Total_reembolso AS monto_total_por_pagar,
						OTOR_Contratos.monto_reembolso,
						OTOR_Contratos.fecha_desembolso,
						OTOR_Contratos.fecha_primer_pago,
						OTOR_Contratos.fecha_ultimo_pago AS fecha_vencimiento,
						CATA_Productos.periodos AS plazo,
						UPPER(LTRIM(@tipoPlazo)) AS tipo_plazo,
						UPPER(CATA_Productos.periodicidad) AS periodicidad,
						CATA_Productos.tasa_anual AS tasa_ordinaria,
						(CATA_Productos.tasa_anual * 2) AS tasa_moratoria,
						CAST(CATA_Productos.garantia_liquida AS MONEY) AS  porcentaje_garantia_liquida,
						--@monto_garantia_liquida - @seguro_vida_total AS monto_garantia_liquida,
						CASE WHEN @porcentajeGarantiaLiquida > 0 THEN @monto_garantia_liquida-@seguro_vida_total ELSE 0 END AS monto_garantia_liquida,
						@bonificacion AS configuracion_bonificacion,
						@monto_bonificacion_estimado AS monto_bonificacion_estimado,
						UPPER(CATA_TipoContrato.etiqueta) AS nombre_comercial_producto,
						UPPER(FUND_Fondeadores.nombre_del_fondo) AS nombre_fondeador,
						@cat AS cat,
						@cat_garantia_incluido AS cat_garantia_incluido,
						@cat_bonificacion_incluido AS cat_bonificacion_incluido,
						@reca AS reca,
						CAST(@requierenSeguro AS BIT) AS requiere_seguro,
						@nombre_aseguradora AS nombre_aseguradora,
						@monto_asegurado AS monto_asegurado,
						@monto_prima_seguro_calculado AS monto_prima_seguro,
						@monto_adeudo_asegurado AS monto_adeudo_asegurado,
						@monto_adeudo_asegurado_conyuge AS monto_adeudo_asegurado_conyuge,
						@monto_asegurado_conserva AS monto_asegurado_empresa,
						@monto_saldo_deudor AS monto_saldo_deudor,
						0 AS id_poder_notarial,
						0 AS id_usuario_representante_legal,
						0 AS id_persona_representante_legal,
						'ALEJANDRA CERVANTES CRUZ' AS nombre_representante_legal,
						0 AS representante_asignado_por,
						GETDATE() fecha_asignacion_representante,
						@contrato_declaracion_inciso_c AS contrato_declaracion_inciso_c,
						-- UPPER(ISNULL(OFICINA_DIRECCION.vialidad + ' ' + OFICINA_DIRECCION.direccion + (CASE WHEN OFICINA_DIRECCION.numero_exterior IN ('S/N','SN') THEN ' S/N' ELSE ' No. ' + OFICINA_DIRECCION.numero_exterior END) + ', ' + OFICINA_DIRECCION.referencia + ' CP. ' + OFICINA_DIRECCION.codigo_postal, '')) AS oficina_direccion,
						UPPER(ISNULL(OFICINA_DIRECCION.vialidad + ' ' + OFICINA_DIRECCION.direccion + ', ' + OFICINA_DIRECCION.asentamiento +', '+ OFICINA_DIRECCION.ciudad_localidad + ' CP ' + OFICINA_DIRECCION.codigo_postal, '')) AS oficina_direccion,
						UPPER(OFICINA_DIRECCION.ciudad_localidad) AS oficina_localidad,
						UPPER(OFICINA_DIRECCION.municipio) AS oficina_municipio,
						UPPER(OFICINA_DIRECCION.estado) AS oficina_estado,
						UPPER(ISNULL(UNE_DIRECCION.vialidad + ' ' + UNE_DIRECCION.direccion + ' No. ' + CAST(UNE_DIRECCION.num_exterior AS VARCHAR) + ', ' + UNE_DIRECCION.referencia + ' CP. ' + UNE_DIRECCION.codigo_postal, '')) AS UNE_direccion,
						UPPER(ISNULL(UNE_DIRECCION.municipio, '')) AS UNE_municipio,
						UPPER(ISNULL(UNE_DIRECCION.estado, '')) AS UNE_estado,
						UPPER(ISNULL(UNE.telefono_oficina + ISNULL(NULLIF(', ' + RTRIM(UNE.telefono_gratuito), ', '), ''), '')) AS UNE_telefono,
						UPPER(ISNULL(UNE.correo_electronico, '')) AS UNE_correo_electronico,
						UPPER(ISNULL(UNE.pagina_internet, '')) AS UNE_pagina_internet
				FROM OTOR_Contratos 
				INNER JOIN OTOR_SolicitudPrestamos ON OTOR_Contratos.id_solicitud_prestamo = OTOR_SolicitudPrestamos.id
				INNER JOIN OTOR_SolicitudPrestamoMonto ON OTOR_SolicitudPrestamos.id = OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo AND OTOR_SolicitudPrestamoMonto.autorizado = 1
				INNER JOIN CLIE_Individual ON OTOR_SolicitudPrestamoMonto.id_individual = CLIE_Individual.id_cliente
				INNER JOIN CONT_Personas ON CLIE_Individual.id_persona = CONT_Personas.id
				INNER JOIN vwCONT_Direcciones CLIENTE_DIRECCION ON CONT_Personas.id_direccion = CLIENTE_DIRECCION.id_direccion
				INNER JOIN CATA_Productos ON OTOR_Contratos.id_producto = CATA_Productos.id
				INNER JOIN FUND_Fondeadores ON OTOR_Contratos.id_fondeador = FUND_Fondeadores.id
				INNER JOIN CATA_TipoContrato ON CATA_Productos.id_tipo_contrato = CATA_TipoContrato.id
				INNER JOIN CORP_OficinasFinancieras ON OTOR_SolicitudPrestamos.id_oficina = CORP_OficinasFinancieras.id
				INNER JOIN CONT_Oficinas ON CORP_OficinasFinancieras.id_oficina = CONT_Oficinas.id 
				INNER JOIN vwCONT_Direcciones OFICINA_DIRECCION ON CONT_Oficinas.id_direccion = OFICINA_DIRECCION.id_direccion
				LEFT JOIN CONT_Unidad_Especializada_Oficina_Financiera UNE_OFICINA ON CORP_OficinasFinancieras.id = UNE_OFICINA.id_oficina_financiera
				LEFT JOIN CONT_Unidad_Especializada UNE ON UNE_OFICINA.id_unidad_especializada = UNE.Id
				LEFT JOIN vwCONT_Direcciones UNE_DIRECCION ON UNE.id_direccion = UNE_DIRECCION.id_direccion
				CROSS APPLY
				(
						SELECT	OTOR_PlanPagos.id_contrato,
								SUM(OTOR_DetallePlanPagos.monto_interes) AS Total_interes,
								SUM(OTOR_DetallePlanPagos.monto_impuesto) AS Total_impuesto,
								SUM(OTOR_DetallePlanPagos.monto_reembolso) AS Total_reembolso
						FROM OTOR_DetallePlanPagos 
						INNER JOIN OTOR_PlanPagos 
						ON OTOR_PlanPagos.id = OTOR_DetallePlanPagos.id_plan_pago
						WHERE OTOR_PlanPagos.id_contrato = OTOR_contratos.id
						GROUP BY OTOR_PlanPagos.id_contrato
				) AS PLANPAGOS
				OUTER APPLY
				(
					SELECT TOP (1) 
							TelefonosPersona.id_persona, ISNULL(NULLIF(Telefono_1.idcel_telefono, ''), ISNULL(Telefono_2.idcel_telefono,'')) AS Telefono 
					FROM  
					(
						SELECT TelefonosPersona.id_persona, MIN(Telefonos.id) AS id_telefono_2, MAX(Telefonos.id) AS id_telefono_1 
						FROM CONT_TelefonosPersona TelefonosPersona 
						INNER JOIN CONT_Telefonos Telefonos ON TelefonosPersona.id_telefono = Telefonos.id AND Telefonos.estatus_registro = 'ACTIVO'
						WHERE TelefonosPersona.id_persona = CONT_Personas.id
						GROUP BY TelefonosPersona.id_persona
					)TelefonosPersona
					LEFT JOIN CONT_Telefonos Telefono_1 ON Telefono_1.id = TelefonosPersona.id_telefono_1
					LEFT JOIN CONT_Telefonos Telefono_2 ON Telefono_2.id = TelefonosPersona.id_telefono_2
				) AS TELEFONO 
				WHERE OTOR_Contratos.id = @idContrato;

				--Insertamos los datos en OTOR_ContratoRelacion
				INSERT INTO OTOR_ContratoRelacion
				SELECT	OTOR_ContratoIndividual.id_contrato,
						ISNULL(RELACIONES.id, 0) AS id_clie_r_i,
						ISNULL(RELACIONES.parentesco, '') AS parentesco,
						ISNULL(RELACIONES.tipo_relacion, '') AS tipo_relacion,
						ISNULL(RELACIONES.tipo, '') AS tipo,
						ISNULL(RELACIONES.id_persona, 0) AS id_persona,
						ISNULL(RELACIONES.nombre, '') AS nombre,
						ISNULL(RELACIONES.apellido_paterno, '') AS apellido_paterno,
						ISNULL(RELACIONES.apellido_materno, '') AS apellido_materno,
						ISNULL(RELACIONES.fecha_nacimiento, '01-01-1900') AS fecha_nacimiento,
						ISNULL(RELACIONES.entidad_nacimiento, '') AS entidad_nacimiento,
						ISNULL(RELACIONES.pais_nacimiento, '') AS pais_nacimiento,
						ISNULL(RELACIONES.nacionalidad, '') AS nacionalidad,
						ISNULL(RELACIONES.sexo, '') AS sexo,
						ISNULL(RELACIONES.estado_civil, '') AS estado_civil,
						ISNULL(RELACIONES.direccion, '') AS direccion,
						ISNULL(RELACIONES.codigo_postal, '') AS codigo_postal,
						ISNULL(RELACIONES.asentamiento, '') AS asentamiento,
						ISNULL(RELACIONES.localidad, '') AS localidad,
						ISNULL(RELACIONES.municipio, '') AS municipio,
						ISNULL(RELACIONES.estado, '') AS estado,
						ISNULL(RELACIONES.pais, '') AS pais,
						ISNULL(RELACIONES.telefono, '') AS telefono,
						ISNULL(RELACIONES.correo_electronico, '') AS correo_electronico,
						1 AS activo,
						1 AS creado_por,
						GETDATE() AS fecha_cracion,
						1 AS modificado_por,
						GETDATE() AS fecha_modificacion
				FROM OTOR_ContratoIndividual
				CROSS APPLY
				(
					SELECT 	CLIE_R_I.id,
							UPPER(CLIE_R_I.parentesco) AS parentesco,
							UPPER(CLIE_R_I.tipo_relacion) AS tipo_relacion,
							ISNULL(NULLIF(UPPER(CLIE_R_I.tipo), ''), 'PERSONA') AS tipo,
							Persona.id AS id_persona,
							UPPER(Persona.nombre) AS nombre,
							UPPER(Persona.apellido_paterno) AS apellido_paterno,
							UPPER(Persona.apellido_materno) AS apellido_materno,
							Persona.fecha_nacimiento,
							UPPER(CATA_Estado.etiqueta) AS entidad_nacimiento,
							UPPER(CATA_Pais.etiqueta) AS pais_nacimiento,
							IIF(CATA_nacionalidad.etiqueta = 'MEXICANO', 'MEXICANA', CATA_nacionalidad.etiqueta)  AS nacionalidad,
							UPPER(CATA_Sexo.etiqueta) AS sexo,
							UPPER(CATA_EstadoCivil.etiqueta) AS estado_civil,
							--UPPER(CLIENTE_DIRECCION.vialidad + ' ' + CLIENTE_DIRECCION.direccion + (CASE WHEN CLIENTE_DIRECCION.num_exterior IN (0) THEN '' ELSE ' No.' + CLIENTE_DIRECCION.num_exterior END) + (CASE WHEN CLIENTE_DIRECCION.numero_exterior IN ('S/N','SN') THEN '' ELSE ' ' + CLIENTE_DIRECCION.numero_exterior END) + (CASE WHEN CLIENTE_DIRECCION.num_interior IN (0) THEN '' ELSE ' INT ' + CLIENTE_DIRECCION.num_interior END) + (CASE WHEN CLIENTE_DIRECCION.numero_interior IN ('S/N','SN') THEN '' ELSE ' ' + CLIENTE_DIRECCION.numero_interior END)) AS direccion,
							UPPER(DIRECCION.vialidad + ' ' + DIRECCION.direccion + (CASE WHEN DIRECCION.num_exterior IN (0) THEN '' ELSE ' No.' + DIRECCION.num_exterior END) + (CASE WHEN DIRECCION.numero_exterior IN ('S/N','SN') THEN '' ELSE ' ' + DIRECCION.numero_exterior END) + (CASE WHEN DIRECCION.num_interior IN (0) THEN '' ELSE ' INT. ' + DIRECCION.num_interior END) + (CASE WHEN DIRECCION.numero_interior IN ('S/N','SN') THEN '' ELSE ' ' + DIRECCION.numero_interior END)) AS direccion,
							--UPPER(DIRECCION.vialidad + ' ' + DIRECCION.direccion + (CASE WHEN DIRECCION.numero_exterior IN ('S/N','SN') THEN ' S/N' ELSE ' No. ' + DIRECCION.numero_exterior END)) AS direccion,
							UPPER(DIRECCION.codigo_postal) AS codigo_postal,
							UPPER(DIRECCION.asentamiento) AS asentamiento,
							UPPER(DIRECCION.ciudad_localidad) AS localidad,
							UPPER(DIRECCION.municipio) AS municipio,
							UPPER(DIRECCION.estado) AS estado,
							UPPER(DIRECCION.pais) AS pais,
							REPLACE(ISNULL(TELEFONO.Telefono, ''), ' ', '') AS telefono,
							ISNULL(DIRECCION.correo_electronico, '') AS correo_electronico
					FROM CLIE_R_I
					INNER JOIN CONT_Personas Persona ON CLIE_R_I.id_referencia = Persona.id
					LEFT JOIN CATA_Estado ON Persona.id_entidad_nacimiento = CATA_Estado.id 
					LEFT JOIN CATA_Pais ON Persona.id_pais_nacimiento = CATA_Pais.id
					LEFT JOIN CATA_Nacionalidad ON Persona.id_nacionalidad = CATA_nacionalidad.id
					LEFT JOIN CATA_Sexo ON Persona.id_sexo = CATA_Sexo.id
					LEFT JOIN CATA_EstadoCivil ON Persona.id_estado_civil = CATA_EstadoCivil.id
					LEFT JOIN vwCONT_Direcciones DIRECCION ON Persona.id_direccion = DIRECCION.id_direccion
					OUTER APPLY
					(
						SELECT TOP (1) 
								TelefonosPersona.id_persona, ISNULL(NULLIF(Telefono_1.idcel_telefono, ''), ISNULL(Telefono_2.idcel_telefono,'')) AS Telefono 
						FROM  
						(
							SELECT TelefonosPersona.id_persona, MIN(Telefonos.id) AS id_telefono_2, MAX(Telefonos.id) AS id_telefono_1 
							FROM CONT_TelefonosPersona TelefonosPersona 
							INNER JOIN CONT_Telefonos Telefonos ON TelefonosPersona.id_telefono = Telefonos.id AND Telefonos.estatus_registro = 'ACTIVO'
							WHERE TelefonosPersona.id_persona = Persona.id
							GROUP BY TelefonosPersona.id_persona
						)TelefonosPersona
						LEFT JOIN CONT_Telefonos Telefono_1 ON Telefono_1.id = TelefonosPersona.id_telefono_1
						LEFT JOIN CONT_Telefonos Telefono_2 ON Telefono_2.id = TelefonosPersona.id_telefono_2
					) AS TELEFONO 
					WHERE CLIE_R_I.eliminado = 0
					AND UPPER(RTRIM(CLIE_R_I.tipo_relacion)) IN ('COACREDITADO', 'AVAL')
					AND CLIE_R_I.id_cliente = OTOR_ContratoIndividual.id_cliente
				) AS RELACIONES
				WHERE OTOR_ContratoIndividual.id_contrato = @idContrato;

			END

			--INSERT PARA CONTRATO GRUPAL Y IND.
			INSERT INTO OTOR_ContratoGrupalInvidual(id_contrato,id_individual,nombre_socia,id_prestamo_solicitud,perfil_riesgo,tipo_cliente)
			SELECT @idContrato, id_individual, nombre, id_solicitud_prestamo, perfil_riesgo, @idTipoCliente 
			FROM @_integrantes;
			
			--Registro de auditor�a para verificar horas pico de creaci�n de paquetes.
			INSERT INTO OTOR_HistorialCreacionContrato (fecha_creacion,id_contrato,fecha_clr,fecha_bono,fecha_cat,fecha_modificacion)
			VALUES (@fecha_inicio, @idContrato, NULL, NULL, NULL, GETDATE())

			COMMIT TRAN T_PRINCIPAL;
		RETURN
	END TRY
	BEGIN CATCH
  		ROLLBACK TRAN T_PRINCIPAL
  		PRINT 'ERROR: ' + ERROR_MESSAGE();
    	INSERT INTO SYST_ErrorLog (numero,gravedad, estado, procedimiento, linea, mensaje, procedimiento_origen)
        SELECT
		ERROR_NUMBER() AS Numero_de_Error,
		ERROR_SEVERITY() AS Gravedad_del_Error,
		ERROR_STATE() AS Estado_del_Error,
		ERROR_PROCEDURE() AS Procedimiento_del_Error,
		ERROR_LINE() AS Linea_de_Error,
		ERROR_MESSAGE() AS Mensaje_de_Error,
        'OTOR_InsertContrato' AS Procedimiento_Origen;
        RETURN;
	END CATCH
END
GO

--#endregion ------------------------------------- FIN PROCEDURE INSERT CONTRACT ------------------------------------------ 

--#region ------------------------------------- PROCEDURE GET BALANCE  ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_ObtenerSaldoClienteById
	@idCliente INT
AS
BEGIN

DECLARE @dateCurrrent DATE = GETDATE()
DECLARE @dateTimeCurrent DATETIME = @dateCurrrent
PRINT @dateTimeCurrent

	SELECT * FROM
	(
		SELECT OTOR_Contratos.id_cliente AS idCliente,
			   OTOR_Contratos.id AS idContrato,
			   (CASE (OTOR_Contratos.id_tipo_cliente)
					WHEN  1
					THEN 
					(
						SELECT ISNULL(CLIE_Grupos.nombre,'')
						FROM CLIE_Grupos 
						WHERE id_cliente = OTOR_contratos.id_cliente
					)
					WHEN  2
					THEN 
					(
						SELECT ISNULL(CONT_Personas.nombre, '') + ' ' + ISNULL(CONT_Personas.apellido_paterno, '') + ' ' + ISNULL(CONT_Personas.apellido_materno, '')
						FROM CONT_Personas 
						INNER JOIN CLIE_Individual
						ON CONT_Personas.id = CLIE_Individual.id_persona
						WHERE CLIE_Individual.id_cliente = OTOR_contratos.id_cliente
					)
					ELSE
					''
				END) AS nombreCliente,
				(
					SELECT ISNULL(COUNT(*),0)
					FROM OTOR_SolicitudPrestamoMonto
					WHERE OTOR_SolicitudPrestamoMonto.id_solicitud_prestamo = OTOR_SolicitudPrestamos.id
					AND OTOR_SolicitudPrestamoMonto.autorizado = 1
				) AS numeroMiembros,
				OTOR_SolicitudPrestamos.ciclo AS Ciclo,
				OTOR_SolicitudPrestamos.monto_total_autorizado AS montoTotalAutorizado,
				CATA_Productos.periodos AS plazo,
				CATA_Productos.periodicidad AS periodicidad,
				dbo.ufnObtenerFechaHabil(OTOR_Contratos.fecha_primer_pago) AS fechaPrimerPago,
				dbo.ufnObtenerFechaHabil(OTOR_Contratos.fecha_ultimo_pago) AS fechaUltimoPago,
				(CASE (OTOR_Contratos.id_tipo_cliente)
					WHEN  1
					THEN 
					(
						SELECT ISNULL(OTOR_ContratoGrupal.monto_reembolso,0)
						FROM OTOR_ContratoGrupal 
						WHERE OTOR_ContratoGrupal.no_folio = OTOR_contratos.id
					)
					WHEN  2
					THEN 
					(
						SELECT ISNULL(OTOR_ContratoIndividual.monto_reembolso,0)
						FROM OTOR_ContratoIndividual 
						WHERE OTOR_ContratoIndividual.id_contrato = OTOR_contratos.id
					)
					ELSE
					''
				END) AS montoReembolso,
				(CASE (OTOR_Contratos.estatus)
					WHEN  'DESEMBOLSADO'
					THEN 
					(
						CAST(dbo.ufnGetSaldoPendiente(OTOR_Contratos.id, @dateTimeCurrent)AS MONEY)
					)
					WHEN  'TRANSITO'
					THEN 
					(
						0
					)
					ELSE
					0
				END) AS saldoActual,
				dbo.ufnCalcularPrincipalVencido(OTOR_Contratos.id,dbo.ufnGetNumeroPago(@dateTimeCurrent, OTOR_Contratos.id, -1), @dateTimeCurrent) AS SaldoEnMora,
				dbo.ufnCalcularInteresVencido(OTOR_Contratos.id,dbo.ufnGetNumeroPago(@dateTimeCurrent, OTOR_Contratos.id, -1), @dateTimeCurrent) AS SaldoInteres,
				dbo.ufnCalcularImpuestoVencido(OTOR_Contratos.id,dbo.ufnGetNumeroPago(@dateTimeCurrent, OTOR_Contratos.id, -1), @dateTimeCurrent) AS SaldoImpuesto,
				dbo.ufnGetCantidadPagosVencidos(OTOR_Contratos.id,dbo.ufnGetNumeroPago(@dateTimeCurrent, OTOR_Contratos.id, -1), @dateTimeCurrent) AS NoPagosVencidos,
				(
					SELECT dbo.ufnObtenerFechaHabil(OTOR_DetallePlanPagos.fecha_vencimiento)
					FROM OTOR_DetallePlanPagos
					WHERE OTOR_DetallePlanPagos.id =
					(
						SELECT ISNULL(MAX(OTOR_DetallePlanPagos.id), (SELECT OTOR_DetallePlanPagos.id FROM dbo.OTOR_DetallePlanPagos 
																	  INNER JOIN OTOR_PlanPagos 
																	  ON OTOR_DetallePlanPagos.id_plan_pago = OTOR_PlanPagos.id
																	  WHERE  OTOR_PlanPagos.id_contrato = OTOR_Contratos.id
																	  AND OTOR_DetallePlanPagos.numero_pago = 1))
						FROM OTOR_DetallePlanPagos 
						INNER JOIN OTOR_PlanPagos 
						ON OTOR_DetallePlanPagos.id_plan_pago = OTOR_PlanPagos.id
						WHERE  OTOR_PlanPagos.id_contrato = OTOR_Contratos.id
						AND OTOR_DetallePlanPagos.numero_pago >= dbo.ufnGetNumeroPago(@dateTimeCurrent, OTOR_Contratos.id, -1)
						AND OTOR_DetallePlanPagos.fecha_vencimiento <= @dateTimeCurrent
					)
				) AS fechaProximoPago,
				dbo.ufnGetDiasAtraso(@dateTimeCurrent, OTOR_Contratos.id, -1) AS diasDeMora,
				OTOR_SolicitudPrestamos.id_oficial AS idOficialCredito,
				(
					SELECT ISNULL(CONT_Personas.nombre, '') + ' ' + ISNULL(CONT_Personas.apellido_paterno, '') + ' ' + ISNULL(CONT_Personas.apellido_materno, '')
					FROM CONT_Personas 
					WHERE id = OTOR_SolicitudPrestamos.id_oficial
				) AS nombreOficialCredito,
				--dbo.ufnGetProvisionBySaldoDias(dbo.ufnGetSaldoPendiente(OTOR_Contratos.id, @fechaFinal), dbo.ufnGetDiasAtraso(@fechaFinal, OTOR_Contratos.id, -1))
				0 AS provision,
				OTOR_Contratos.estatus AS estatus,
				(
					SELECT RECU_Reembolsos.fecha_efectiva
					FROM RECU_ContratoEventos
					INNER JOIN RECU_Reembolsos 
					ON RECU_ContratoEventos.id = RECU_Reembolsos.id_contrato_evento
					WHERE id = (SELECT ISNULL(MAX(id),0)
								FROM RECU_ContratoEventos 
								WHERE id_contrato = OTOR_Contratos.id
								AND tipo_evento='REEMBOLSO')
					AND RECU_ContratoEventos.revertido = 0 
				) AS fechaUltimoReembolso,
				CORP_OficinasFinancieras.id AS idOficina,
				ISNULL(CORP_OficinasFinancieras.nombre,'') AS nombreOficina,
                CORP_Zonas.id AS idEstado,
				ISNULL(CORP_Zonas.nombre,'') AS nombreEstado,
				ROW_NUMBER() OVER(ORDER BY OTOR_Contratos.id ASC) AS RowNum,
				dbo.ufnObtenerDiasAtraso(@dateTimeCurrent, OTOR_Contratos.id) AS diasAtrasoAcumulados,
				
				(
				CASE (OTOR_Contratos.estatus)
					WHEN  'DESEMBOLSADO'
						THEN 
							
							CASE WHEN dbo.ufnGetDiasAtraso(@dateTimeCurrent, OTOR_Contratos.id, -1) > 0
							
						 THEN 
							(
								CAST(dbo.ufnGetSaldoPendiente(OTOR_Contratos.id, @dateTimeCurrent)AS MONEY)
							)
						ELSE
						(
						   0
						)
						END
					WHEN 'TRANSITO'
					THEN 
					 (
						0
					 )
					 ELSE
					 (
					   0
					 )
				END
				
				)AS [Par 1],
				CATA_Productos.tipo_contrato
		FROM OTOR_Contratos
		INNER JOIN OTOR_SolicitudPrestamos
		ON OTOR_Contratos.id_solicitud_prestamo = OTOR_SolicitudPrestamos.id
		INNER JOIN CATA_Productos
		ON OTOR_SolicitudPrestamos.id_producto = CATA_Productos.id
        INNER JOIN CORP_OficinasFinancieras
        ON OTOR_SolicitudPrestamos.id_oficina = CORP_OficinasFinancieras.id
        INNER JOIN CORP_Zonas
        ON CORP_OficinasFinancieras.id_zona = CORP_Zonas.id
		WHERE OTOR_Contratos.id_cliente = @idCliente AND (OTOR_Contratos.estatus = 'DESEMBOLSADO' OR OTOR_Contratos.estatus = 'TRANSITO')
	) 
	AS Resultado
END
GO

--#endregion ------------------------------------- FIN PROCEDURE GET BALANCE ------------------------------------------ 

--#region ------------------------------------- PROCEDURE GET DATA OF PERSONAL OFFICE  ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_ObtenerDatosDelPersonal
AS
BEGIN

	SELECT * FROM CATA_Puesto
	SELECT
	E.id,
	E.id_empleado_padre,
	E.id_persona,
	CONCAT(P.nombre, ' ', P.apellido_paterno, ' ', P.apellido_materno) AS 'persona_nombre_completo',
	E.id_puesto,
	E.id_nivel_puesto,
	E.id_cuota_negocio,
	E.activo
	FROM CORP_Empleado as E
	INNER JOIN CONT_Personas AS P ON p.id = e.id_persona

	SELECT * FROM CORP_OficinasFinancieras

END
GO

--#endregion ------------------------------------- FIN PROCEDURE GET DATA OF PERSONAL OFFICE ------------------------------------------ 

--#region ------------------------------------- PROCEDURE ASSIGN DISPOSITION  ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_FUND_ASIGNAR_DISPOSICION
@idTipoCliente INT,
@idServicioFinanciero INT,
@idOficina INT,
@idLocalidad INT,
@todasCurp INT,
@ciclo INT,
@montoSolicitado MONEY,
@montoMaximoSolicitado MONEY
AS
BEGIN
	IF (@idTipoCliente = 1)
    BEGIN

        DECLARE @habitantes INT;
        DECLARE @numero_habitantes FLOAT;
        DECLARE @numero_habitantes_linea FLOAT;
        DECLARE @estado_grupo VARCHAR(255);
		DECLARE @idMinDisposicion INT;
		DECLARE @idLineaCredito INT;
		
        DECLARE @Lineas TABLE
        (
			id_disposicion INT,
			id_lineacredito INT,
			nombre_linea  VARCHAR(255),
			id_fondeador INT,
			nombre_fondo  VARCHAR(255),
			monto_dispuesto MONEY,
			monto_colocado MONEY,
			monto_apartado MONEY,
			monto_disponible MONEY,
			identificador INT,
			prelacion INT,
			id int IDENTITY

        )
        
        --Obtenemos el estado del grupo.
        SELECT @estado_grupo = CATA_estado.etiqueta 
        FROM CATA_estado 
        INNER JOIN CATA_municipio 
        ON CATA_estado.id = CATA_municipio.id_estado 
        INNER JOIN CATA_ciudad_localidad 
        ON CATA_municipio.id = CATA_ciudad_localidad.id_municipio
        WHERE CATA_ciudad_localidad.id = @idLocalidad; 
        
        --Obtenemos la cantidad de habitantes de la localidad del grupo.
        SELECT @numero_habitantes = CATA_ciudad_localidad.no_habitantes 
        FROM CATA_ciudad_localidad 
        WHERE CATA_ciudad_localidad.id = @idLocalidad;
                
        
        INSERT INTO @Lineas
        SELECT   FUND_Disposicion.id AS IdDisposicion,
				 FUND_Disposicion.id_lineacredito AS IdLineaCredito,
                 FUND_LineaCredito.nombre_linea AS LineaCredito,
                 FUND_Fondeadores.id AS IdFondeador,
                 FUND_Fondeadores.nombre_del_fondo AS Fondeador,
                 FUND_Fondeadores.monto_maximo AS montoMaximo,
                 FUND_Disposicion.monto_colocado AS MontoColocado,
                 FUND_Disposicion.monto_apartado AS MontoApartado,
                (FUND_Disposicion.monto_dispuesto-FUND_Disposicion.monto_colocado-FUND_Disposicion.monto_apartado) AS MontoDisponible,
                0 AS identificador,
                ISNULL(FUND_FondeadorSucursal.orden, 0) AS prelacion
        FROM     FUND_Disposicion 
				 INNER JOIN FUND_LineaCredito 
				 ON FUND_Disposicion.id_lineacredito = FUND_LineaCredito.id 
				 INNER JOIN FUND_FondeadorSucursal 
				 ON FUND_LineaCredito.id_fondeador = FUND_FondeadorSucursal.id_fondeador  
				 INNER JOIN FUND_Estados 
				 ON FUND_LineaCredito.id = FUND_Estados.id_lineacredito 
				 INNER JOIN FUND_Fondeadores 
				 ON FUND_FondeadorSucursal.id_fondeador = FUND_Fondeadores.id
				 LEFT JOIN FUND_FondeadorPrelacion
				 ON FUND_Fondeadores.id = FUND_FondeadorPrelacion.id_fondeador
        WHERE    FUND_LineaCredito.curp <= @todasCurp  
                 AND FUND_FondeadorSucursal.id_sucursal = @idOficina 
                 AND FUND_Estados.nombre=@estado_grupo
                 AND(FUND_Disposicion.monto_dispuesto-FUND_Disposicion.monto_colocado - FUND_Disposicion.monto_apartado) >= @montoSolicitado
                 AND FUND_Fondeadores.monto_maximo >= @montoMaximoSolicitado
                 AND (FUND_Fondeadores.estatus_registro='ACTIVO' AND FUND_LineaCredito.estatus_registro='ACTIVO' AND FUND_Disposicion.estatus_registro='ACTIVO')
        ORDER BY ISNULL(FUND_FondeadorSucursal.orden, 0) ASC;


        SELECT @idMinDisposicion=MIN(id) 
        FROM @Lineas;
        
        WHILE NOT (@idMinDisposicion IS NULL)
        BEGIN
			SET @habitantes = 0;
			SET @idLineaCredito = 0;
			SET @numero_habitantes_linea = 0;
			
			SELECT @idLineaCredito = id_lineacredito 
			FROM @Lineas 
			WHERE id = @idMinDisposicion;
			
			SELECT @habitantes = poblacion,
				   @numero_habitantes_linea = cantidad_habitantes 
			FROM FUND_LineaCredito 
			WHERE id = @idLineaCredito;
			
			IF(@habitantes=1)
			BEGIN
			
				IF((@numero_habitantes_linea * 1000) < @numero_habitantes)
				BEGIN
					UPDATE @Lineas 
					SET identificador = 1 
					WHERE id = @idMinDisposicion;       
				END
			END    
			
			SELECT @idMinDisposicion=MIN(id) 
			FROM @Lineas 
			WHERE  id > @idMinDisposicion ;
        END
         
		
        SELECT * FROM @Lineas 
        WHERE identificador = 0
        AND prelacion = 
        (
			SELECT ISNULL(MIN(prelacion),0) 
			FROM @Lineas 
			WHERE prelacion > 0
			AND identificador = 0
   	    )
        
    END
    ELSE
    BEGIN
    	SELECT FUND_Disposicion.id as IdDisposicion,
            FUND_Disposicion.id_lineacredito as IdLineaCredito,
            FUND_LineaCredito.nombre_linea as LineaCredito,
            FUND_Fondeadores.id as IdFondeador,
            FUND_Fondeadores.nombre_del_fondo as Fondeador, 
            FUND_Fondeadores.monto_maximo,
            FUND_Disposicion.monto_colocado as MontoColocado,
            FUND_Disposicion.monto_apartado as MontoApartado,
            (FUND_Disposicion.monto_dispuesto-FUND_Disposicion.monto_colocado-FUND_Disposicion.monto_apartado) as MontoDisponible,
            0
        FROM FUND_Disposicion 
        INNER JOIN FUND_LineaCredito 
        ON FUND_Disposicion.id_lineacredito = FUND_LineaCredito.id 
        INNER JOIN FUND_FondeadorSucursal 
        ON FUND_LineaCredito.id_fondeador = FUND_FondeadorSucursal.id_fondeador  
        INNER JOIN FUND_Fondeadores 
        ON FUND_FondeadorSucursal.id_fondeador = FUND_Fondeadores.id
        WHERE FUND_FondeadorSucursal.id_sucursal = @idOficina
        and (FUND_Disposicion.monto_dispuesto - FUND_Disposicion.monto_colocado - FUND_Disposicion.monto_apartado) >= 0  
        AND FUND_Fondeadores.id in (21,33)  
        AND (FUND_Fondeadores.estatus_registro='ACTIVO' AND FUND_LineaCredito.estatus_registro='ACTIVO' AND FUND_Disposicion.estatus_registro='ACTIVO')
        ORDER BY FUND_FondeadorSucursal.orden;
    END
END
GO

--#endregion ------------------------------------- FIN PROCEDURE ASSIGN DISPOSITION ------------------------------------------ 

--#region ------------------------------------- PROCEDURE GET TABLA AMORTIZACION  ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_uspObtenerDatosTablaAmortizacion
	@idContrato INT
AS
BEGIN

	--DATOS CONTRATO
	DECLARE @idTipoCliente INT = 0,
			@idOficinaFinanciera INT = 0,
			@idZonaFinanciera INT = 0,
			@telefonoOficinaFinanciera CHAR(30) = '',
			@direccionCompletaOficinaFinanciera VARCHAR(455) = '',
			@correoElectronicoOficinaFinanciera VARCHAR(200) = '',
			@paginaInternetOficinaFinanciera VARCHAR(100) = '',
			@telefonoOficinaUnidadEspecializada VARCHAR(200) = '',
			@direccion_oficina VARCHAR(200) = '',
			@idGrupo INT = 0,
			@nombre_oficina VARCHAR(50) = '';

	
	SELECT	@idTipoCliente = ISNULL(OTOR_contratos.id_tipo_cliente,0), 
			@idGrupo = OTOR_contratos.id_cliente,
			@idOficinaFinanciera = ISNULL(OTOR_SolicitudPrestamos.id_oficina, 0)
	FROM OTOR_contratos
	INNER JOIN OTOR_SolicitudPrestamos ON OTOR_Contratos.id_solicitud_prestamo = OTOR_SolicitudPrestamos.id
	WHERE OTOR_contratos.id = @idContrato
	
	SELECT @idZonaFinanciera = ISNULL(CORP_OficinasFinancieras.id_zona, 0), 
		   @nombre_oficina = CORP_OficinasFinancieras.nombre
	FROM CORP_OficinasFinancieras
	WHERE CORP_OficinasFinancieras.id = @idOficinaFinanciera;
	
	--Obtenemos el telefono de la oficina financiera.
	SELECT TOP(1) @telefonoOficinaFinanciera = RTRIM(ISNULL(CONT_Telefonos.idcel_telefono, ''))
	FROM CONT_Telefonos
	INNER JOIN CONT_TelefonosOficina
	ON CONT_Telefonos.id = CONT_TelefonosOficina.id_telefono
	INNER JOIN CORP_OficinasFinancieras
	ON CONT_TelefonosOficina.id_oficina = CORP_OficinasFinancieras.id_oficina
	WHERE CORP_OficinasFinancieras.id = @idOficinaFinanciera;
	
	SELECT	@direccionCompletaOficinaFinanciera = ISNULL(
				CATA_TipoVialidad.descripcion 
				+ ' ' + CONT_Direcciones.direccion 
				+ ' No. ' + CAST(CONT_Direcciones.num_exterior AS VARCHAR) 
				+ ', ' + CONT_Direcciones.referencia 
				+ ' CP. ' + CATA_asentamiento.codigo_postal
				+ ', ' + CATA_municipio.etiqueta 
				+ ', ' + CATA_estado.etiqueta
				, '')
			,@correoElectronicoOficinaFinanciera = ISNULL(UNIDAD.correo_electronico, '')
			,@telefonoOficinaUnidadEspecializada = UNIDAD.telefono_oficina + ', ' + UNIDAD.telefono_gratuito
			,@paginaInternetOficinaFinanciera = UNIDAD.pagina_internet
	FROM CONT_Unidad_Especializada_Oficina_Financiera UNIDAD_OFICINA
	INNER JOIN CONT_Unidad_Especializada UNIDAD ON UNIDAD.Id = UNIDAD_OFICINA.id_unidad_especializada
	INNER JOIN CONT_Direcciones ON CONT_Direcciones.id = UNIDAD.id_direccion
	INNER JOIN CATA_estado ON CATA_estado.id = CONT_Direcciones.estado
	INNER JOIN CATA_ciudad_localidad ON CATA_ciudad_localidad.id = CONT_Direcciones.localidad
	INNER JOIN CATA_asentamiento ON CATA_asentamiento.id = CONT_Direcciones.colonia
	INNER JOIN CATA_TipoVialidad ON CATA_TipoVialidad.id = CONT_Direcciones.vialidad
	INNER JOIN CATA_municipio ON CATA_municipio.id = CATA_ciudad_localidad.id_municipio
	WHERE UNIDAD_OFICINA.id_oficina_financiera = @idOficinaFinanciera
	AND UNIDAD_OFICINA.activo = 1
	AND UNIDAD.activo = 1

	SELECT	@direccion_oficina = CONT_Direcciones.direccion + (CASE WHEN CONT_Direcciones.num_exterior IN (0) THEN '' ELSE ' NO. ' + CONVERT(VARCHAR , CONT_Direcciones.num_exterior) END)  + (CASE WHEN CONT_Direcciones.numero_exterior IN ('S/N','SN') THEN '' ELSE '' + CONT_Direcciones.numero_exterior END) + (CASE WHEN CONT_Direcciones.num_interior IN (0) THEN '' ELSE ' INT. ' + CONVERT(VARCHAR , CONT_Direcciones.num_interior) END) + (CASE WHEN CONT_Direcciones.numero_interior IN ('S/N','SN') THEN '' ELSE '' + CONT_Direcciones.numero_interior END)
	+ ', ' + UPPER(CATA_asentamiento.asentamiento) + ' '  + CATA_asentamiento.etiqueta + ', ' + CATA_municipio.etiqueta + ', ' + CATA_estado.etiqueta + ', CÓDIGO POSTAL ' + CONT_Direcciones.codigo_postal
			--CONT_Direcciones.direccion + (CASE WHEN CONT_Direcciones.numero_exterior IN ('S/N','SN') THEN ' S/N' ELSE ' # ' + CONT_Direcciones.numero_exterior END) 
			--+ ', ' + CATA_municipio.etiqueta + ', ' + CATA_estado.etiqueta
	FROM CORP_OFICINASFINANCIERAS OFI
	INNER JOIN CONT_OFICINAS ON CONT_OFICINAS.id = OFI.id_oficina
	INNER JOIN CONT_Direcciones ON CONT_Direcciones.id = CONT_OFICINAS.id_direccion
	INNER JOIN CATA_estado ON CATA_estado.id = CONT_Direcciones.estado
	INNER JOIN CATA_municipio ON CATA_municipio.id = CONT_Direcciones.municipio
	--AGREGADO
	INNER JOIN CATA_asentamiento ON CATA_asentamiento.id = CONT_Direcciones.colonia
	WHERE OFI.id_tipo_oficina = 1
	AND OFI.id = @idOficinaFinanciera


	--END DATOS CONTRATO
	IF(@idTipoCliente = 1)
	BEGIN
		SELECT	@nombre_oficina AS Sucursal,
				CONT_Personas.nombre + ' ' + CONT_Personas.apellido_paterno +' '+ CONT_Personas.apellido_materno AS Oficial_credito,
				OTOR_Contratos.fecha_desembolso AS Fecha_desembolso,
				OTOR_ContratoGrupal.grp_nombre AS Nombre_grupo,
				UPPER(CAST(OTOR_ContratoGrupal.plazo AS VARCHAR(10)) + ' ' + OTOR_ContratoGrupal.tipo_plazo) AS Plazo,
				UPPER(OTOR_ContratoGrupal.frecuencia_pagos) AS Periodicidad,
				UPPER(CAST(OTOR_ContratoGrupal.plazo AS VARCHAR(10))) AS Numero_pagos,
				'SOBRE SALDOS INSOLUTOS, SIN CAPITALIZACIÓN' AS Metodologia_interes,
				CAST(CAST(CATA_Productos.tasa_anual AS DECIMAL(18,2)) AS VARCHAR) AS Tasa_anual_ordinaria,
				CAST(CAST(CATA_Productos.tasa_anual AS DECIMAL(18,2)) * 2 AS VARCHAR) AS Tasa_anual_moratoria,
				CAST(CAST(CATA_Productos.impuesto AS DECIMAL(18,2)) AS VARCHAR) AS Iva,
				CAST(CAST(OTOR_ContratoGrupal.cat AS DECIMAL(6,1)) AS VARCHAR(10)) AS Cat,

				CONVERT(VARCHAR, CAST(OTOR_Contratos.monto_total_autorizado AS MONEY), 1) AS Monto_prestamo,
				CONVERT(VARCHAR, CAST(OTOR_ContratoGrupal.monto_garantia AS MONEY), 1) AS Monto_garantia,
				--CAST(OTOR_ContratoGrupal.monto_garantia AS VARCHAR(50)) AS Monto_garantia,
				'NO APLICA' AS Comisiones,

				CONVERT(VARCHAR, CAST(ISNULL(OTOR_ContratoGrupal.monto_prima_seguro_grupal,0.0) AS MONEY), 1) AS Seguro_vida,
				CONVERT(VARCHAR, CAST(ISNULL(OTOR_ContratoGrupal.monto_saldo_deudor_grupo,0.0) AS MONEY), 1) AS Seguro_saldo_deudor,
				CAST(CASE WHEN OTOR_ContratoGrupal.no_folio IS NULL
					THEN 'NO APLICA'
					WHEN OTOR_ContratoGrupal.no_folio > 0
					THEN 
					--ISNULL(CAST(OTOR_ContratoGrupal.monto_bonificacion_estimado AS VARCHAR), '0.00')
					ISNULL(CONVERT(VARCHAR, CAST(OTOR_ContratoGrupal.monto_bonificacion_estimado AS MONEY), 1), '0.00')
					END AS VARCHAR(50))
					AS monto_bonificacion,

				UPPER (@direccion_oficina) AS Direccion_completa_oficina,
				RTRIM(@telefonoOficinaFinanciera) AS Telefono_oficina,
				UPPER(@direccionCompletaOficinaFinanciera) AS Direccion_une,
				@telefonoOficinaUnidadEspecializada AS Telefono_une,    
				@correoElectronicoOficinaFinanciera AS Correo_une,
				@paginaInternetOficinaFinanciera AS Pagina_web_une,
				UPPER(OTOR_ContratoGrupal.nombre_representante_legal) AS Representante_legal,
				CAST(OTOR_ContratoGrupal.no_folio AS VARCHAR(20)) AS Id_contrato,
				ISNULL(PLANPAGOS.Total_capital,0.0) AS Total_capital,
				PLANPAGOS.Total_interes AS Total_interes,
				PLANPAGOS.Total_impuesto AS Total_impuesto,
				PLANPAGOS.Total_reembolso AS Total_reembolso,
				OTOR_ContratoGrupal.reca AS Reca,
				'' AS avales
		FROM OTOR_ContratoGrupal 
		INNER JOIN OTOR_Contratos ON OTOR_ContratoGrupal.no_folio = OTOR_contratos.id
		INNER JOIN CATA_Productos ON CATA_Productos.id = OTOR_Contratos.id_producto
		INNER JOIN OTOR_PoderNotarial ON OTOR_ContratoGrupal.id_poder_notarial = OTOR_PoderNotarial.id
		INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamos.id = OTOR_Contratos.id_solicitud_prestamo
		LEFT JOIN CONT_Personas ON CONT_Personas.id = OTOR_SolicitudPrestamos.id_oficial
		OUTER APPLY
		(
				SELECT 
				OTOR_PlanPagos.id_contrato,
				SUM(OTOR_DetallePlanPagos.monto_principal) AS Total_capital,
				SUM(OTOR_DetallePlanPagos.monto_interes) AS Total_interes,
				SUM(OTOR_DetallePlanPagos.monto_impuesto) AS Total_impuesto,
				SUM(OTOR_DetallePlanPagos.monto_reembolso) AS Total_reembolso
				FROM OTOR_DetallePlanPagos 
				INNER JOIN OTOR_PlanPagos 
				ON OTOR_PlanPagos.id = OTOR_DetallePlanPagos.id_plan_pago
				WHERE OTOR_PlanPagos.id_contrato = OTOR_contratos.id
				GROUP BY OTOR_PlanPagos.id_contrato
		) AS PLANPAGOS
		WHERE OTOR_ContratoGrupal.no_folio = @idContrato;
	END
	ELSE IF(@idTipoCliente = 2)
	BEGIN

		DECLARE @clientes VARCHAR(MAX) = '',
				@avales VARCHAR(MAX) = '';
		
		DECLARE @relacion TABLE
		(
			id INT,
			nombre VARCHAR(500)
		);

		INSERT INTO @relacion
		SELECT 1, OTOR_ContratoIndividual.nombre_acreditado
		FROM OTOR_ContratoIndividual 
		WHERE OTOR_ContratoIndividual.id_contrato = @idContrato;

		INSERT INTO @relacion
		SELECT ROW_NUMBER() OVER (ORDER BY OTOR_ContratoRelacion.id) + 1,
			   CONCAT(OTOR_ContratoRelacion.nombre, ' ', OTOR_ContratoRelacion.apellido_paterno, ' ', OTOR_ContratoRelacion.apellido_materno)
		FROM OTOR_ContratoRelacion
		WHERE OTOR_ContratoRelacion.activo = 1
		AND OTOR_ContratoRelacion.tipo_relacion = 'COACREDITADO'
		AND OTOR_ContratoRelacion.id_contrato = @idContrato;
		
		SELECT	@clientes =  CONCAT(@clientes, IIF(LEN(@clientes) = 0, '', IIF(id = (SELECT COUNT(id) FROM @relacion), ' Y ', ', ')), nombre)
		FROM @relacion;

		DELETE FROM @relacion;

		INSERT INTO @relacion
		SELECT  ROW_NUMBER() OVER (ORDER BY OTOR_ContratoRelacion.id),
				CONCAT(OTOR_ContratoRelacion.nombre, ' ', OTOR_ContratoRelacion.apellido_paterno, ' ', OTOR_ContratoRelacion.apellido_materno)
		FROM OTOR_ContratoRelacion
		WHERE OTOR_ContratoRelacion.activo = 1
		AND OTOR_ContratoRelacion.tipo_relacion = 'AVAL'
		AND OTOR_ContratoRelacion.id_contrato = @idContrato;

		SELECT	@avales =  CONCAT(@avales, IIF(LEN(@avales) = 0, '', IIF(id = (SELECT COUNT(id) FROM @relacion), ' Y ', ', ')), nombre)
		FROM @relacion

		SELECT	@nombre_oficina AS Sucursal,
				CONT_Personas.nombre + ' ' + CONT_Personas.apellido_paterno +' '+ CONT_Personas.apellido_materno AS Oficial_credito,
				OTOR_Contratos.fecha_desembolso AS Fecha_desembolso,
				@clientes AS Nombre_grupo,
				CONCAT(CAST(OTOR_ContratoIndividual.plazo AS VARCHAR), ' ', OTOR_ContratoIndividual.tipo_plazo) AS Plazo,
				OTOR_ContratoIndividual.periodicidad AS Periodicidad,
				CAST(OTOR_ContratoIndividual.plazo AS VARCHAR(10)) AS Numero_pagos,
				'SOBRE SALDOS INSOLUTOS, SIN CAPITALIZACIÓN' AS Metodologia_interes,
				CAST(CAST(CATA_Productos.tasa_anual AS DECIMAL(18,2)) AS VARCHAR) AS Tasa_anual_ordinaria,
				CAST(CAST(CATA_Productos.tasa_anual AS DECIMAL(18,2)) * 2 AS VARCHAR) AS Tasa_anual_moratoria,
				CAST(CAST(CATA_Productos.impuesto AS DECIMAL(18,2)) AS VARCHAR) AS Iva,
				CAST(CAST(OTOR_ContratoIndividual.cat AS DECIMAL(6,1)) AS VARCHAR(10)) AS Cat,
				CONCAT('$', CONVERT(VARCHAR, CAST(OTOR_Contratos.monto_total_autorizado AS MONEY), 1)) AS Monto_prestamo,
				CONCAT('$', CONVERT(VARCHAR, CAST(OTOR_ContratoIndividual.monto_garantia_liquida AS MONEY), 1)) AS Monto_garantia,
				'NO APLICA' AS Comisiones,
				CONCAT('$', CONVERT(VARCHAR, CAST(ISNULL(OTOR_ContratoIndividual.monto_prima_seguro, 0.0) AS MONEY), 1)) AS Seguro_vida,
				CONCAT('$', CONVERT(VARCHAR, CAST(ISNULL(OTOR_ContratoIndividual.monto_saldo_deudor,0.0) AS MONEY), 1)) AS Seguro_saldo_deudor,
				CAST(
					CASE WHEN OTOR_ContratoIndividual.id_contrato IS NULL
						THEN 'NO APLICA'
					WHEN OTOR_ContratoIndividual.id_contrato > 0
						THEN CONCAT('$', ISNULL(CAST(OTOR_ContratoIndividual.monto_bonificacion_estimado AS VARCHAR), '0.00'))
					END AS VARCHAR(50)
				) AS monto_bonificacion,
				CONCAT(OTOR_ContratoIndividual.oficina_direccion, ', ', OTOR_ContratoIndividual.oficina_municipio, ', ', OTOR_ContratoIndividual.oficina_estado) AS Direccion_completa_oficina,
				RTRIM(@telefonoOficinaFinanciera) AS Telefono_oficina,
				CONCAT(OTOR_ContratoIndividual.UNE_direccion, ', ', OTOR_ContratoIndividual.UNE_municipio, ', ', OTOR_ContratoIndividual.UNE_estado) AS UNE_direccion,
				OTOR_ContratoIndividual.UNE_telefono,    
				OTOR_ContratoIndividual.UNE_correo_electronico,
				OTOR_ContratoIndividual.UNE_pagina_internet,
				OTOR_ContratoIndividual.nombre_representante_legal,
				RIGHT(CONCAT('000000000', CAST(OTOR_ContratoIndividual.id_contrato AS VARCHAR)), '9') AS Id_contrato,
				OTOR_ContratoIndividual.monto_autorizado,
				OTOR_ContratoIndividual.monto_total_interes,
				OTOR_ContratoIndividual.monto_total_impuesto,
				OTOR_ContratoIndividual.monto_total_por_pagar,
				OTOR_ContratoIndividual.reca,
				@avales AS avales
		FROM OTOR_ContratoIndividual 
		INNER JOIN OTOR_Contratos ON OTOR_ContratoIndividual.id_contrato = OTOR_contratos.id
		INNER JOIN CATA_Productos ON CATA_Productos.id = OTOR_Contratos.id_producto
		INNER JOIN OTOR_SolicitudPrestamos ON OTOR_SolicitudPrestamos.id = OTOR_Contratos.id_solicitud_prestamo
		LEFT JOIN CONT_Personas ON CONT_Personas.id = OTOR_SolicitudPrestamos.id_oficial
		WHERE OTOR_ContratoIndividual.id_contrato = @idContrato;
	END

	SELECT	OTOR_DetallePlanPagos.numero_pago AS Numero_pago,
			dbo.ufnObtenerFechaHabil(OTOR_DetallePlanPagos.fecha_vencimiento) AS Fecha_pago,
			OTOR_DetallePlanPagos.monto_capital_vivo_original + OTOR_DetallePlanPagos.monto_principal_original AS Saldo_inicial,
			OTOR_DetallePlanPagos.monto_principal_original AS Monto_principal,
			OTOR_DetallePlanPagos.monto_interes_original AS Monto_interes,
			OTOR_DetallePlanPagos.monto_impuesto_original AS Monto_impuesto,
			OTOR_DetallePlanPagos.monto_reembolso AS Monto_reembolso,
			OTOR_DetallePlanPagos.monto_capital_vivo_original AS Capital_vivo_original,
			OTOR_DetallePlanPagos.estatus as estatus,
			CASE
			WHEN CAST(dbo.ufnObtenerFechaHabil(OTOR_DetallePlanPagos.fecha_vencimiento) AS DATE) = CAST(OTOR_DetallePlanPagos.fecha_vencimiento AS DATE)
			THEN ''
			ELSE '*' END
			AS Dia_festivo
	FROM OTOR_DetallePlanPagos 
	INNER JOIN OTOR_PlanPagos 
	ON OTOR_PlanPagos.id = OTOR_DetallePlanPagos.id_plan_pago
	WHERE OTOR_PlanPagos.id_contrato = @idContrato
END
GO

--#endregion ------------------------------------- FIN PROCEDURE GET TABLA AMORTIZACION ------------------------------------------ 

--#region ------------------------------------- PROCEDURE GET OFFICES ADMINISTRATIVES AND LOCATION  ------------------------------------------ 

CREATE OR ALTER PROCEDURE MOV_ObtenerOficinasFinancieras
AS
BEGIN

    SELECT
    OFI.id, OFI.nombre,
    OFI.id_zona,
    OFI.id_entidad_financiera,
    OFI.id_oficina,
    OFI.codigo,
    CO.nombre_oficina,
    CO.funcion_oficina,
    CO.email_sucursal,
    CO.horario,
    CO.dias_laborales,
    DIR.direccion,
    DIR.colonia AS 'id_colonia',
    COLONIA.etiqueta AS 'nombre_colonia',
    DIR.codigo_postal,
    DIR.localidad AS 'id_localidad',
    LOCALIDAD.etiqueta AS 'nombre_localidad',
    DIR.estado AS 'id_estado',
    ESTADO.etiqueta AS 'nombre_estado',
    DIR.municipio AS 'id_municipio',
    MUNICIPIO.etiqueta AS 'nombre_municipio',
    DIR.pais AS 'id_pais',
    PAIS.etiqueta AS 'nombre_pais',
    DIR.referencia,
    DIR.num_exterior,
    DIR.num_interior,
    DIR.numero_exterior,
    DIR.numero_interior
    FROM CORP_OficinasFinancieras AS OFI 
    INNER JOIN CONT_Oficinas AS CO ON CO.id = OFI.id_oficina
    INNER JOIN CONT_Direcciones AS DIR ON DIR.id = CO.id_direccion
    INNER JOIN CATA_asentamiento AS COLONIA ON COLONIA.id = DIR.colonia
    INNER JOIN CATA_ciudad_localidad AS LOCALIDAD ON LOCALIDAD.ID = DIR.localidad
    INNER JOIN CATA_estado AS ESTADO ON ESTADO.id = DIR.estado
    INNER JOIN CATA_municipio AS MUNICIPIO ON MUNICIPIO.id = DIR.municipio
    INNER JOIN CATA_pais AS PAIS ON PAIS.id = DIR.pais

    WHERE OFI.estatus = 'ACTIVO' AND OFI.id_tipo_oficina = 1

END
GO

--#endregion ------------------------------------- FIN PROCEDURE GET OFFICE ADMINISTRATIVES AND LOCATION ------------------------------------------ 

--#region ------------------------------------- PROCEDURE INSERT CONTRACT  ------------------------------------------ 

--#endregion ------------------------------------- FIN PROCEDURE INSERT CONTRACT ------------------------------------------ 

