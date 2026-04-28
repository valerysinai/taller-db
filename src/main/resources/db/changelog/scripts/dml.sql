-- 1. INSERT: Agregar nuevos registros
-- Usuarios
INSERT INTO usuario (nombre, email, password) VALUES 
('Juan Perez', 'juan@ejemplo.com', 'pass123'),
('Maria Gomez', 'maria@ejemplo.com', 'pass456'),
('Carlos Ruiz', 'carlos@ejemplo.com', 'pass789'),
('Ana Diaz', 'ana@ejemplo.com', 'pass111'),
('Luis Silva', 'luis@ejemplo.com', 'pass222');

-- Productos
INSERT INTO producto (nombre, descripcion, precio, stock) VALUES 
('Laptop', 'Laptop de 15 pulgadas', 1200.50, 10),
('Mouse', 'Mouse inalámbrico', 25.00, 50),
('Teclado', 'Teclado mecánico', 80.00, 30),
('Monitor', 'Monitor 4K', 300.00, 15),
('Auriculares', 'Auriculares con cancelación de ruido', 150.00, 20);

-- Pedidos (asumiendo IDs del 1 al 5 para usuarios)
INSERT INTO pedido (total, estado, usuario_id) VALUES 
(1225.50, 'COMPLETADO', 1),
(80.00, 'PENDIENTE', 2),
(450.00, 'ENVIADO', 3),
(300.00, 'COMPLETADO', 4),
(150.00, 'PENDIENTE', 5);

-- 2. UPDATE: Modificar registros existentes
-- Actualizar el stock del producto con ID 1
UPDATE producto SET stock = 8 WHERE id = 1;

-- 3. DELETE: Eliminar registros
-- Eliminar el pedido con ID 5
DELETE FROM pedido WHERE id = 5;

-- 4. SELECT con JOIN: Consultar datos de múltiples tablas
-- Obtener los nombres de los usuarios y el total de sus pedidos
SELECT u.nombre, p.id AS numero_pedido, p.total, p.estado
FROM usuario u
JOIN pedido p ON u.id = p.usuario_id;
