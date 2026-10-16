DROP DATABASE IF EXISTS fint_db;
CREATE DATABASE fint_db CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE fint_db;

CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    zona_vivienda VARCHAR(255),
    INDEX idx_correo (correo),
    INDEX idx_activo (activo)
);

CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    tipo ENUM('ingreso', 'gasto') NOT NULL,
    icono VARCHAR(50),
    color VARCHAR(7),
    descripcion TEXT,
    usuario_id INT,
    predeterminada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_tipo (tipo),
    INDEX idx_usuario (usuario_id),
    INDEX idx_predeterminada (predeterminada)
);

CREATE TABLE cuentas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo ENUM('bancaria', 'efectivo', 'tarjeta_credito', 'tarjeta_debito', 'inversion') NOT NULL,
    banco VARCHAR(100),
    saldo_inicial DECIMAL(15,2) DEFAULT 0.00,
    saldo_actual DECIMAL(15,2) DEFAULT 0.00,
    usuario_id INT NOT NULL,
    activa BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_tipo (tipo),
    INDEX idx_activa (activa)
);

CREATE TABLE transacciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    monto DECIMAL(15,2) NOT NULL,
    tipo ENUM('ingreso', 'gasto') NOT NULL,
    categoria_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_transaccion DATE NOT NULL,
    nota TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT,
    FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_tipo (tipo),
    INDEX idx_categoria (categoria_id),
    INDEX idx_cuenta (cuenta_id),
    INDEX idx_fecha (fecha_transaccion)
);

CREATE TABLE presupuestos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria_id INT NOT NULL,
    cuenta_id INT,
    usuario_id INT NOT NULL,
    monto_limite DECIMAL(15,2) NOT NULL,
    periodo ENUM('semanal', 'quincenal', 'mensual', 'anual') NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE CASCADE,
    FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE SET NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_categoria (categoria_id),
    INDEX idx_periodo (periodo),
    INDEX idx_activo (activo),
    INDEX idx_fechas (fecha_inicio, fecha_fin)
);


CREATE TABLE sesiones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NULL DEFAULT NULL,
    activa BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_token (token),
    INDEX idx_expiracion (fecha_expiracion),
    INDEX idx_activa (activa)
);


INSERT INTO usuarios (nombre, correo, contrasena, telefono) VALUES
('Administrador', 'admin', '$2b$10$UbZOwEuGgNEs0UqqkezfGuhxXSdTGKrfpaCJljUGIJOFQuaItbAx6', '5555555555');

INSERT INTO categorias (nombre, tipo, icono, color, descripcion, predeterminada) VALUES
('Salario', 'ingreso', 'work', '#4CAF50', 'Ingresos por trabajo', TRUE),
('Freelance', 'ingreso', 'laptop', '#2196F3', 'Trabajos independientes', TRUE),
('Inversiones', 'ingreso', 'trending_up', '#FF9800', 'Rendimientos de inversiones', TRUE),
('Otros Ingresos', 'ingreso', 'add_circle', '#9C27B0', 'Otros tipos de ingresos', TRUE),
('Alimentos', 'gasto', 'restaurant', '#F44336', 'Comida y bebidas', TRUE),
('Transporte', 'gasto', 'directions_car', '#3F51B5', 'Gastos de transporte', TRUE),
('Vivienda', 'gasto', 'home', '#009688', 'Renta, hipoteca, servicios', TRUE),
('Servicios', 'gasto', 'power', '#FF5722', 'Agua, luz, gas, internet', TRUE),
('Salud', 'gasto', 'local_hospital', '#E91E63', 'Gastos médicos y salud', TRUE),
('Educación', 'gasto', 'school', '#673AB7', 'Cursos, libros, formación', TRUE),
('Entretenimiento', 'gasto', 'movie', '#795548', 'Cine, juegos, hobbies', TRUE),
('Compras', 'gasto', 'shopping_cart', '#607D8B', 'Ropa, electrónicos, etc', TRUE),
('Ahorro', 'gasto', 'savings', '#00BCD4', 'Transferencias a ahorro', TRUE),
('Impuestos', 'gasto', 'receipt', '#FFC107', 'Pagos de impuestos', TRUE),
('Otros Gastos', 'gasto', 'more_horiz', '#9E9E9E', 'Gastos no categorizados', TRUE);

INSERT INTO cuentas (nombre, tipo, banco, saldo_actual, usuario_id) VALUES
('Cuenta Principal', 'bancaria', 'BBVA', 15000.00, 1),
('Efectivo', 'efectivo', NULL, 2000.00, 1),
('Tarjeta de Crédito', 'tarjeta_credito', 'Banorte', 0.00, 1),
('Cuenta de Ahorros', 'bancaria', 'Santander', 8000.00, 1);

INSERT INTO transacciones (descripcion, monto, tipo, categoria_id, cuenta_id, usuario_id, fecha_transaccion, nota) VALUES
('Salario mensual', 25000.00, 'ingreso', 1, 1, 1, '2026-01-15', 'Pago quincenal'),
('Proyecto freelance', 5000.00, 'ingreso', 2, 1, 1, '2026-01-20', 'Diseño web'),
('Supermercado', 2500.00, 'gasto', 5, 1, 1, '2026-01-25', 'Compras semanal'),
('Gasolina', 800.00, 'gasto', 6, 3, 1, '2026-01-26', 'Tanque completo'),
('Renta departamento', 8000.00, 'gasto', 7, 1, 1, '2026-01-01', 'Renta enero'),
('Servicios de internet', 500.00, 'gasto', 8, 1, 1, '2026-01-05', 'Internet fibra óptica'),
('Cine y palomitas', 350.00, 'gasto', 10, 2, 1, '2026-01-27', 'Domingo de cine'),
('Ropa nueva', 1200.00, 'gasto', 11, 3, 1, '2026-01-28', 'Ropa de trabajo'),
('Transferencia a ahorros', 3000.00, 'gasto', 13, 1, 1, '2026-01-30', 'Ahorro mensual');

INSERT INTO presupuestos (nombre, categoria_id, cuenta_id, usuario_id, monto_limite, periodo, fecha_inicio, fecha_fin) VALUES
('Presupuesto Alimentos', 5, 1, 1, 3000.00, 'mensual', '2026-01-01', '2026-01-31'),
('Presupuesto Transporte', 6, 3, 1, 1000.00, 'mensual', '2026-01-01', '2026-01-31'),
('Presupuesto Entretenimiento', 10, 2, 1, 500.00, 'mensual', '2026-01-01', '2026-01-31'),
('Presupuesto Compras', 11, 3, 1, 1500.00, 'mensual', '2026-01-01', '2026-01-31');


SELECT
    'Base de datos FINT creada exitosamente' as mensaje,
    'Usuario: admin / Contraseña: admin' as credenciales,
    'Total tablas creadas: 6' as tablas;
