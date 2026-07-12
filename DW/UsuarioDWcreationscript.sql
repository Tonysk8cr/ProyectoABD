
-- Creacion de usuario para modelo Multidimensional.
--Luego crea la conexion.
--Se ejecuta con SYS.

--Corran esto primero
alter session set "_ORACLE_SCRIPT" = TRUE;

--Este par crear el usuario del modelo relacional
CREATE USER INVENTARIO IDENTIFIED BY inventario123 DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE TO INVENTARIO;

--Este para crear el usuario del dw
CREATE USER INVENTARIODW IDENTIFIED BY inventario123 DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE TO INVENTARIODW;