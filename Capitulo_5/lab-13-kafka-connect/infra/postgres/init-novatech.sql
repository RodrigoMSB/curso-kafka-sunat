-- NovaTech Logistics - Schema inicial Lab 09

-- Tabla origen (Source connector la captura)
CREATE TABLE IF NOT EXISTS pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    producto VARCHAR(200) NOT NULL,
    cantidad INT NOT NULL,
    monto NUMERIC(10, 2) NOT NULL,
    estado VARCHAR(50) DEFAULT 'pendiente',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla destino (Sink connector la llena)
CREATE TABLE IF NOT EXISTS pedidos_procesados (
    id INT PRIMARY KEY,
    cliente_id INT,
    producto VARCHAR(200),
    cantidad INT,
    monto NUMERIC(10, 2),
    estado VARCHAR(50),
    procesado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Datos seed: 5 pedidos iniciales para que el Source tenga algo que capturar
INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado) VALUES
    (1001, 'Caja de bananos premium', 50, 12500.00, 'pendiente'),
    (1002, 'Pallet de cajas reforzadas', 20, 89000.00, 'pendiente'),
    (1003, 'Etiquetas RFID x1000', 1, 45000.00, 'pendiente'),
    (1004, 'Cinta adhesiva industrial 50m', 100, 7500.00, 'pendiente'),
    (1005, 'Stretch film 500m', 30, 18000.00, 'pendiente');
