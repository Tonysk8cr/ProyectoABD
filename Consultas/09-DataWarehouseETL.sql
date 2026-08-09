-- Reutilizamos las mismas consultas para las validaciones
-- Modificamos la de fecha por el formato con el que se guarda en el sa YYYYMMDD

CREATE OR REPLACE FUNCTION valida_numero_entero (
    p_numero VARCHAR2
) RETURN CHAR AS
    v_numero NUMBER;
BEGIN
    v_numero := TO_NUMBER ( p_numero );
    IF v_numero = trunc(v_numero) THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END;
/

CREATE OR REPLACE FUNCTION valida_numero_decimal (
    p_numero VARCHAR2
) RETURN CHAR AS
    v_numero NUMBER(20, 2);
BEGIN
    v_numero := TO_NUMBER ( p_numero );
    IF v_numero <> trunc(v_numero) THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END;
/

CREATE OR REPLACE FUNCTION valida_fecha (
    p_fecha VARCHAR2
) RETURN CHAR AS
    v_fecha DATE;
BEGIN
    v_fecha := TO_DATE ( p_fecha, 'YYYYMMDD' ); --Validamos el formato
    RETURN 'S';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END;
/

--FOROS QUE COSULTAMOS PARA DESARROLLAR ESTA FUNCION
-- https://www.forosdelweb.com/f100/comom-recorrer-cadena-oracle-1089314/
-- https://es.stackoverflow.com/questions/527388/c%C3%B3mo-recorrer-una-cadena-en-sqloracle

-- !TODO
--DOCS DEL REGEX, HACER REFERENCIA EN DOC ESCRITO 
-- https://docs.oracle.com/cd/B13789_01/server.101/b10759/conditions018.htm
CREATE OR REPLACE FUNCTION valida_email (
    p_email VARCHAR2
) RETURN CHAR AS
BEGIN
    -- VERIFICA QUE NO SEA NULO Y QUE CUMPLA CON EL PATRON
    IF
        p_email IS NOT NULL 
    -- ^ = INICIO DE LA CADENA, [] = CARAC PERMITIDOS + = UNO MAS, ES PARA DECIR DESPUES DE []
        AND regexp_like(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
    THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END;
/

--VALIDA QUE EL ESTADO SEA 1 OSEA ACTIVO
CREATE OR REPLACE FUNCTION valida_estado (
    p_estado VARCHAR2
) RETURN CHAR AS
    v_estado VARCHAR2(1);
BEGIN
    IF TRIM(p_estado) IS NULL
       OR length(trim(p_estado)) != 1 THEN
        RETURN 'N';
    END IF;

    v_estado := trim(p_estado);
    IF v_estado = '1' THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END;
/


-----------------------------------------------
--Tablas de errores
-----------------------------------------------

--Proveedores
CREATE TABLE inventariodw.error_proveedor (
    id_proveedor     VARCHAR2(4000),
    nombre_proveedor VARCHAR2(4000),
    telefono         VARCHAR2(4000),
    cod_postal       VARCHAR2(4000),
    email            VARCHAR2(4000),
    estado           VARCHAR2(4000),
    error_msj        VARCHAR2(4000)
);

CREATE TABLE inventariodw.error_empleado (
    id_empleado VARCHAR2(4000),
    nombre      VARCHAR2(4000),
    apellido_p  VARCHAR2(4000),
    apellido_m  VARCHAR2(4000),
    puesto      VARCHAR2(4000),
    email       VARCHAR2(4000),
    telefono    VARCHAR2(4000),
    estado      VARCHAR2(4000),
    error_msj   VARCHAR2(4000)
);

CREATE TABLE inventariodw.error_producto (
    id_producto      VARCHAR2(4000),
    nombre_prod      VARCHAR2(4000),
    descripcion_prod VARCHAR2(4000),
    categoria_id     VARCHAR2(4000),
    precio_unidad    VARCHAR2(4000),
    estado           VARCHAR2(4000),
    error_msj        VARCHAR2(4000)
);

CREATE TABLE inventariodw.error_orden_compra (
    id_orden        VARCHAR2(4000),
    numero_factura  VARCHAR2(4000),
    metodo_envio_id VARCHAR2(4000),
    fecha_envio     VARCHAR2(4000),
    fecha_orden     VARCHAR2(4000),
    error_msj       VARCHAR2(4000)
);

CREATE TABLE inventariodw.error_movimiento_inv (
    id_movimiento VARCHAR2(4000),
    fecha         VARCHAR2(4000),
    error_msj     VARCHAR2(4000)
);

-----------------------------------------------
--PAQUETE 
-----------------------------------------------
CREATE OR REPLACE PACKAGE inventariodw.etl_dw AS
    PROCEDURE migrarproveedor; --1
    PROCEDURE migrarempleado; --2
    PROCEDURE migrarproducto; --3
    PROCEDURE migrarordencompra; --4
    PROCEDURE migrarmovimientoinv; --5

    PROCEDURE migrardatos; --main
END etl_dw;
/

--Body del paquete

CREATE OR REPLACE PACKAGE BODY inventariodw.etl_dw AS
    --Migracion de los proveedores
    PROCEDURE migrarproveedor IS

        v_error         INTEGER;
        v_numero        INTEGER;
        v_error_mensaje VARCHAR2(4000);
        CURSOR c_datos IS --CICLO INICIO
        SELECT
            prov.id_proveedor,
            prov.nombre_proveedor,
            prov.telefono,
            prov.cod_postal,
            prov.email,
            prov.estado
        FROM
            inventariosa.sa_proveedor prov
        WHERE
            prov.id_proveedor NOT IN (
                SELECT
                    d.prv_id
                FROM
                    inventariodw.dim_proveedor d
            )
        ORDER BY
            prov.id_proveedor;

    BEGIN
        FOR d_datos IN c_datos LOOP
            BEGIN
                v_error := 0;
                v_error_mensaje := '';

                --PK VALIDACIONES
                --pK ES NULO O INEXISTENTE
                IF d_datos.id_proveedor IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador nulo. ';
                END IF;

                IF valida_numero_entero(d_datos.id_proveedor) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.id_proveedor ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Identificador negativo o cero. ';
                    END IF;

                END IF;

                --NOMBRE
                IF d_datos.nombre_proveedor IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre proveedor nulo. ';
                END IF;

                IF length(d_datos.nombre_proveedor) > 100 THEN       --QUE NO SEA MAYOR AL MAX DE LA COLUMNA         
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre proveedor con una mayor longitud. ';
                END IF;

                IF length(d_datos.nombre_proveedor) <= 0 THEN --QUE NO ESTE VACIO O '   '
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre proveedor vacío. ';
                END IF;

                --TELEFONO
                IF d_datos.telefono IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono proveedor nulo. ';
                END IF;

                IF length(d_datos.telefono) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono proveedor vacío. ';
                END IF;

                IF length(d_datos.telefono) < 3 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono proveedor con longitud menor. ';
                END IF;

                IF valida_numero_entero(d_datos.telefono) = 'N' THEN --NO DEBERIA DE SER DE OTRO TIPO APARTE DE ENTERO
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono proveedor no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.telefono ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Teléfono proveedor negativo o cero. ';
                    END IF;

                END IF;

                --COD POSTAL
                --PODRIAMOS VALIDAR LA LONGITUD PERO EN PAISES COMO MONACO LOS COD POSTAL SON DE UN SOLO NUM
                IF d_datos.cod_postal IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Código postal proveedor nulo. ';
                END IF;

                IF length(d_datos.cod_postal) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Código postal proveedor vacío. ';
                END IF;

                IF valida_numero_entero(d_datos.cod_postal) = 'N' THEN --NO DEBERIA DE SER DE OTRO TIPO APARTE DE ENTERO
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Código postal proveedor no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.cod_postal ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Código postal proveedor negativo o cero. ';
                    END IF;

                END IF;

                --EMAIL
                IF d_datos.email IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email proveedor nulo. ';
                END IF;

                IF length(d_datos.email) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email proveedor vacío. ';
                END IF;

                IF valida_numero_entero(d_datos.email) = 'S' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email proveedor no es varchar2. ';
                END IF;

                IF valida_email(d_datos.email) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email proveedor no tiene formato valido. ';
                END IF;

                --ESTADO
                IF d_datos.estado IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado proveedor nulo. ';
                END IF;

                IF length(d_datos.estado) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado proveedor vacío. ';
                END IF;

                IF valida_estado(d_datos.estado) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado proveedor es 0. ';
                END IF;

                --VERIFICAMOS ERRORES
                IF v_error = 0 THEN
                    INSERT INTO inventariodw.dim_proveedor (
                        prv_id,
                        prv_nombre,
                        prv_telefono,
                        prv_cod_postal,
                        prv_email
                    ) VALUES ( TO_NUMBER(d_datos.id_proveedor),
                               d_datos.nombre_proveedor,
                               TO_NUMBER(d_datos.telefono),
                               TO_NUMBER(d_datos.cod_postal),
                               d_datos.email );

                ELSE
                    INSERT INTO inventariodw.error_proveedor (
                        id_proveedor,
                        nombre_proveedor,
                        telefono,
                        cod_postal,
                        email,
                        estado,
                        error_msj
                    ) VALUES ( d_datos.id_proveedor,
                               d_datos.nombre_proveedor,
                               d_datos.telefono,
                               d_datos.cod_postal,
                               d_datos.email,
                               d_datos.estado,
                               v_error_mensaje );

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    INSERT INTO inventariodw.error_proveedor (
                        id_proveedor,
                        nombre_proveedor,
                        telefono,
                        cod_postal,
                        email,
                        estado,
                        error_msj
                    ) VALUES ( d_datos.id_proveedor,
                               d_datos.nombre_proveedor,
                               d_datos.telefono,
                               d_datos.cod_postal,
                               d_datos.email,
                               d_datos.estado,
                               v_error_mensaje );

            END;
        END LOOP;
    END migrarproveedor;

    --Migracion de los empleados
    PROCEDURE migrarempleado IS

        v_error         INTEGER;
        v_numero        INTEGER;
        v_error_mensaje VARCHAR2(4000);
        CURSOR c_datos IS --CICLO INICIO
        SELECT
            emp.id_empleado,
            emp.nombre,
            emp.apellido_p,
            emp.apellido_m,
            emp.puesto,
            emp.email,
            emp.telefono,
            emp.estado
        FROM
            inventariosa.sa_empleado emp
        WHERE
            emp.id_empleado NOT IN (
                SELECT
                    d.emp_id
                FROM
                    inventariodw.dim_empleado d
            )
        ORDER BY
            emp.id_empleado;

    BEGIN
        FOR d_datos IN c_datos LOOP
            BEGIN
                v_error := 0;
                v_error_mensaje := '';

                --PK VALIDACIONES
                --pK ES NULO O INEXISTENTE
                IF d_datos.id_empleado IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador nulo. ';
                END IF;

                IF valida_numero_entero(d_datos.id_empleado) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.id_empleado ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Identificador negativo o cero. ';
                    END IF;

                END IF;

                --NOMBRE
                IF d_datos.nombre IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre empleado nulo. ';
                END IF;

                IF length(d_datos.nombre) > 50 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre empleado con una mayor longitud. ';
                END IF;

                IF length(d_datos.nombre) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre empleado vacío. ';
                END IF;

                --APELLIDO PATERNO
                IF d_datos.apellido_p IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Apellido paterno empleado nulo. ';
                END IF;

                IF length(d_datos.apellido_p) > 50 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Apellido paterno empleado con una mayor longitud. ';
                END IF;

                IF length(d_datos.apellido_p) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Apellido paterno empleado vacío. ';
                END IF;

                --APELLIDO MATERNO
                IF d_datos.apellido_m IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Apellido materno empleado nulo. ';
                END IF;

                IF length(d_datos.apellido_m) > 50 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Apellido materno empleado con una mayor longitud. ';
                END IF;

                IF length(d_datos.apellido_m) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Apellido materno empleado vacío. ';
                END IF;

                --PUESTO
                IF d_datos.puesto IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Puesto empleado nulo. ';
                END IF;

                IF length(d_datos.puesto) > 50 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Puesto empleado con una mayor longitud. ';
                END IF;

                IF length(d_datos.puesto) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Puesto empleado vacío. ';
                END IF;

                --TELEFONO
                IF d_datos.telefono IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono empleado nulo. ';
                END IF;

                IF length(d_datos.telefono) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono empleado vacío. ';
                END IF;

                IF length(d_datos.telefono) < 3 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono empleado con longitud menor. ';
                END IF;

                IF valida_numero_entero(d_datos.telefono) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Teléfono empleado no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.telefono ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Teléfono empleado negativo o cero. ';
                    END IF;

                END IF;

                --EMAIL
                IF d_datos.email IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email empleado nulo. ';
                END IF;

                IF length(d_datos.email) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email empleado vacío. ';
                END IF;

                IF valida_numero_entero(d_datos.email) = 'S' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email empleado no es varchar2. ';
                END IF;

                IF valida_email(d_datos.email) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Email empleado no tiene formato valido. ';
                END IF;

                --ESTADO
                IF d_datos.estado IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado empleado nulo. ';
                END IF;

                IF length(d_datos.estado) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado empleado vacío. ';
                END IF;

                IF valida_estado(d_datos.estado) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado empleado es 0. ';
                END IF;

                --VERIFICAMOS ERRORES
                IF v_error = 0 THEN
                    INSERT INTO inventariodw.dim_empleado (
                        emp_id,
                        emp_nombre,
                        emp_apellido_p,
                        emp_apellido_m,
                        emp_puesto,
                        emp_email,
                        emp_telefono
                    ) VALUES ( TO_NUMBER(d_datos.id_empleado),
                               d_datos.nombre,
                               d_datos.apellido_p,
                               d_datos.apellido_m,
                               d_datos.puesto,
                               d_datos.email,
                               TO_NUMBER(d_datos.telefono) );

                ELSE
                    INSERT INTO inventariodw.error_empleado (
                        id_empleado,
                        nombre,
                        apellido_p,
                        apellido_m,
                        puesto,
                        email,
                        telefono,
                        estado,
                        error_msj
                    ) VALUES ( d_datos.id_empleado,
                               d_datos.nombre,
                               d_datos.apellido_p,
                               d_datos.apellido_m,
                               d_datos.puesto,
                               d_datos.email,
                               d_datos.telefono,
                               d_datos.estado,
                               v_error_mensaje );

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    INSERT INTO inventariodw.error_empleado (
                        id_empleado,
                        nombre,
                        apellido_p,
                        apellido_m,
                        puesto,
                        email,
                        telefono,
                        estado,
                        error_msj
                    ) VALUES ( d_datos.id_empleado,
                               d_datos.nombre,
                               d_datos.apellido_p,
                               d_datos.apellido_m,
                               d_datos.puesto,
                               d_datos.email,
                               d_datos.telefono,
                               d_datos.estado,
                               v_error_mensaje );

            END;
        END LOOP;
    END migrarempleado;


   --Migracion de los productos
    PROCEDURE migrarproducto IS

        v_error         INTEGER;
        v_numero        INTEGER;
        v_error_mensaje VARCHAR2(4000);
        CURSOR c_datos IS --CICLO INICIO
        SELECT
            prd.id_producto,
            prd.nombre_prod,
            prd.descripcion_prod,
            prd.categoria_id,
            prd.precio_unidad,
            prd.estado
        FROM
            inventariosa.sa_producto prd
        WHERE
            prd.id_producto NOT IN (
                SELECT
                    d.prd_id
                FROM
                    inventariodw.dim_producto d
            )
        ORDER BY
            prd.id_producto;

    BEGIN
        FOR d_datos IN c_datos LOOP
            BEGIN
                v_error := 0;
                v_error_mensaje := '';

                --PK VALIDACIONES
                --pK ES NULO O INEXISTENTE
                IF d_datos.id_producto IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador nulo. ';
                END IF;

                IF valida_numero_entero(d_datos.id_producto) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.id_producto ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Identificador negativo o cero. ';
                    END IF;

                END IF;

                --NOMBRE
                IF d_datos.nombre_prod IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre producto nulo. ';
                END IF;

                IF length(d_datos.nombre_prod) > 100 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre producto con una mayor longitud. ';
                END IF;

                IF length(d_datos.nombre_prod) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Nombre producto vacío. ';
                END IF;

                --DESCRIPCION
                IF d_datos.descripcion_prod IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Descripción producto nula. ';
                END IF;

                IF length(d_datos.descripcion_prod) > 200 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Descripción producto con una mayor longitud. ';
                END IF;

                IF length(d_datos.descripcion_prod) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Descripción producto vacía. ';
                END IF;

                --CATEGORIA
                IF d_datos.categoria_id IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Categoría producto nula. ';
                END IF;

                IF length(d_datos.categoria_id) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Categoría producto vacía. ';
                END IF;

                IF valida_numero_entero(d_datos.categoria_id) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Categoría producto no númerica. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.categoria_id ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Categoría producto negativa o cero. ';
                    END IF;

                END IF;

                --PRECIO UNIDAD
                IF d_datos.precio_unidad IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Precio unidad producto nulo. ';
                END IF;

                IF length(d_datos.precio_unidad) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Precio unidad producto vacío. ';
                END IF;
                --ES VALIDO SI ES ENTERO O DECIMAL, YA QUE LA COLUMNA ES NUMBER(10,2)
                IF
                    valida_numero_entero(d_datos.precio_unidad) = 'N'
                    AND valida_numero_decimal(d_datos.precio_unidad) = 'N'
                THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Precio unidad producto no númerico y/o decimal. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.precio_unidad ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Precio unidad producto negativo o cero. ';
                    END IF;

                END IF;

                --ESTADO
                IF d_datos.estado IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado producto nulo. ';
                END IF;

                IF length(d_datos.estado) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado producto vacío. ';
                END IF;

                IF valida_estado(d_datos.estado) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Estado producto es 0. ';
                END IF;

                --VERIFICAMOS ERRORES
                IF v_error = 0 THEN
                    INSERT INTO inventariodw.dim_producto (
                        prd_id,
                        prd_nombre,
                        prd_descripcion,
                        prd_categoria_id,
                        prd_precio_unidad
                    ) VALUES ( TO_NUMBER(d_datos.id_producto),
                               d_datos.nombre_prod,
                               d_datos.descripcion_prod,
                               TO_NUMBER(d_datos.categoria_id),
                               TO_NUMBER(d_datos.precio_unidad) );

                ELSE
                    INSERT INTO inventariodw.error_producto (
                        id_producto,
                        nombre_prod,
                        descripcion_prod,
                        categoria_id,
                        precio_unidad,
                        estado,
                        error_msj
                    ) VALUES ( d_datos.id_producto,
                               d_datos.nombre_prod,
                               d_datos.descripcion_prod,
                               d_datos.categoria_id,
                               d_datos.precio_unidad,
                               d_datos.estado,
                               v_error_mensaje );

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    INSERT INTO inventariodw.error_producto (
                        id_producto,
                        nombre_prod,
                        descripcion_prod,
                        categoria_id,
                        precio_unidad,
                        estado,
                        error_msj
                    ) VALUES ( d_datos.id_producto,
                               d_datos.nombre_prod,
                               d_datos.descripcion_prod,
                               d_datos.categoria_id,
                               d_datos.precio_unidad,
                               d_datos.estado,
                               v_error_mensaje );

            END;
        END LOOP;
    END migrarproducto;

    --Migracion de las ordenes de compra
    PROCEDURE migrarordencompra IS

        v_error         INTEGER;
        v_numero        INTEGER;
        v_error_mensaje VARCHAR2(4000);
        CURSOR c_datos IS --CICLO INICIO
        SELECT
            ord.id_orden,
            ord.numero_factura,
            ord.metodo_envio_id,
            ord.fecha_envio,
            ord.fecha_orden
        FROM
            inventariosa.sa_orden_compra ord
        WHERE
            ord.id_orden NOT IN (
                SELECT
                    d.ord_id
                FROM
                    inventariodw.dim_orden_compra d
            )
        ORDER BY
            ord.id_orden;

    BEGIN
        FOR d_datos IN c_datos LOOP
            BEGIN
                v_error := 0;
                v_error_mensaje := '';

                --PK VALIDACIONES
                --pK ES NULO O INEXISTENTE
                IF d_datos.id_orden IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador nulo. ';
                END IF;

                IF valida_numero_entero(d_datos.id_orden) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.id_orden ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Identificador negativo o cero. ';
                    END IF;

                END IF;

                --NUMERO FACTURA
                IF d_datos.numero_factura IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Número de factura nulo. ';
                END IF;

                IF length(d_datos.numero_factura) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Número de factura vacío. ';
                END IF;

                IF valida_numero_entero(d_datos.numero_factura) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Número de factura no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.numero_factura ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Número de factura negativo o cero. ';
                    END IF;

                END IF;

                --METODO ENVIO
                IF d_datos.metodo_envio_id IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Método de envío nulo. ';
                END IF;

                IF length(d_datos.metodo_envio_id) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Método de envío vacío. ';
                END IF;

                IF valida_numero_entero(d_datos.metodo_envio_id) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Método de envío no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.metodo_envio_id ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Método de envío negativo o cero. ';
                    END IF;

                END IF;

                --FECHA ENVIO
                IF d_datos.fecha_envio IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de envío nula. ';
                END IF;

                IF length(d_datos.fecha_envio) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de envío vacía. ';
                END IF;

                IF valida_fecha(d_datos.fecha_envio) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de envío no tiene formato válido. ';
                END IF;

                --FECHA ORDEN
                IF d_datos.fecha_orden IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de orden nula. ';
                END IF;

                IF length(d_datos.fecha_orden) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de orden vacía. ';
                END IF;

                IF valida_fecha(d_datos.fecha_orden) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de orden no tiene formato válido. ';
                END IF;

                --VERIFICAMOS ERRORES
                IF v_error = 0 THEN
                    INSERT INTO inventariodw.dim_orden_compra (
                        ord_id,
                        ord_numero_factura,
                        ord_metodo_envio_id,
                        ord_fecha_envio,
                        ord_fecha_orden
                    ) VALUES ( TO_NUMBER(d_datos.id_orden),
                               TO_NUMBER(d_datos.numero_factura),
                               TO_NUMBER(d_datos.metodo_envio_id),
                               TO_DATE(d_datos.fecha_envio, 'YYYYMMDD'),
                               TO_DATE(d_datos.fecha_orden, 'YYYYMMDD') );

                ELSE
                    INSERT INTO inventariodw.error_orden_compra (
                        id_orden,
                        numero_factura,
                        metodo_envio_id,
                        fecha_envio,
                        fecha_orden,
                        error_msj
                    ) VALUES ( d_datos.id_orden,
                               d_datos.numero_factura,
                               d_datos.metodo_envio_id,
                               d_datos.fecha_envio,
                               d_datos.fecha_orden,
                               v_error_mensaje );

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    INSERT INTO inventariodw.error_orden_compra (
                        id_orden,
                        numero_factura,
                        metodo_envio_id,
                        fecha_envio,
                        fecha_orden,
                        error_msj
                    ) VALUES ( d_datos.id_orden,
                               d_datos.numero_factura,
                               d_datos.metodo_envio_id,
                               d_datos.fecha_envio,
                               d_datos.fecha_orden,
                               v_error_mensaje );

            END;
        END LOOP;
    END migrarordencompra;

    --Migracion de  mov inv
    --Este es un poco especial ya que solo lo vamos a usar para
    --cargar la dim fecha
    PROCEDURE migrarmovimientoinv IS

        v_error         INTEGER;
        v_numero        INTEGER;
        v_error_mensaje VARCHAR2(4000);
        CURSOR c_datos IS --CICLO INICIO
        SELECT
            movi.id_movimiento,
            movi.fecha
        FROM
            inventariosa.sa_movimiento_inv movi
        WHERE
            movi.id_movimiento NOT IN (
                SELECT
                    d.fec_id
                FROM
                    inventariodw.dim_fecha d
            )
        ORDER BY
            movi.id_movimiento;

    BEGIN
        FOR d_datos IN c_datos LOOP
            BEGIN
                v_error := 0;
                v_error_mensaje := '';

                --PK VALIDACIONES
                --pK ES NULO O INEXISTENTE
                IF d_datos.id_movimiento IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador nulo. ';
                END IF;

                IF valida_numero_entero(d_datos.id_movimiento) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Identificador no númerico. ';
                ELSE
                    v_numero := TO_NUMBER ( d_datos.id_movimiento ); --CONVERTIMOS
                    IF v_numero <= 0 THEN
                        v_error := 1;
                        v_error_mensaje := v_error_mensaje || 'Identificador negativo o cero. ';
                    END IF;

                END IF;

                --FECHA
                IF d_datos.fecha IS NULL THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha nula. ';
                END IF;

                IF length(d_datos.fecha) <= 0 THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de envío vacía. ';
                END IF;

                IF valida_fecha(d_datos.fecha) = 'N' THEN
                    v_error := 1;
                    v_error_mensaje := v_error_mensaje || 'Fecha de envío no tiene formato válido. ';
                END IF;

                --VERIFICAMOS ERRORES
                IF v_error = 0 THEN
                    INSERT INTO inventariodw.dim_fecha (
                        fec_id,
                        fec_fecha
                    ) VALUES ( TO_NUMBER(d_datos.fecha),
                               TO_DATE(d_datos.fecha, 'YYYYMMDD') ); --INSERTAMOS LA FECHA COMO EL MISMO ID!
                            --ANTERIORMENTE SE TENIA EL ID MOV COMO ID DE AQUI PERO PUEDE CAUSAR PROBLEMAS 
                ELSE
                    INSERT INTO inventariodw.error_movimiento_inv (
                        id_movimiento,
                        fecha,
                        error_msj
                    ) VALUES ( d_datos.id_movimiento,
                               d_datos.fecha,
                               v_error_mensaje );

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    INSERT INTO inventariodw.error_movimiento_inv (
                        id_movimiento,
                        fecha,
                        error_msj
                    ) VALUES ( d_datos.id_movimiento,
                               d_datos.fecha,
                               v_error_mensaje );

            END;
        END LOOP;
    END migrarmovimientoinv;

        --PRINCIPAL
    PROCEDURE migrardatos AS
    BEGIN
        migrarproveedor;
        migrarempleado;
        migrarproducto;
        migrarordencompra;
        migrarmovimientoinv;
        COMMIT;
    END migrardatos;

END etl_dw;
/

EXECUTE INVENTARIODW.ETL_DW.MigrarDatos;