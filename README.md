# Proyecto de Cátedra Fase 2 - DMD941

## Data Warehouse Superstore

Repositorio del proyecto final de la asignatura **Datawarehouse y Minería de Datos - DMD941**.

Este proyecto implementa un proceso de **Data Warehouse** utilizando como fuente el archivo **Superstore DMD941**, aplicando un flujo ETL para cargar los datos en un modelo dimensional tipo **esquema estrella**. Posteriormente, el modelo sirve como base para análisis mediante **KPIs**, **cubo OLAP** y reportes en **Power BI**.

---

## Objetivo del proyecto

Implementar una solución de inteligencia de negocios que permita integrar, transformar y analizar datos de ventas a partir del dataset Superstore, con el propósito de apoyar la toma de decisiones en áreas como ventas, finanzas y logística.

La solución contempla:

- Carga de datos desde archivo Excel/CSV.
- Creación de una tabla RAW o staging.
- Implementación de un Data Warehouse relacional.
- Diseño de un modelo dimensional tipo estrella.
- Desarrollo de proceso ETL en SQL Server.
- Validación de datos cargados.
- Generación de KPIs.
- Implementación de cubo OLAP.
- Creación de reportes interactivos en Power BI.
- Documentación de evidencias y capturas del proceso.

---

## Integrantes

| Integrante | Nombre | Rol |
|---|---|---|
| 1 | Carlos Ernesto Contreras Bonilla CB121033 | Técnico 1 - Base de datos, Data Warehouse y ETL |
| 2 | Alisson Rebeca Ramós Sibrian RS21346  | Técnico 2 - KPIs, Cubo OLAP y Power BI |
| 3 | Marlene Noemy López de Servando LQ221481 | Teórico 1 - Problema, datos y diseño del DW |
| 4 | Kevin Oswaldo Alvarado Rosales AR202118| Teórico 2 - KPIs, herramientas, cronograma, conclusiones y defensa |

---

## Herramientas utilizadas

- SQL Server
- SQL Server Management Studio, SSMS
- Visual Studio 2022
- SQL Server Analysis Services, SSAS
- Microsoft Analysis Services Projects
- Power BI Desktop
- GitHub Desktop
- GitHub
- Microsoft Excel

---

## Estructura del repositorio

```text
DMD941_ProyectoFinal/
│
├── 1_SQL/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_recreate_rawsuperstore.sql
│   ├── 04_BulkInsert.sql
│   ├── 05_data_validation.sql
│   └── otros scripts SQL del proyecto
│
├── 2_Data/
│   └── Archivos de datos utilizados o referencias al archivo fuente
│
├── 3_Capturas/
│   └── Evidencias gráficas del proceso técnico
│
├── 4_Documento/
│   └── Documento de avance o entrega final
│
├── 5_backup_db/
│   ├── DMD941_Superstore_DW.bak
│   └── README_BACKUP.md
│
├── 6_PowerBI/
│   └── Archivo .pbix y evidencias de dashboards
│
├── 7_OLAP/
│   └── Proyecto OLAP / SSAS y documentación del cubo
│
├── .gitignore
├── .gitattributes
└── README.md
```

---

## Modelo de Data Warehouse

El Data Warehouse fue diseñado bajo un **esquema estrella**, donde la tabla de hechos se ubica al centro del modelo y se conecta con las dimensiones de análisis.

### Tabla de hechos

```text
fact_sales
```

La tabla `fact_sales` representa el proceso de negocio principal: **ventas**.

Contiene métricas como:

- `sales`
- `quantity`
- `discount`
- `profit`
- `shipping_cost`
- `delivery_days`
- `profit_margin`

También contiene las claves foráneas hacia las dimensiones.

### Dimensiones

```text
dim_date
dim_customer
dim_product
dim_location
dim_shipmode
dim_priority
```

Estas dimensiones permiten analizar las ventas desde diferentes perspectivas:

- Tiempo
- Cliente
- Producto
- Ubicación
- Modo de envío
- Prioridad de la orden

---

## Granularidad del modelo

La granularidad de la tabla de hechos es:

```text
Una fila por producto dentro de una orden.
```

Esto permite analizar las ventas a nivel de detalle por producto, cliente, fecha, ubicación y modalidad de envío.

---

## Llaves utilizadas

El modelo utiliza **llaves sustitutas** en las dimensiones y en la tabla de hechos.

Ejemplos:

```text
dim_customer.customer_key
dim_product.product_key
dim_date.date_key
dim_location.location_key
dim_shipmode.shipmode_key
dim_priority.priority_key
fact_sales.sales_key
```

La tabla de hechos utiliza estas llaves como claves foráneas para relacionarse con cada dimensión.

---

## Dimensión de fecha

La dimensión `dim_date` se utiliza para analizar la información en función del tiempo.

En el modelo se contemplan dos campos de fecha en la tabla de hechos:

```text
order_date_key
ship_date_key
```

Esto permite analizar ventas por fecha de orden y, de forma opcional, por fecha de envío.

---

## Proceso ETL

El proceso ETL fue implementado mediante scripts SQL y un procedimiento almacenado.

### Flujo general

```text
Excel / CSV
   ↓
raw_superstore
   ↓
Limpieza y transformación
   ↓
Dimensiones
   ↓
fact_sales
```

### 1. Extracción

Se tomó como fuente el archivo **Superstore DMD941**. Para facilitar la carga en SQL Server, el archivo fue exportado a formato CSV UTF-8.

La carga inicial se realizó hacia la tabla:

```text
raw_superstore
```

Esta tabla funciona como capa RAW o staging, conservando los datos originales antes de aplicar transformaciones.

### 2. Transformación

Durante la transformación se aplicaron las siguientes reglas:

- Limpieza de espacios en blanco.
- Conversión de fechas.
- Conversión de campos numéricos.
- Estandarización de textos.
- Reemplazo de códigos postales vacíos por `SIN_CODIGO`.
- Deduplicación de clientes mediante `ROW_NUMBER()`.
- Deduplicación de productos mediante `ROW_NUMBER()`.
- Generación de claves sustitutas.
- Cálculo de `delivery_days`.
- Cálculo de `profit_margin`.

### 3. Carga

La carga se realizó en el siguiente orden:

1. `dim_date`
2. `dim_customer`
3. `dim_product`
4. `dim_location`
5. `dim_shipmode`
6. `dim_priority`
7. `fact_sales`

Este orden permite respetar la integridad referencial, cargando primero las dimensiones y luego la tabla de hechos.

---

## Scripts SQL

Los scripts principales se encuentran en la carpeta:

```text
1_SQL/
```

Orden recomendado de ejecución:

```text
01_create_database.sql
02_create_tables.sql
03_recreate_rawsuperstore.sql
04_BulkInsert.sql
05_data_validation.sql
```

> Nota: si la base de datos se restaura desde el archivo `.bak`, no es necesario ejecutar todos los scripts desde cero.

---

## Restauración de base de datos

El respaldo de base de datos se encuentra en:

```text
5_backup_db/
```

Archivo esperado:

```text
DMD941_Superstore_DW.bak
```

Para restaurar la base de datos, revisar el archivo:

```text
5_backup_db/README_BACKUP.md
```

Ese archivo contiene instrucciones paso a paso para restaurar la base desde SQL Server Management Studio.

---

## Validaciones realizadas

Después de ejecutar el ETL se realizaron validaciones para confirmar que el Data Warehouse fue cargado correctamente.

### Validación de conteos

Se validó la cantidad de registros en:

- `raw_superstore`
- `dim_date`
- `dim_customer`
- `dim_product`
- `dim_location`
- `dim_shipmode`
- `dim_priority`
- `fact_sales`

### Validación de claves foráneas

Se verificó que la tabla `fact_sales` no tuviera claves foráneas nulas en:

- `customer_key`
- `product_key`
- `order_date_key`
- `ship_date_key`
- `location_key`
- `shipmode_key`
- `priority_key`

### Validación de integración

Se ejecutaron consultas con `JOIN` entre `fact_sales` y sus dimensiones para confirmar que el modelo estrella funciona correctamente.

---

## KPIs propuestos

Los KPIs se construyen a partir de la tabla de hechos y sus dimensiones.

- Ventas Totales (Total Sales): representa el monto total de ventas realizadas.
- Ganancia Total (Total Profit): permite evaluar la rentabilidad del negocio.
- Cantidad Vendida (Quantity): muestra el volumen de productos vendidos.
- Ticket Promedio (Average Ticket): indica el valor promedio por orden.
- Margen de Ganancia (%): mide el rendimiento financiero en términos porcentuales.

Además, se realizaron análisis más detallados utilizando dimensiones:

Ventas por mes y año, para identificar tendencias en el tiempo.
Ventas por región, para comparar el desempeño geográfico.
Ventas por categoría, para identificar los productos más vendidos.
Top clientes, para reconocer los clientes con mayor contribución.


---

## Cubo OLAP

La implementación OLAP se trabaja en la carpeta:

```text
7_OLAP/
```

El objetivo del cubo OLAP es permitir el análisis multidimensional de las ventas a partir del Data Warehouse.

### Cubo propuesto

```text
Cubo Superstore Sales
```

### Medidas del cubo

- Sales
- Quantity
- Profit
- Discount
- Shipping Cost
- Delivery Days
- Profit Margin

### Dimensiones del cubo

- Dim Date
- Dim Customer
- Dim Product
- Dim Location
- Dim Shipmode
- Dim Priority

### Jerarquías propuestas

#### Dim Date

```text
Year → Quarter → Month → Date
```

#### Dim Product

```text
Category → Subcategory → Product
```

#### Dim Location

```text
Market → Region → Country → State → City
```

---

## Power BI

La carpeta de Power BI es:

```text
6_PowerBI/
```

En Power BI se utilizará la base `DMD941_Superstore_DW` como origen de datos para crear reportes interactivos.

### Reportes recomendados

#### Dashboard ejecutivo

- Ventas totales
- Utilidad total
- Margen de utilidad
- Cantidad vendida
- Costo de envío

#### Dashboard de ventas

- Ventas por año y mes
- Ventas por región
- Ventas por categoría
- Top productos
- Top clientes

#### Dashboard financiero

- Utilidad por categoría
- Margen por región
- Productos con pérdida
- Costo de envío vs utilidad

#### Dashboard logístico

- Días promedio de entrega
- Costo de envío por modo de envío
- Ventas por prioridad de orden

---

## Evidencias

Las capturas del proceso se encuentran en:

```text
3_Capturas/
```

Evidencias recomendadas:

- Base de datos creada.
- Tabla RAW cargada.
- Ejecución del `BULK INSERT`.
- Procedimiento ETL creado.
- ETL ejecutado correctamente.
- Conteo de registros.
- Validación de claves foráneas.
- Consulta integrada entre hechos y dimensiones.
- Diagrama físico del Data Warehouse.
- Creación del proyecto OLAP.
- Data Source de SSAS.
- Data Source View.
- Dimensiones del cubo.
- Procesamiento del cubo.
- Dashboard en Power BI.

---

## Instrucciones para ejecutar desde scripts

Si no se utiliza el respaldo `.bak`, seguir este flujo:

1. Abrir SQL Server Management Studio.
2. Ejecutar `01_create_database.sql`.
3. Ejecutar `02_create_tables.sql`.
4. Exportar el archivo Excel a CSV UTF-8.
5. Ajustar la ruta del archivo CSV en `04_BulkInsert.sql`.
6. Ejecutar la carga hacia `raw_superstore`.
7. Ejecutar el procedimiento ETL.
8. Ejecutar las consultas de validación.
9. Revisar que las tablas dimensionales y `fact_sales` tengan registros.

---

## Instrucciones para restaurar desde backup

1. Abrir SQL Server Management Studio.
2. Clic derecho sobre `Databases`.
3. Seleccionar `Restore Database`.
4. Elegir la opción `Device`.
5. Seleccionar el archivo `DMD941_Superstore_DW.bak`.
6. Restaurar la base con el nombre:

```text
DMD941_Superstore_DW
```

7. Validar las tablas y conteos con las consultas incluidas en `README_BACKUP.md`.

---

## Estado del proyecto

| Componente | Estado |
|---|---|
| Creación de base de datos | Completado |
| Tabla RAW | Completado |
| Carga CSV | Completado |
| Modelo dimensional | Completado |
| Proceso ETL | Completado |
| Validaciones SQL | Completado |
| Backup de base de datos | Completado |
| Cubo OLAP | Completado |
| Power BI | Completado |
| Documento final | Completado |

---

## Observaciones técnicas

Durante la implementación se identificaron aspectos importantes:

- El archivo CSV debía cargarse usando formato CSV y comillas como delimitador de texto.
- La tabla RAW se definió con tipos `NVARCHAR(MAX)` para evitar conversiones prematuras.
- Las conversiones de tipos se realizaron dentro del ETL.
- Se aplicó deduplicación en dimensiones para evitar errores por claves de negocio repetidas.
- Se conservaron los datos originales en RAW para mantener trazabilidad.

---

## Conclusión

Este repositorio documenta la implementación de un Data Warehouse basado en el dataset Superstore.

La solución permite pasar de un archivo plano a un modelo dimensional consultable, validado y preparado para análisis mediante KPIs, cubo OLAP y reportes en Power BI.
