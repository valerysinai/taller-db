# Base de Datos 
Repositorio de base de datos gestionado con **Liquibase** y **PostgreSQL**.  
Aquí **no se escribe SQL directamente** — todo cambio en la BD se hace mediante archivos XML llamados *changesets*.

---

## Estructura del Proyecto

```
db-repo/
├── .github/
│   └── workflows/
│       └── validate-liquibase.yml        # Robot que valida las migraciones en cada push
├── Docker/
│   └── liquibase/
│       └── Dockerfile                    # Imagen Docker personalizada de Liquibase
├── src/
│   └── main/
│       └── resources/
│           └── db/
│               └── changelog/
│                   ├── master.xml        # Índice principal: define el orden de ejecución
│                   ├── v1/               # Versión 1: creación de tablas base
│                   │   ├── 001-create-usuario.xml
│                   │   ├── 002-create-producto.xml
│                   │   └── 003-create-pedido.xml
│                   ├── v2/               # Versión 2: optimizaciones (índices)
│                   │   └── 001-add-indexes.xml
│                   └── scripts/          # Scripts SQL de referencia
│                       ├── ddl.sql       # Data Definition Language (crear/modificar tablas)
│                       ├── dml.sql       # Data Manipulation Language (insertar/actualizar datos)
│                       ├── dcl.sql       # Data Control Language (permisos y usuarios)
│                       └── rollback.xml  # Ejemplos de reversión de cambios
├── docker-compose.yml                    # Levanta PostgreSQL + Liquibase juntos
├── liquibase.properties                  # Configuración de conexión a PostgreSQL
└── README.md
```

---

## 🧠 ¿Cómo funciona? (Explicado simple)

Imagina que la base de datos es un **edificio en construcción**:

```
Liquibase     = El arquitecto
Archivos XML  = Los planos del edificio
PostgreSQL    = El terreno donde se construye
master.xml    = El índice que dice en qué orden seguir los planos
scripts/      = La biblioteca de referencia (consulta, no construcción)
```

Tú **nunca construyes la pared directamente** (nunca escribes SQL en la BD).  
En cambio, le entregas el plano (el XML) al arquitecto (Liquibase) y él construye todo en orden, llevando un registro exacto de qué ya se construyó.

---

## 🔑 Archivos más importantes

### 1. `master.xml` — El índice principal

Es el punto de entrada de Liquibase. Define en qué orden deben ejecutarse los demás archivos:

```xml
<databaseChangeLog>

    <!-- Primero crea las tablas base (v1) -->
    <include file="src/main/resources/db/changelog/v1/001-create-usuario.xml" />
    <include file="src/main/resources/db/changelog/v1/002-create-producto.xml" />
    <include file="src/main/resources/db/changelog/v1/003-create-pedido.xml" />

    <!-- Luego aplica las optimizaciones (v2) -->
    <include file="src/main/resources/db/changelog/v2/001-add-indexes.xml" />

</databaseChangeLog>
```

> **¿Por qué el orden importa?** No puedes crear la tabla `pedido` antes que `usuario`, porque `pedido` tiene una referencia (llave foránea) a `usuario`. Si el orden fuera incorrecto, daría error.

---

### 2. `v1/001-create-usuario.xml` — Crea la tabla Usuario

```xml
<changeSet id="1" author="taller">
    <createTable tableName="usuario">
        <column name="id" type="BIGINT" autoIncrement="true">
            <constraints primaryKey="true" nullable="false"/>
        </column>
        <column name="nombre" type="VARCHAR(255)">
            <constraints nullable="false"/>
        </column>
        <column name="email" type="VARCHAR(255)">
            <constraints nullable="false" unique="true"/>
        </column>
        <column name="password" type="VARCHAR(255)">
            <constraints nullable="false"/>
        </column>
        <column name="fecha_creacion" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
            <constraints nullable="false"/>
        </column>
    </createTable>
</changeSet>
```

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGINT | Llave primaria, autoincremental |
| `nombre` | VARCHAR(255) | Obligatorio |
| `email` | VARCHAR(255) | Obligatorio y único |
| `password` | VARCHAR(255) | Obligatorio |
| `fecha_creacion` | TIMESTAMP | Se llena automáticamente |

---

### 3. `v1/002-create-producto.xml` — Crea la tabla Producto

```xml
<changeSet id="2" author="taller">
    <createTable tableName="producto">
        <column name="id" type="BIGINT" autoIncrement="true">
            <constraints primaryKey="true" nullable="false"/>
        </column>
        <column name="nombre" type="VARCHAR(255)">
            <constraints nullable="false"/>
        </column>
        <column name="descripcion" type="TEXT"/>
        <column name="precio" type="DECIMAL(10, 2)">
            <constraints nullable="false"/>
        </column>
        <column name="stock" type="INT" defaultValue="0">
            <constraints nullable="false"/>
        </column>
    </createTable>
</changeSet>
```

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGINT | Llave primaria, autoincremental |
| `nombre` | VARCHAR(255) | Obligatorio |
| `descripcion` | TEXT | Texto largo, opcional |
| `precio` | DECIMAL(10,2) | Obligatorio, con decimales |
| `stock` | INT | Por defecto en 0 |

---

### 4. `v1/003-create-pedido.xml` — Crea la tabla Pedido + Llave Foránea

```xml
<changeSet id="3" author="taller">
    <createTable tableName="pedido">
        <column name="id" type="BIGINT" autoIncrement="true">
            <constraints primaryKey="true" nullable="false"/>
        </column>
        <column name="fecha" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
            <constraints nullable="false"/>
        </column>
        <column name="total" type="DECIMAL(10, 2)">
            <constraints nullable="false"/>
        </column>
        <column name="estado" type="VARCHAR(50)">
            <constraints nullable="false"/>
            <!-- Valores: PENDIENTE, PAGADO, ENVIADO, ENTREGADO -->
        </column>
        <column name="usuario_id" type="BIGINT">
            <constraints nullable="false"/>
        </column>
    </createTable>

    <addForeignKeyConstraint
        baseTableName="pedido"
        baseColumnNames="usuario_id"
        constraintName="fk_pedido_usuario"
        referencedTableName="usuario"
        referencedColumnNames="id"/>
</changeSet>
```

**Relación entre tablas:**

```
┌─────────────┐       ┌──────────────┐
│   usuario   │       │    pedido    │
│─────────────│       │──────────────│
│ id (PK) ◄──┼───────┤ usuario_id   │
│ nombre      │       │ fecha        │
│ email       │       │ total        │
│ password    │       │ estado       │
│ fecha_crea  │       │ id (PK)      │
└─────────────┘       └──────────────┘
     1 usuario puede tener muchos pedidos
```

---

### 5. `v2/001-add-indexes.xml` — Índices para búsquedas rápidas

```xml
<changeSet id="4" author="taller">
    <createIndex tableName="pedido" indexName="idx_pedido_usuario_id">
        <column name="usuario_id"/>
    </createIndex>
    <!--
        Un índice es como el índice de un libro:
        Sin él PostgreSQL revisa TODA la tabla fila por fila.
        Con el índice va directo → búsquedas hasta 100x más rápidas.
    -->
</changeSet>
```

---

## 📂 Scripts de Referencia (`scripts/`)

Estos archivos son de **referencia y estudio**. No los ejecuta Liquibase automáticamente.

---

### 📄 `ddl.sql` — Data Definition Language

> **¿Qué es DDL?** Son los comandos que **definen la estructura** de la base de datos. No mueven datos, solo crean, modifican o eliminan tablas y columnas.

```sql
-- ✅ CREATE: Crear una tabla desde cero
CREATE TABLE usuario (
    id            BIGSERIAL PRIMARY KEY,         -- BIGSERIAL = autoincremental
    nombre        VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,  -- UNIQUE = no se repite
    password      VARCHAR(255) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ✅ ALTER: Agregar una columna nueva a una tabla existente
ALTER TABLE usuario ADD COLUMN telefono VARCHAR(20);

-- ✅ DROP: Eliminar una tabla completamente (¡cuidado, borra todo!)
-- DROP TABLE usuario;   ← comentado para evitar accidentes
```

| Comando | ¿Qué hace? |
|---------|-----------|
| `CREATE TABLE` | Crea una tabla nueva |
| `ALTER TABLE` | Modifica una tabla existente |
| `DROP TABLE` | Elimina una tabla y todos sus datos |

---

### 📄 `dml.sql` — Data Manipulation Language

> **¿Qué es DML?** Son los comandos que **manipulan los datos** dentro de las tablas. Insertar, actualizar, eliminar y consultar.

```sql
-- ✅ INSERT: Insertar datos de prueba
INSERT INTO usuario (nombre, email, password) VALUES
    ('Valery García',  'valery@email.com',   '123456'),
    ('Carlos López',   'carlos@email.com',   'abcdef'),
    ('Ana Martínez',   'ana@email.com',       'pass123'),
    ('Pedro Gómez',    'pedro@email.com',     'qwerty'),
    ('Laura Torres',   'laura@email.com',     'laura99');

INSERT INTO producto (nombre, descripcion, precio, stock) VALUES
    ('Laptop Gaming',    'Alto rendimiento',   2500000, 10),
    ('Mouse Inalámbrico','Ergonómico',           45000,  50),
    ('Teclado Mecánico', 'Switches azules',     180000,  30),
    ('Monitor 27"',      '4K HDR',              950000,   8),
    ('Audífonos BT',     'Cancelación de ruido',220000,  25);

INSERT INTO pedido (total, estado, usuario_id) VALUES
    (2500000, 'PENDIENTE',  1),
    (225000,  'PAGADO',     2),
    (1130000, 'ENVIADO',    1),
    (45000,   'ENTREGADO',  3),
    (400000,  'PENDIENTE',  4);

-- ✅ UPDATE: Actualizar un dato existente
UPDATE producto SET stock = stock - 1 WHERE id = 1;

-- ✅ DELETE: Eliminar un registro
DELETE FROM pedido WHERE estado = 'ENTREGADO';

-- ✅ SELECT con JOIN: Consultar pedidos con nombre del usuario
SELECT
    p.id          AS pedido_id,
    u.nombre      AS cliente,
    p.total,
    p.estado,
    p.fecha
FROM pedido p
INNER JOIN usuario u ON p.usuario_id = u.id
ORDER BY p.fecha DESC;
```

| Comando | ¿Qué hace? |
|---------|-----------|
| `INSERT` | Agrega filas nuevas |
| `UPDATE` | Modifica filas existentes |
| `DELETE` | Elimina filas |
| `SELECT` | Consulta y muestra datos |

---

### 📄 `dcl.sql` — Data Control Language

> **¿Qué es DCL?** Son los comandos que **controlan los permisos** de acceso a la base de datos. Quién puede leer, escribir o modificar.

```sql
-- ✅ Crear un usuario de solo lectura (para reportes)
CREATE USER lector_taller WITH PASSWORD 'lector123';

-- ✅ GRANT: Dar permisos de lectura sobre todas las tablas
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lector_taller;
-- SELECT = solo puede consultar, no puede modificar nada

-- ✅ Crear un usuario con permisos completos (para la app)
CREATE USER app_taller WITH PASSWORD 'app123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_taller;
-- Puede hacer todo: leer, crear, editar y eliminar

-- ✅ REVOKE: Quitarle permisos a un usuario
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM app_taller;
-- Ya no puede eliminar registros
```

| Comando | ¿Qué hace? |
|---------|-----------|
| `CREATE USER` | Crea un nuevo usuario en PostgreSQL |
| `GRANT` | Da permisos a un usuario |
| `REVOKE` | Quita permisos a un usuario |

---

### 📄 `rollback.xml` — Revertir cambios con Liquibase

> **¿Qué es Rollback?** Es la capacidad de **deshacer un cambio** aplicado a la base de datos. Como un Ctrl+Z para la BD.

```xml
<!-- Changeset con rollback definido -->
<changeSet id="5" author="taller">

    <!-- Acción: crear tabla de categorías -->
    <createTable tableName="categoria">
        <column name="id" type="BIGINT" autoIncrement="true">
            <constraints primaryKey="true" nullable="false"/>
        </column>
        <column name="nombre" type="VARCHAR(100)">
            <constraints nullable="false"/>
        </column>
    </createTable>

    <!-- Rollback: si se deshace este changeset, elimina la tabla -->
    <rollback>
        <dropTable tableName="categoria"/>
    </rollback>

</changeSet>
```

**¿Cómo ejecutar el rollback?**

```bash
# Revertir el último changeset aplicado
liquibase rollbackCount 1

# Revertir hasta una fecha específica
liquibase rollbackToDate 2026-04-01

# Revertir hasta un tag específico
liquibase rollback v1.0
```

---

### 6. `liquibase.properties` — Configuración de conexión

```properties
# Dirección de la base de datos
url=jdbc:postgresql://localhost:5432/taller_db

# Usuario y contraseña de PostgreSQL
username=postgres
password=postgres

# Archivo que Liquibase debe leer primero
changeLogFile=src/main/resources/db/changelog/master.xml

# Driver que permite a Liquibase hablar con PostgreSQL
driver=org.postgresql.Driver
```

> **⚠️ Nota:** Si tienes PostgreSQL instalado localmente y hay conflicto en el puerto `5432`, usa el puerto `5433` del contenedor Docker.

---

### 7. `docker-compose.yml` — Levanta todo con un solo comando

Levanta PostgreSQL y Liquibase automáticamente:

```yaml
services:
  postgres:                          # Servicio de base de datos
    image: postgres:15-alpine
    container_name: taller_postgres
    ports:
      - "5432:5432"                  # Puerto local:puerto contenedor
    environment:
      POSTGRES_DB: taller_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    healthcheck:                     # Verifica que PostgreSQL esté listo antes de continuar
      test: ["CMD-SHELL", "pg_isready -U postgres -d taller_db"]

  liquibase:                         # Servicio que aplica las migraciones
    build:
      dockerfile: Docker/liquibase/Dockerfile
    container_name: taller_liquibase
    depends_on:
      postgres:
        condition: service_healthy   # Espera que postgres esté sano antes de correr
    environment:
      LIQUIBASE_COMMAND_CHANGELOG_FILE: master.xml
    command: update                  # Ejecuta las migraciones y se apaga (es normal ✅)
```

> **¿Por qué Liquibase se apaga solo?** Porque no es un servidor, es una tarea. Arranca, aplica los cambios y termina. El que debe seguir corriendo siempre es `taller_postgres`.

---

### 8. `validate-liquibase.yml` — El robot protector (GitHub Action)

```yaml
steps:
  - name: Descargar el código
    uses: actions/checkout@v4

  - name: Instalar Java
    uses: actions/setup-java@v4

  - name: Instalar Liquibase

  - name: Validar sintaxis de los XML
    run: liquibase validate

  - name: Ejecutar migraciones en BD temporal
    run: liquibase update
```

---

## ▶️ Cómo correr el proyecto

### Opción A — Con Docker Compose (recomendado)

```bash
# 1. Levantar PostgreSQL y aplicar migraciones
docker-compose up --build

# 2. Verificar las tablas
docker exec -it taller_postgres psql -U postgres -d taller_db -c "\dt"
```

### Opción B — Manual (si hay conflicto de puertos)

```bash
# 1. Levantar PostgreSQL en puerto 5433
docker run --name taller_postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=taller_db \
  -p 5433:5432 \
  -d postgres:15

# 2. Aplicar migraciones con Liquibase local
liquibase \
  --url=jdbc:postgresql://localhost:5433/taller_db \
  --username=postgres \
  --password=postgres \
  --changelog-file=src/main/resources/db/changelog/master.xml \
  update

# 3. Verificar tablas
docker exec -it taller_postgres psql -U postgres -d taller_db -c "\dt"
```

### Resultado esperado

```
 Schema |          Name          | Type  |  Owner
--------+------------------------+-------+----------
 public | databasechangelog      | table | postgres
 public | databasechangeloglock  | table | postgres
 public | pedido                 | table | postgres
 public | producto               | table | postgres
 public | usuario                | table | postgres
```

> `databasechangelog` y `databasechangeloglock` son tablas que crea Liquibase automáticamente para llevar el registro de migraciones. Son normales ✅

---

## 🐘 Conectar a pgAdmin

```
Host:      localhost
Puerto:    5433
Base de datos: taller_db
Usuario:   postgres
Password:  postgres
```

---

## 🔗 Repositorios relacionados

| Repo | Descripción |
|------|-------------|
| `taller-db` | Este repositorio — Base de datos con PostgreSQL + Liquibase |
| `taller-backend` | API REST con Spring Boot |
| `taller-frontend` | Interfaz visual con React + Vite |