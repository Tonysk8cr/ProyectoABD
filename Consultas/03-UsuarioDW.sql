-- Creacion de usuario para modelo Multidimensional.
--Luego crea la conexion.
--Se ejecuta con SYS.

--Corran esto primero
ALTER SESSION SET "_ORACLE_SCRIPT" = true;

--Este para crear el usuario del dw
CREATE USER inventariodw IDENTIFIED BY inventario123
    DEFAULT TABLESPACE users
    QUOTA UNLIMITED ON users;

GRANT connect, resource TO inventariodw;