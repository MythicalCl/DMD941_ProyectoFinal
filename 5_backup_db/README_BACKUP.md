# Restauración de Base de Datos

Este archivo contiene las instrucciones para restaurar la base de datos del proyecto **DMD941 - Fase 2** a partir del respaldo `.bak`.

## Archivo requerido

El respaldo de la base de datos debe encontrarse en esta carpeta o descargarse desde el enlace compartido por el equipo:

```text
DMD941_Superstore_DW.bak
```

La base de datos restaurada debe llamarse:

```text
DMD941_Superstore_DW
```

---

## Requisitos previos

Antes de iniciar la restauración, cada integrante debe tener instalado:

- SQL Server
- SQL Server Management Studio, SSMS
- Archivo de respaldo `DMD941_Superstore_DW.bak`

---

## Restauración desde SQL Server Management Studio

### 1. Abrir SSMS

Abrir **SQL Server Management Studio** y conectarse al servidor local.

Ejemplos comunes de servidor:

```text
localhost
```

o:

```text
.\SQLEXPRESS
```

El nombre puede variar según la instancia instalada en cada computadora.

---

### 2. Iniciar restauración

En el panel izquierdo de SSMS:

1. Clic derecho sobre:

```text
Databases
```

2. Seleccionar:

```text
Restore Database...
```

---

### 3. Seleccionar el archivo de respaldo

En la ventana de restauración:

1. Seleccionar la opción:

```text
Device
```

2. Presionar el botón de los tres puntos:

```text
...
```

3. Presionar:

```text
Add
```

4. Buscar y seleccionar el archivo:

```text
DMD941_Superstore_DW.bak
```

5. Presionar:

```text
OK
```

---

### 4. Definir el nombre de la base de datos

En el campo **Database**, colocar:

```text
DMD941_Superstore_DW
```

---

### 5. Verificar rutas de archivos

Ir a la sección:

```text
Files
```

Verificar que las rutas de los archivos `.mdf` y `.ldf` sean válidas para la computadora donde se está restaurando.

Si aparece un error relacionado con rutas, cambiar las rutas a una carpeta válida de SQL Server, por ejemplo:

```text
C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\
```

La ruta exacta puede variar según la versión e instancia instalada.

---

### 6. Opciones de restauración

Ir a la sección:

```text
Options
```

Marcar la opción:

```text
Overwrite the existing database (WITH REPLACE)
```

Esta opción solo es necesaria si ya existe una base de datos con el mismo nombre.

---

### 7. Ejecutar restauración

Presionar:

```text
OK
```

Esperar hasta que SSMS muestre el mensaje:

```text
Database restored successfully
```

---

## Validación después de restaurar

Después de restaurar la base de datos, ejecutar las siguientes consultas en SSMS.

### Validar existencia de tablas

```sql
USE DMD941_Superstore_DW;
GO

SELECT name 
FROM sys.tables;
GO
```

Deben aparecer tablas como:

```text
raw_superstore
dim_date
dim_customer
dim_product
dim_location
dim_shipmode
dim_priority
fact_sales
```

---

### Validar conteo de registros

```sql
USE DMD941_Superstore_DW;
GO

SELECT 'raw_superstore' AS tabla, COUNT(*) AS registros FROM dbo.raw_superstore
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dbo.dim_date
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dbo.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dbo.dim_product
UNION ALL
SELECT 'dim_location', COUNT(*) FROM dbo.dim_location
UNION ALL
SELECT 'dim_shipmode', COUNT(*) FROM dbo.dim_shipmode
UNION ALL
SELECT 'dim_priority', COUNT(*) FROM dbo.dim_priority
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dbo.fact_sales;
```

---

## Capturas recomendadas

Para documentar la restauración, tomar capturas de:

1. Ventana **Restore Database** con el archivo `.bak` seleccionado.
2. Mensaje de restauración exitosa.
3. Base `DMD941_Superstore_DW` visible en SSMS.
4. Consulta mostrando las tablas restauradas.
5. Consulta mostrando conteo de registros.

---

## Texto sugerido para el documento

> Para facilitar la colaboración del equipo, se generó un respaldo completo de la base de datos `DMD941_Superstore_DW` en formato `.bak`. Este respaldo permite que los integrantes puedan restaurar el Data Warehouse directamente en SQL Server Management Studio sin ejecutar manualmente todos los scripts de creación, carga y transformación. Después de la restauración, se validó la existencia de las tablas principales y el conteo de registros para confirmar que la base fue restaurada correctamente.

---

## Nota importante

Si al restaurar aparece un error relacionado con las rutas de los archivos `.mdf` o `.ldf`, se debe ir a la pestaña **Files** y cambiar las rutas a una carpeta válida de la instalación local de SQL Server.
