

# Proyecto ABD
## Sistema de Administración de Inventarios con Data Warehouse y Staging Area



## Descripción General

Proyecto académico desarrollado para el curso de Aplicaciones de Bases de Datos de la Universidad Hispanoamericana.

El proyecto implementa una solución completa de análisis de inventario compuesta por:

- Modelo Relacional (ER)
- Staging Area (SA)
- Data Warehouse (DW)
- Procesos ETL para la integración de datos

La solución utiliza Oracle Database 19c y está diseñada para administrar información relacionada con:

- Productos
- Inventario
- Proveedores
- Empleados
- Órdenes de Compra
- Movimientos de Inventario
- Bodegas

El objetivo principal es transformar datos operacionales del sistema transaccional en información estructurada para análisis y toma de decisiones.


---
## Arquitectura de la Solución

El proyecto se encuentra dividido en tres capas:

### 1. Modelo Relacional (ER)

Usuario:

INVENTARIO

Contiene las tablas operacionales del sistema:

- PROVEEDORES
- EMPLEADO
- PRODUCTOS
- INVENTARIO
- ORDEN_COMPRA
- MOVIMIENTO_INV
- DETALLE_COMPRA
- BODEGAS
- PROD_CATEGORIA
- METODO_ENVIO

### 2. Staging Area (SA)

Usuario:

INVENTARIOSA

Almacena temporalmente los datos extraídos desde el modelo relacional para facilitar los procesos ETL.

Tablas:

- SA_PROVEEDOR
- SA_EMPLEADO
- SA_PRODUCTO
- SA_ORDEN_COMPRA
- SA_MOVIMIENTO_INV

### 3. Data Warehouse (DW)

Usuario:

INVENTARIODW

Contiene el esquema dimensional para análisis histórico.

Tablas:

- FACT_INV_TRANSACCION (HECHOS)
- DIM_EMPLEADO(Dimensión)
- DIM_FECHA(Dimensión)
- DIM_ORDEN_COMPRA(Dimensión)
- DIM_PRODUCTO(Dimensión)
- DIM_PROVEEDOR(Dimensión)

---

## Procesos ETL

El proyecto incluye procesos ETL desarrollados mediante PL/SQL.

### ETL ER → SA

Responsabilidades:

- Extraer datos desde INVENTARIO
- Cargar información al Staging Area
- Evitar registros duplicados
- Estandarizar fechas utilizando formato YYYYMMDD

Procedimientos principales:

- CARGA_PROVEEDORES
- CARGA_EMPLEADO
- CARGA_PRODUCTOS
- CARGA_ORDEN_COMPRA
- CARGA_MOVIMIENTO_INV
- CARGA_DATOS

---

## Estructura del Repositorio

```text
├── DW/
│   ├── Datawarehouse.pdf
│   ├── Datawarehouse.sql
│   ├── Diseño DW.xlsx
│   ├── ProyectoABD_DW(ER).pdf
│   └── UsuarioDWcreationscript.sql
│
├── ETL/
│   └── SA_ETL.sql
│
├── Relacional/
│   ├── ProyectoABD.sql
│   ├── ProyectoABDER.pdf
│   ├── Schema_original.pdf
│   └── UsuarioERcreationscript.sql
│
├── SA/
│   ├── AccesosSA.sql
│   ├── DWStagingAreaCreacion.sql
│   └── UsuarioSAcreationscript.sql
│
└── Readme.md
```

---

## Flujo de Datos

```text
Modelo Relacional
(INVENTARIO)
        │
        ▼
Staging Area
(INVENTARIOSA)
        │
        ▼
Data Warehouse
(INVENTARIODW)
        │
        ▼
Consultas Analíticas
```

---

## Instalación

### Paso 1. Crear los usuarios

Ejecutar los scripts de creación para:

- INVENTARIO
- INVENTARIOSA
- INVENTARIODW

### Paso 2. Crear el modelo relacional

Ejecutar el script correspondiente al esquema INVENTARIO.

### Paso 3. Cargar datos de prueba

Ejecutar los INSERT suministrados en el proyecto.

### Paso 4. Crear el Staging Area

Ejecutar los scripts del esquema INVENTARIOSA.

### Paso 5. Crear el Data Warehouse

Ejecutar los scripts dimensionales del esquema INVENTARIODW.

### Paso 6. Ejecutar ETL

```sql
EXECUTE PG_ETL_SA.CARGA_DATOS;
```

---



## Equipo de Desarrollo

### Anthony Emanuel Villalobos Hidalgo | [GitHub](https://github.com/Tonysk8cr) | [LinkedIn](https://www.linkedin.com/in/anthony-villalobos-55bb1a221/)

### Santiago Fonseca

### José Castro

### Kleyber Vindas

---



## Profesor del Curso

**Ing. Allan Henry Naranjo Rojas**

---

## Institución Académica

<a href="https://uh.ac.cr/home">
  <img src="https://uh.ac.cr/img/iso.png" alt="Universidad Hispanoamericana" width="40" height="40" style="vertical-align: middle;">
</a> | <a href="https://uh.ac.cr/home">Universidad Hispanoamericana</a>

---

### Tecnologías Utilizadas

<p>
  <img src="https://img.shields.io/badge/Oracle-19c-F80000?style=for-the-badge&logo=oracle&logoColor=white" alt="Oracle 19c">
  <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git">
  <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
</p>

---

## Licencia y Uso

Este proyecto fue desarrollado exclusivamente con fines académicos como parte del curso de **Aplicaciones de Bases de Datos** de la Universidad Hispanoamericana.

Su contenido puede utilizarse como referencia educativa y de aprendizaje, respetando los créditos correspondientes a sus autores.

---

## Autor Principal

**Anthony Emanuel Villalobos Hidalgo**

Estudiante de Ingeniería en Sistemas Informática  
Universidad Hispanoamericana


