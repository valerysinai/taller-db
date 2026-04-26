# 🗄️ Base de Datos — Taller Fullstack

Repositorio de base de datos gestionado con **Liquibase** y **PostgreSQL**.  
Aquí **no se escribe SQL directamente** — todo cambio en la BD se hace mediante archivos XML llamados *changesets*.

---

## 📁 Estructura del Proyecto

```
db-repo/
├── .github/
│   └── workflows/
│       └── validate-liquibase.yml        # Robot que valida que nadie suba SQL directo
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
│                   └── v2/               # Versión 2: optimizaciones (índices)
│                       └── 001-add-indexes.xml
├── liquibase.properties                  # Configuración de conexión a PostgreSQL
└── README.md
```

---

## 🧠 ¿Cómo funciona? (Explicado simple)

Imagina que la base de datos es un **edificio en construcción**:

```
Liquibase = El arquitecto
Archivos XML = Los planos del edificio
PostgreSQL = El terreno donde se construye
master.xml = El índice que dice en qué orden seguir los planos
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
<changeSet id="1" author="taller">   <!-- id único + quién hizo el cambio -->
    <createTable tableName="usuario">

        <column name="id" type="BIGINT" autoIncrement="true">
            <constraints primaryKey="true" nullable="false"/>
            <!-- primaryKey = es la llave principal, autoIncrement = se genera solo: 1, 2, 3... -->
        </column>

        <column name="nombre" type="VARCHAR(255)">
            <constraints nullable="false"/>   <!-- obligatorio, no puede estar vacío -->
        </column>

        <column name="email" type="VARCHAR(255)">
            <constraints nullable="false" unique="true"/>
            <!-- unique = no pueden existir dos usuarios con el mismo email -->
        </column>

        <column name="password" type="VARCHAR(255)">
            <constraints nullable="false"/>
        </column>

        <column name="fecha_creacion" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP">
            <!-- CURRENT_TIMESTAMP = pone automáticamente la fecha y hora actual al crear -->
            <constraints nullable="false"/>
        </column>

    </createTable>
</changeSet>
```

**Resultado en PostgreSQL:**

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
        <!-- TEXT = texto largo sin límite de caracteres -->

        <column name="precio" type="DECIMAL(10, 2)">
            <!-- DECIMAL(10,2) = número con hasta 10 dígitos y 2 decimales, ej: 99999999.99 -->
            <constraints nullable="false"/>
        </column>

        <column name="stock" type="INT" defaultValue="0">
            <!-- defaultValue="0" = si no se especifica, el stock empieza en 0 -->
            <constraints nullable="false"/>
        </column>

    </createTable>
</changeSet>
```

**Resultado en PostgreSQL:**

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGINT | Llave primaria, autoincremental |
| `nombre` | VARCHAR(255) | Obligatorio |
| `descripcion` | TEXT | Texto largo, opcional |
| `precio` | DECIMAL(10,2) | Obligatorio, con decimales |
| `stock` | INT | Por defecto en 0 |

---

### 4. `v1/003-create-pedido.xml` — Crea la tabla Pedido + Llave Foránea

Este es el más importante porque tiene una **relación con la tabla Usuario**:

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
            <!-- Valores posibles: PENDIENTE, PAGADO, ENVIADO, ENTREGADO -->
            <constraints nullable="false"/>
        </column>

        <column name="usuario_id" type="BIGINT">
            <!-- Esta columna conecta el pedido con un usuario específico -->
            <constraints nullable="false"/>
        </column>

    </createTable>

    <!-- 🔗 Llave Foránea: conecta pedido con usuario -->
    <addForeignKeyConstraint
        baseTableName="pedido"
        baseColumnNames="usuario_id"
        constraintName="fk_pedido_usuario"
        referencedTableName="usuario"
        referencedColumnNames="id"/>
    <!--
        Esto dice: el usuario_id de la tabla pedido
        DEBE existir en la columna id de la tabla usuario.
        Evita pedidos "huérfanos" (sin usuario válido).
    -->

</changeSet>
```

> **¿Qué es una llave foránea?** Es una regla de integridad. Si el usuario con id=5 no existe, no puedes crear un pedido con usuario_id=5. Esto protege los datos de inconsistencias.

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

### 5. `v2/001-add-indexes.xml` — Agrega índices para búsquedas rápidas

```xml
<changeSet id="4" author="taller">
    <createIndex tableName="pedido" indexName="idx_pedido_usuario_id">
        <column name="usuario_id"/>
    </createIndex>
    <!--
        Un índice es como el índice de un libro:
        Sin él, para buscar todos los pedidos del usuario 5,
        PostgreSQL revisa TODA la tabla fila por fila.
        Con el índice, va directo a los pedidos de ese usuario.
        Resultado: búsquedas hasta 100x más rápidas.
    -->
</changeSet>
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

> **⚠️ Nota:** Si tienes PostgreSQL instalado localmente y hay conflicto en el puerto 5432, cambia el puerto a `5433` (el del contenedor Docker).

---

### 7. `validate-liquibase.yml` — El robot protector (GitHub Action)

Se ejecuta automáticamente en cada `push` o `pull request` a `main`. Hace 5 cosas:

```yaml
steps:
  # 1. Descarga el código del repositorio
  - name: Descargar el código
    uses: actions/checkout@v4

  # 2. Instala Java (Liquibase lo necesita para correr)
  - name: Instalar Java
    uses: actions/setup-java@v4

  # 3. Instala Liquibase
  - name: Instalar Liquibase

  # 4. ❌ FALLA si alguien sube un archivo .sql directo
  - name: Prohibir archivos SQL directos
    run: |
      if find src/main/resources/db/changelog -name "*.sql" | grep -q .; then
        echo "ERROR: ¡No uses scripts SQL directos! Usa formato XML de Liquibase."
        exit 1   # exit 1 = hace fallar el pipeline con ❌ rojo
      fi

  # 5. Verifica que los XML están bien escritos
  - name: Validar sintaxis
    run: liquibase validate

  # 6. Aplica los cambios en una BD temporal de prueba
  - name: Ejecutar migraciones
    run: liquibase update
```

---

## ▶️ Cómo correr el proyecto

### Requisitos previos
- Docker instalado
- Liquibase instalado

### Pasos

```bash
# 1. Levantar PostgreSQL con Docker
docker run --name pg-taller \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=taller_db \
  -p 5433:5432 \
  -d postgres:15

# 2. Esperar que inicie
# (verifica con: docker exec pg-taller pg_isready -U postgres)

# 3. Aplicar las migraciones
liquibase \
  --url=jdbc:postgresql://localhost:5433/taller_db \
  --username=postgres \
  --password=postgres \
  --changelog-file=src/main/resources/db/changelog/master.xml \
  update

# 4. Verificar que las tablas fueron creadas
docker exec -it pg-taller psql -U postgres -d taller_db -c "\dt"
```

### Resultado esperado

```
          List of relations
 Schema |   Name    | Type  |  Owner
--------+-----------+-------+----------
 public | pedido    | table | postgres
 public | producto  | table | postgres
 public | usuario   | table | postgres
 public | databasechangelog      | table | postgres
 public | databasechangeloglock  | table | postgres
```

> Las tablas `databasechangelog` y `databasechangeloglock` son creadas automáticamente por Liquibase para llevar el registro de qué migraciones ya se ejecutaron. Son normales ✅

---

## 🛡️ Regla de oro de este repositorio

```
❌ PROHIBIDO → subir archivos .sql directos
✅ PERMITIDO → solo archivos .xml de Liquibase
```

Si alguien intenta subir un `.sql`, el GitHub Action falla automáticamente con ❌ y no permite hacer merge.

---

## 🔗 Repositorios relacionados

| Repo | Descripción |
|------|-------------|
| `taller-db` | Este repositorio — Base de datos con PostgreSQL + Liquibase |
| `taller-backend` | API REST con Spring Boot |
| `taller-frontend` | Interfaz visual con React + Vite |
