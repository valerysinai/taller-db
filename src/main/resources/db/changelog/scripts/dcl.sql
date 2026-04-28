
-- 1. CREATE USER: Crear un nuevo usuario en la base de datos (sintaxis general / PostgreSQL)
CREATE USER analista_datos WITH PASSWORD 'secreta123';

-- 2. GRANT: Otorgar permisos
-- Dar permiso de conexión a la base de datos (asumiendo que se llama 'mi_basedatos')
GRANT CONNECT ON DATABASE mi_basedatos TO analista_datos;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista_datos;

GRANT INSERT, UPDATE, DELETE ON pedido TO analista_datos;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO analista_datos;

-- 3. REVOKE: Quitar permisos
REVOKE DELETE ON pedido FROM analista_datos;
REVOKE INSERT, UPDATE, DELETE ON pedido FROM analista_datos;
