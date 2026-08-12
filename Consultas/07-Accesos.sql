--------------------------------------------------------------------------------
-- Esto se ejecuta con el usuario SYS.
--------------------------------------------------------------------------------
GRANT SELECT ON INVENTARIO.PROVEEDORES TO INVENTARIODW;
GRANT SELECT ON INVENTARIO.EMPLEADO TO INVENTARIODW;
GRANT SELECT ON INVENTARIO.PRODUCTOS TO INVENTARIODW;
GRANT SELECT ON INVENTARIO.ORDEN_COMPRA TO INVENTARIODW;
GRANT SELECT ON INVENTARIO.MOVIMIENTO_INV TO INVENTARIODW;
GRANt SELECT ON INVENTARIO.DETALLE_COMPRA TO INVENTARIODW; --Necesario para poder hacer bien el proceso de migracion de la tabla de hechos
--------------------------------------------------------------------------------
GRANT SELECT, INSERT ON INVENTARIOSA.SA_PROVEEDOR TO INVENTARIODW;
GRANT SELECT, INSERT ON INVENTARIOSA.SA_EMPLEADO TO INVENTARIODW;
GRANT SELECT, INSERT ON INVENTARIOSA.SA_PRODUCTO TO INVENTARIODW;
GRANT SELECT, INSERT ON INVENTARIOSA.SA_ORDEN_COMPRA TO INVENTARIODW;
GRANT SELECT, INSERT ON INVENTARIOSA.SA_MOVIMIENTO_INV TO INVENTARIODW;
GRANT SELECT, INSERT ON INVENTARIOSA.SA_DETALLE_COMPRA TO INVENTARIODW; --Necesario para poder hacer bien el proceso de migracion de la tabla de hechos
--------------------------------------------------------------------------------
