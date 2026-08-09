--Luego crea la conexion.
--Se ejecuta con SYS.

--Corran esto primero
ALTER SESSION SET "_ORACLE_SCRIPT" = true;

--Este par crear el usuario del modelo relacional
CREATE USER inventariosa IDENTIFIED BY inventario123
    DEFAULT TABLESPACE users
    QUOTA UNLIMITED ON users;

GRANT connect, resource TO inventariosa;