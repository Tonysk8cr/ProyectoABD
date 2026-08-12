--------------------------------------------
--Consulta de creacion del ETL del SA
--------------------------------------------

--Referencia del porque usar el to_char:
--https://sites.google.com/site/jmdstips/oracle/to_char-function
--Usamos TO_CHAR solo para valores de tipo de date, para asi poder darle un formato varchar2 (dd/mm/aaaa -> AAAAMMDD)

CREATE OR REPLACE PACKAGE pg_etl_sa AS
--Inicio de los funciones para cargar los datos del ER
    PROCEDURE carga_proveedores;

    PROCEDURE carga_empleado;

    PROCEDURE carga_productos;

    PROCEDURE carga_orden_compra;

    PROCEDURE carga_detalle_compra; --Necesario para poder hacer bien el proceso de migracion de la tabla de hechos

    PROCEDURE carga_movimiento_inv;

    PROCEDURE carga_datos;

END pg_etl_sa;
/

--Creacion del body.
CREATE OR REPLACE PACKAGE BODY pg_etl_sa AS

    PROCEDURE carga_proveedores AS --Primer proceso
    BEGIN
        INSERT INTO inventariosa.sa_proveedor (
            id_proveedor,
            nombre_proveedor,
            telefono,
            cod_postal,
            email,
            estado
        )
            SELECT
                id_proveedor,
                nombre_proveedor,
                telefono,
                cod_postal,
                email,
                estado
            FROM
                inventario.proveedores
            WHERE
                id_proveedor NOT IN (
                    SELECT
                        id_proveedor
                    FROM
                        inventariosa.sa_proveedor
                ); 
        --El filtro de estado lo vamos a hacer hasta el etl del dw, en caso de que esos records los ocupemos a futuro
    END carga_proveedores;

    PROCEDURE carga_empleado AS --Segundo proceso
    BEGIN
        INSERT INTO inventariosa.sa_empleado (
            id_empleado,
            nombre,
            apellido_p,
            apellido_m,
            puesto,
            email,
            telefono,
            estado
        )
            SELECT
                id_empleado,
                nombre,
                apellido_p,
                apellido_m,
                puesto,
                email,
                telefono,
                estado
            FROM
                inventario.empleado
            WHERE
                id_empleado NOT IN (
                    SELECT
                        id_empleado
                    FROM
                        inventariosa.sa_empleado
                );

    END carga_empleado;

    PROCEDURE carga_productos AS --Tercer proceso
    BEGIN
        INSERT INTO inventariosa.sa_producto (
            id_producto,
            nombre_prod,
            descripcion_prod,
            categoria_id,
            precio_unidad,
            estado
        )
            SELECT
                id_producto,
                nombre_prod,
                descripcion_prod,
                categoria_id,
                precio_unidad,
                estado
            FROM
                inventario.productos
            WHERE
                id_producto NOT IN (
                    SELECT
                        id_producto
                    FROM
                        inventariosa.sa_producto
                );

    END carga_productos;

    PROCEDURE carga_orden_compra AS --Cuarto proceso
    BEGIN
        INSERT INTO inventariosa.sa_orden_compra (
            id_orden,
            numero_factura,
            proveedor_id,
            empleado_id,
            descripcion,
            metodo_envio_id,
            fecha_envio,
            fecha_orden
        )
            SELECT
                id_orden,
                numero_factura,
                proveedor_id,
                empleado_id,
                descripcion,
                metodo_envioid,
                to_char(fecha_envio, 'YYYYMMDD'),
                to_char(fecha_orden, 'YYYYMMDD')
            FROM
                inventario.orden_compra
            WHERE
                id_orden NOT IN (
                    SELECT
                        id_orden
                    FROM
                        inventariosa.sa_orden_compra
                );

    END carga_orden_compra;

    PROCEDURE carga_detalle_compra AS -- Quinto proceso
    BEGIN
        INSERT INTO inventariosa.sa_detalle_compra (
            id_detalle,
            producto_id,
            orden_compra,
            cantidad,
            detalle_precio
        )
            SELECT
                id_detalle,
                producto_id,
                orden_compra,
                cantidad,
                detalle_precio
            FROM
                inventario.detalle_compra
            WHERE
                id_detalle NOT IN (
                    SELECT
                        id_detalle
                    FROM
                        inventariosa.sa_detalle_compra
                );

    END carga_detalle_compra;

    PROCEDURE carga_movimiento_inv AS -- Sexto proceso
    BEGIN
        INSERT INTO inventariosa.sa_movimiento_inv (
            id_movimiento,
            cantidad_mov,
            id_producto,
            id_empleado,
            id_inventario,
            fecha
        )
            SELECT
                id_movimiento,
                cantidad_mov,
                id_producto,
                id_empleado,
                id_inventario,
                to_char(fecha, 'YYYYMMDD')
            FROM
                inventario.movimiento_inv
            WHERE
                id_movimiento NOT IN (
                    SELECT
                        id_movimiento
                    FROM
                        inventariosa.sa_movimiento_inv
                );

    END carga_movimiento_inv;

    PROCEDURE carga_datos AS --Proceso principal
    BEGIN
        carga_proveedores; --1
        carga_empleado; --2
        carga_productos; --3
        carga_orden_compra; --4
        carga_detalle_compra; --5 Necesario para poder hacer bien el proceso de migracion de la tabla de hechos
        carga_movimiento_inv; --6
        COMMIT;
    END carga_datos;

END pg_etl_sa;
/

EXECUTE PG_ETL_SA.CARGA_DATOS;