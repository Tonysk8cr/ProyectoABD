-- Reutilizamos las mismas consultas para las validaciones
-- Modificamos la de fecha por el formato con el que se guarda en el sa YYYYMMDD

CREATE OR REPLACE FUNCTION VALIDA_NUMERO_ENTERO(P_NUMERO VARCHAR2) RETURN CHAR AS
   V_NUMERO NUMBER;
BEGIN
   V_NUMERO := TO_NUMBER(P_NUMERO);
   IF V_NUMERO = TRUNC(V_NUMERO) THEN
      RETURN 'S';
   ELSE
      RETURN 'N';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RETURN 'N';
END;
/

CREATE OR REPLACE FUNCTION VALIDA_NUMERO_DECIMAL(P_NUMERO VARCHAR2) RETURN CHAR AS
   V_NUMERO NUMBER(20,2);
BEGIN
   V_NUMERO := TO_NUMBER(P_NUMERO);
   IF V_NUMERO <> TRUNC(V_NUMERO) THEN
      RETURN 'S';
   ELSE
      RETURN 'N';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RETURN 'N';
END;
/

CREATE OR REPLACE FUNCTION VALIDA_FECHA(P_FECHA VARCHAR2) RETURN CHAR AS
   V_FECHA DATE;
BEGIN
   V_FECHA := TO_DATE(P_FECHA, 'YYYYMMDD'); --Validamos el formato
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
CREATE OR REPLACE FUNCTION VALIDA_EMAIL(P_EMAIL VARCHAR2) RETURN CHAR AS
BEGIN
    -- VERIFICA QUE NO SEA NULO Y QUE CUMPLA CON EL PATRON
    IF P_EMAIL IS NOT NULL 
    -- ^ = INICIO DE LA CADENA, [] = CARAC PERMITIDOS + = UNO MAS, ES PARA DECIR DESPUES DE []
       AND REGEXP_LIKE(P_EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') 
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


--VALIDA ESTADO 1 = ACTIVE 0 = OFF
CREATE OR REPLACE FUNCTION VALIDA_ESTADO(P_ESTADO VARCHAR2) RETURN CHAR AS
    V_ESTADO VARCHAR2(1);
BEGIN

    IF TRIM(P_ESTADO) IS NULL OR LENGTH(TRIM(P_ESTADO)) != 1 THEN
        RETURN 'N';
    END IF;

    V_ESTADO := TRIM(P_ESTADO);

    IF V_ESTADO = '1' THEN 
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
CREATE TABLE INVENTARIODW.ERROR_PROVEEDOR (
    ID_PROVEEDOR    VARCHAR2(4000),
    NOMBRE_PROVEEDOR VARCHAR2(4000),
    TELEFONO        VARCHAR2(4000),
    COD_POSTAL      VARCHAR2(4000),
    EMAIL           VARCHAR2(4000),
    ESTADO          VARCHAR2(4000),
    ERROR_MSJ       VARCHAR2(4000)
);

CREATE TABLE INVENTARIODW.ERROR_EMPLEADO (
    ID_EMPLEADO        VARCHAR2(4000),
    NOMBRE             VARCHAR2(4000),
    APELLIDO_P         VARCHAR2(4000),
    APELLIDO_M         VARCHAR2(4000),
    PUESTO             VARCHAR2(4000),
    EMAIL              VARCHAR2(4000),
    TELEFONO           VARCHAR2(4000),
    ESTADO             VARCHAR2(4000),
    ERROR_MSJ       VARCHAR2(4000)
);

CREATE TABLE INVENTARIODW.ERROR_PRODUCTO (
    ID_PRODUCTO        VARCHAR2(4000),
    NOMBRE_PROD        VARCHAR2(4000),
    DESCRIPCION_PROD   VARCHAR2(4000),
    CATEGORIA_ID       VARCHAR2(4000),
    PRECIO_UNIDAD      VARCHAR2(4000),
    ESTADO             VARCHAR2(4000),
    ERROR_MSJ       VARCHAR2(4000)
);

CREATE TABLE INVENTARIODW.ERROR_ORDEN_COMPRA (
    ID_ORDEN           VARCHAR2(4000),
    NUMERO_FACTURA     VARCHAR2(4000),
    PROVEEDOR_ID       VARCHAR2(4000),
    EMPLEADO_ID        VARCHAR2(4000),
    DESCRIPCION        VARCHAR2(4000),
    METODO_ENVIO_ID    VARCHAR2(4000),
    FECHA_ENVIO        VARCHAR2(4000),
    FECHA_ORDEN        VARCHAR2(4000),
    ERROR_MSJ          VARCHAR2(4000)
);

CREATE TABLE INVENTARIODW.ERROR_MOVIMIENTO_INV (
    ID_MOVIMIENTO      VARCHAR2(4000),
    CANTIDAD_MOV       VARCHAR2(4000),
    ID_PRODUCTO        VARCHAR2(4000),
    ID_EMPLEADO        VARCHAR2(4000),
    ID_INVENTARIO      VARCHAR2(4000),
    FECHA              VARCHAR2(4000),
    ERROR_MSJ          VARCHAR2(4000)
);


-----------------------------------------------
--PAQUETE 
-----------------------------------------------
CREATE OR REPLACE PACKAGE INVENTARIODW.ETL_DW AS 
    PROCEDURE MigrarProveedor; --1
    PROCEDURE MigrarEmpleado; --2
    PROCEDURE MigrarProducto; --3
    PROCEDURE MigrarOrdenCompra; --4
    PROCEDURE MigrarMovimientoInv; --5

    PROCEDURE MigrarDatos; --main
END ETL_DW;
/

--Body del paquete

CREATE OR REPLACE PACKAGE BODY INVENTARIODW.ETL_DW AS
    --Migracion de los proveedores
    PROCEDURE MigrarProveedor IS
    V_ERROR INTEGER;
    V_NUMERO INTEGER;
    V_ERROR_MENSAJE VARCHAR2(4000);
    CURSOR C_DATOS IS --CICLO INICIO
        SELECT PROV.ID_PROVEEDOR,
                PROV.NOMBRE_PROVEEDOR,
                PROV.TELEFONO,
                PROV.COD_POSTAL,
                PROV.EMAIL,
                PROV.ESTADO
        FROM INVENTARIOSA.SA_PROVEEDOR PROV
        WHERE PROV.ID_PROVEEDOR NOT IN (SELECT D.PRV_ID FROM INVENTARIODW.DIM_PROVEEDOR D)
        ORDER BY PROV.ID_PROVEEDOR;
    BEGIN
        FOR D_DATOS IN C_DATOS LOOP
            BEGIN
                V_ERROR := 0;
                V_ERROR_MENSAJE := '';

                --PK VALIDACIONES
                --pK ES NULO O INEXISTENTE
                IF D_DATOS.ID_PROVEEDOR IS NULL THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Identificador nulo. ';
                END IF;

                IF VALIDA_NUMERO_ENTERO(D_DATOS.ID_PROVEEDOR) = 'N' THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Identificador no númerico. ';
                ELSE
                    V_NUMERO := TO_NUMBER(D_DATOS.ID_PROVEEDOR); --CONVERTIMOS
                    IF V_NUMERO <= 0 THEN
                        V_ERROR := 1;
                        V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Identificador negativo o cero. ';
                    END IF;
                END IF;

                --NOMBRE
                IF D_DATOS.NOMBRE_PROVEEDOR IS NULL THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Nombre proveedor nulo. ';  
                END IF;
                IF LENGTH(D_DATOS.NOMBRE_PROVEEDOR) > 100 THEN       --QUE NO SEA MAYOR AL MAX DE LA COLUMNA         
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Nombre proveedor con una mayor longitud. '; 
                END IF;
                IF LENGTH(D_DATOS.NOMBRE_PROVEEDOR) <= 0 THEN --QUE NO ESTE VACIO O '   '
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Nombre proveedor vacío. ';
                END IF;

                --TELEFONO
                IF D_DATOS.TELEFONO IS NULL THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Teléfono proveedor nulo. '; 
                END IF;
                IF LENGTH(D_DATOS.TELEFONO) <= 0 THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Teléfono proveedor vacío. ';
                END IF;
                IF LENGTH(D_DATOS.TELEFONO) < 3 THEN
                    V_ERROR := 1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Teléfono proveedor con longitud menor. ';
                END IF;
                IF VALIDA_NUMERO_ENTERO(D_DATOS.TELEFONO) = 'N' THEN --NO DEBERIA DE SER DE OTRO TIPO APARTE DE ENTERO
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Teléfono proveedor no númerico. ';
                ELSE
                    V_NUMERO := TO_NUMBER(D_DATOS.TELEFONO); --CONVERTIMOS
                    IF V_NUMERO <= 0 THEN
                        V_ERROR := 1;
                        V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Teléfono proveedor negativo o cero. ';
                    END IF;
                END IF;

                --COD POSTAL
                --PODRIAMOS VALIDAR LA LONGITUD PERO EN PAISES COMO MONACO LOS COD POSTAL SON DE UN SOLO NUM
                IF D_DATOS.COD_POSTAL IS NULL THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Código postal proveedor nulo. '; 
                END IF;
                IF LENGTH(D_DATOS.COD_POSTAL) <= 0 THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Código postal proveedor vacío. ';
                END IF;
                IF VALIDA_NUMERO_ENTERO(D_DATOS.COD_POSTAL) = 'N' THEN --NO DEBERIA DE SER DE OTRO TIPO APARTE DE ENTERO
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Código postal proveedor no númerico. ';
                ELSE
                    V_NUMERO := TO_NUMBER(D_DATOS.COD_POSTAL); --CONVERTIMOS
                    IF V_NUMERO <= 0 THEN
                        V_ERROR := 1;
                        V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Código postal proveedor negativo o cero. ';
                    END IF;
                END IF;

                --EMAIL
                IF D_DATOS.EMAIL IS NULL THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Email proveedor nulo. '; 
                END IF;
                IF LENGTH(D_DATOS.EMAIL) <= 0 THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Email proveedor vacío. ';
                END IF;
                IF VALIDA_NUMERO_ENTERO(D_DATOS.EMAIL) = 'S' THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Email proveedor no es varchar2. ';
                END IF;
                IF VALIDA_EMAIL(D_DATOS.EMAIL) = 'N' THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Email proveedor no tiene formato valido. ';
                END IF;

                --ESTADO
                IF D_DATOS.ESTADO IS NULL THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Estado proveedor nulo. '; 
                END IF;
                IF LENGTH(D_DATOS.ESTADO) <= 0 THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Estado proveedor vacío. ';
                END IF;
                IF VALIDA_ESTADO(D_DATOS.ESTADO) = 'N' THEN
                    V_ERROR :=1;
                    V_ERROR_MENSAJE := V_ERROR_MENSAJE || 'Estado proveedor es 0. ';
                END IF;

                --VERIFICAMOS ERRORES
                IF V_ERROR = 0 THEN
                    INSERT
                     INTO INVENTARIODW.DIM_PROVEEDOR (PRV_ID, PRV_NOMBRE, PRV_TELEFONO, PRV_COD_POSTAL, PRV_EMAIL)
                        VALUES (TO_NUMBER(D_DATOS.ID_PROVEEDOR), D_DATOS.NOMBRE_PROVEEDOR, TO_NUMBER(D_DATOS.TELEFONO), TO_NUMBER(D_DATOS.COD_POSTAL), D_DATOS.EMAIL);
                ELSE
                    INSERT INTO INVENTARIODW.ERROR_PROVEEDOR (ID_PROVEEDOR, NOMBRE_PROVEEDOR, TELEFONO, COD_POSTAL, EMAIL, ESTADO, ERROR_MSJ)
                        VALUES (D_DATOS.ID_PROVEEDOR, D_DATOS.NOMBRE_PROVEEDOR, D_DATOS.TELEFONO, D_DATOS.COD_POSTAL, D_DATOS.EMAIL, D_DATOS.ESTADO, V_ERROR_MENSAJE);
                END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        INSERT INTO INVENTARIODW.ERROR_PROVEEDOR (ID_PROVEEDOR, NOMBRE_PROVEEDOR, TELEFONO, COD_POSTAL, EMAIL, ESTADO, ERROR_MSJ)
                            VALUES (D_DATOS.ID_PROVEEDOR, D_DATOS.NOMBRE_PROVEEDOR, D_DATOS.TELEFONO, D_DATOS.COD_POSTAL, D_DATOS.EMAIL, D_DATOS.ESTADO, V_ERROR_MENSAJE);
        END;
    END LOOP;
END;













