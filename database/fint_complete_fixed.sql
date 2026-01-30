-- =====================================================
-- BASE DE DATOS COMPLETA PARA FINT (VERSIÓN CORREGIDA)
-- =====================================================
-- Creado: 29/01/2026
-- Versión: 1.1 (Corregido para HeidiSQL)
-- Descripción: Sistema financiero personal con usuarios, transacciones, presupuestos y categorías

-- Eliminar bases de datos existentes si es necesario
DROP DATABASE IF EXISTS fint_db;
CREATE DATABASE fint_db CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE fint_db;

-- =====================================================
-- TABLA DE USUARIOS
-- =====================================================
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    INDEX idx_correo (correo),
    INDEX idx_activo (activo)
);

-- =====================================================
-- TABLA DE CATEGORÍAS
-- =====================================================
CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    tipo ENUM('ingreso', 'gasto') NOT NULL,
    icono VARCHAR(50),
    color VARCHAR(7), -- Código de color hex
    descripcion TEXT,
    usuario_id INT,
    predeterminada BOOLEAN DEFAULT FALSE, -- Categorías del sistema
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_tipo (tipo),
    INDEX idx_usuario (usuario_id),
    INDEX idx_predeterminada (predeterminada)
);

-- =====================================================
-- TABLA DE CUENTAS/BANCOS
-- =====================================================
CREATE TABLE cuentas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo ENUM('bancaria', 'efectivo', 'tarjeta_credito', 'tarjeta_debito', 'inversion') NOT NULL,
    banco VARCHAR(100),
    numero_cuenta VARCHAR(50),
    saldo_inicial DECIMAL(15,2) DEFAULT 0.00,
    saldo_actual DECIMAL(15,2) DEFAULT 0.00,
    moneda VARCHAR(3) DEFAULT 'MXN',
    usuario_id INT NOT NULL,
    activa BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_tipo (tipo),
    INDEX idx_activa (activa)
);

-- =====================================================
-- TABLA DE TRANSACCIONES
-- =====================================================
CREATE TABLE transacciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    monto DECIMAL(15,2) NOT NULL,
    tipo ENUM('ingreso', 'gasto') NOT NULL,
    categoria_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_transaccion DATE NOT NULL,
    hora_transaccion TIME DEFAULT CURRENT_TIME,
    nota TEXT,
    etiquetas VARCHAR(255),
    recurrente BOOLEAN DEFAULT FALSE,
    frecuencia_recurrencia ENUM('diaria', 'semanal', 'quincenal', 'mensual', 'anual') NULL,
    fecha_fin_recurrencia DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT,
    FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_tipo (tipo),
    INDEX idx_categoria (categoria_id),
    INDEX idx_cuenta (cuenta_id),
    INDEX idx_fecha (fecha_transaccion),
    INDEX idx_recurrente (recurrente)
);

-- =====================================================
-- TABLA DE PRESUPUESTOS
-- =====================================================
CREATE TABLE presupuestos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria_id INT NOT NULL,
    cuenta_id INT,
    usuario_id INT NOT NULL,
    monto_limite DECIMAL(15,2) NOT NULL,
    monto_actual DECIMAL(15,2) DEFAULT 0.00,
    periodo ENUM('semanal', 'quincenal', 'mensual', 'anual') NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    alerta_porcentaje DECIMAL(5,2) DEFAULT 80.00, -- Alerta al 80%
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

-- =====================================================
-- TABLA DE METAS DE AHORRO
-- =====================================================
CREATE TABLE metas_ahorro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    monto_objetivo DECIMAL(15,2) NOT NULL,
    monto_actual DECIMAL(15,2) DEFAULT 0.00,
    cuenta_destino_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_objetivo DATE,
    prioridad ENUM('baja', 'media', 'alta') DEFAULT 'media',
    automatico BOOLEAN DEFAULT FALSE,
    monto_automatico DECIMAL(15,2) DEFAULT 0.00,
    frecuencia_automatico ENUM('semanal', 'quincenal', 'mensual') DEFAULT 'mensual',
    activa BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_completado TIMESTAMP NULL,
    FOREIGN KEY (cuenta_destino_id) REFERENCES cuentas(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_cuenta (cuenta_destino_id),
    INDEX idx_activa (activa),
    INDEX idx_prioridad (prioridad)
);

-- =====================================================
-- TABLA DE SESIONES (para autenticación) - CORREGIDA
-- =====================================================
CREATE TABLE sesiones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    dispositivo VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NULL DEFAULT NULL, -- CORREGIDO: Permitir NULL y valor por defecto
    activa BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario (usuario_id),
    INDEX idx_token (token),
    INDEX idx_expiracion (fecha_expiracion),
    INDEX idx_activa (activa)
);

-- =====================================================
-- TABLA DE CONFIGURACIÓN DE USUARIO
-- =====================================================
CREATE TABLE configuracion_usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE,
    moneda_preferida VARCHAR(3) DEFAULT 'MXN',
    idioma VARCHAR(10) DEFAULT 'es',
    tema VARCHAR(20) DEFAULT 'auto', -- claro, oscuro, auto
    formato_fecha VARCHAR(20) DEFAULT 'DD/MM/YYYY',
    notificaciones_email BOOLEAN DEFAULT TRUE,
    notificaciones_push BOOLEAN DEFAULT TRUE,
    alertas_presupuesto BOOLEAN DEFAULT TRUE,
    reporte_semanal BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================
-- INSERTAR DATOS DE EJEMPLO
-- =====================================================

-- Usuario admin
INSERT INTO usuarios (nombre, correo, contrasena, telefono) VALUES 
('Administrador', 'admin', 'admin', '5555555555');

-- Configuración del usuario admin
INSERT INTO configuracion_usuario (usuario_id) VALUES (1);

-- Categorías predeterminadas del sistema
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

-- Cuentas de ejemplo para el usuario admin
INSERT INTO cuentas (nombre, tipo, banco, saldo_actual, usuario_id) VALUES
('Cuenta Principal', 'bancaria', 'BBVA', 15000.00, 1),
('Efectivo', 'efectivo', NULL, 2000.00, 1),
('Tarjeta de Crédito', 'tarjeta_credito', 'Banorte', 0.00, 1),
('Cuenta de Ahorros', 'bancaria', 'Santander', 8000.00, 1);

-- Transacciones de ejemplo
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

-- Presupuestos de ejemplo
INSERT INTO presupuestos (nombre, categoria_id, cuenta_id, usuario_id, monto_limite, periodo, fecha_inicio, fecha_fin) VALUES
('Presupuesto Alimentos', 5, 1, 1, 3000.00, 'mensual', '2026-01-01', '2026-01-31'),
('Presupuesto Transporte', 6, 3, 1, 1000.00, 'mensual', '2026-01-01', '2026-01-31'),
('Presupuesto Entretenimiento', 10, 2, 1, 500.00, 'mensual', '2026-01-01', '2026-01-31'),
('Presupuesto Compras', 11, 3, 1, 1500.00, 'mensual', '2026-01-01', '2026-01-31');

-- Metas de ahorro de ejemplo
INSERT INTO metas_ahorro (nombre, descripcion, monto_objetivo, cuenta_destino_id, usuario_id, fecha_objetivo, prioridad) VALUES
('Fondo de emergencia', 'Ahorrar para emergencias', 50000.00, 4, 1, '2026-12-31', 'alta'),
('Vacaciones 2026', 'Ahorro para vacaciones familiares', 30000.00, 4, 1, '2026-07-01', 'media'),
('Nuevo laptop', 'Comprar laptop para trabajo', 25000.00, 4, 1, '2026-06-30', 'baja');

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de resumen financiero del usuario
CREATE VIEW resumen_financiero AS
SELECT 
    u.id as usuario_id,
    u.nombre,
    u.correo,
    COALESCE(ingresos.total_ingresos, 0) as total_ingresos,
    COALESCE(gastos.total_gastos, 0) as total_gastos,
    COALESCE(ingresos.total_ingresos, 0) - COALESCE(gastos.total_gastos, 0) as balance,
    COALESCE(cuentas.total_cuentas, 0) as total_en_cuentas
FROM usuarios u
LEFT JOIN (
    SELECT usuario_id, SUM(monto) as total_ingresos
    FROM transacciones 
    WHERE tipo = 'ingreso'
    GROUP BY usuario_id
) ingresos ON u.id = ingresos.usuario_id
LEFT JOIN (
    SELECT usuario_id, SUM(monto) as total_gastos
    FROM transacciones 
    WHERE tipo = 'gasto'
    GROUP BY usuario_id
) gastos ON u.id = gastos.usuario_id
LEFT JOIN (
    SELECT usuario_id, SUM(saldo_actual) as total_cuentas
    FROM cuentas
    WHERE activa = TRUE
    GROUP BY usuario_id
) cuentas ON u.id = cuentas.usuario_id;

-- Vista de últimas transacciones
CREATE VIEW ultimas_transacciones AS
SELECT 
    t.id,
    t.descripcion,
    t.monto,
    t.tipo,
    c.nombre as categoria,
    cu.nombre as cuenta,
    t.fecha_transaccion,
    t.nota,
    u.nombre as usuario
FROM transacciones t
JOIN categorias c ON t.categoria_id = c.id
JOIN cuentas cu ON t.cuenta_id = cu.id
JOIN usuarios u ON t.usuario_id = u.id
ORDER BY t.fecha_transaccion DESC, t.created_at DESC;

-- Vista de progreso de presupuestos
CREATE VIEW progreso_presupuestos AS
SELECT 
    p.id,
    p.nombre,
    cat.nombre as categoria,
    p.monto_limite,
    p.monto_actual,
    ROUND((p.monto_actual / p.monto_limite) * 100, 2) as porcentaje_usado,
    p.fecha_inicio,
    p.fecha_fin,
    p.activo,
    u.nombre as usuario
FROM presupuestos p
JOIN categorias cat ON p.categoria_id = cat.id
JOIN usuarios u ON p.usuario_id = u.id;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS ÚTILES
-- =====================================================

DELIMITER //

-- Procedimiento para actualizar saldo de cuenta
CREATE PROCEDURE actualizar_saldo_cuenta(
    IN p_cuenta_id INT,
    IN p_monto DECIMAL(15,2),
    IN p_tipo VARCHAR(10)
)
BEGIN
    IF p_tipo = 'ingreso' THEN
        UPDATE cuentas 
        SET saldo_actual = saldo_actual + p_monto 
        WHERE id = p_cuenta_id;
    ELSEIF p_tipo = 'gasto' THEN
        UPDATE cuentas 
        SET saldo_actual = saldo_actual - p_monto 
        WHERE id = p_cuenta_id;
    END IF;
END //

-- Procedimiento para registrar transacción completa
CREATE PROCEDURE registrar_transaccion(
    IN p_descripcion VARCHAR(255),
    IN p_monto DECIMAL(15,2),
    IN p_tipo VARCHAR(10),
    IN p_categoria_id INT,
    IN p_cuenta_id INT,
    IN p_usuario_id INT,
    IN p_fecha DATE,
    IN p_nota TEXT
)
BEGIN
    DECLARE v_id INT;
    
    -- Insertar transacción
    INSERT INTO transacciones (descripcion, monto, tipo, categoria_id, cuenta_id, usuario_id, fecha_transaccion, nota)
    VALUES (p_descripcion, p_monto, p_tipo, p_categoria_id, p_cuenta_id, p_usuario_id, p_fecha, p_nota);
    
    SET v_id = LAST_INSERT_ID();
    
    -- Actualizar saldo de cuenta
    CALL actualizar_saldo_cuenta(p_cuenta_id, p_monto, p_tipo);
    
    -- Actualizar presupuesto si existe
    UPDATE presupuestos 
    SET monto_actual = monto_actual + p_monto 
    WHERE categoria_id = p_categoria_id 
    AND usuario_id = p_usuario_id 
    AND activo = TRUE 
    AND p_fecha BETWEEN fecha_inicio AND fecha_fin;
    
    SELECT v_id as transaccion_id;
END //

-- Procedimiento para obtener resumen mensual
CREATE PROCEDURE resumen_mensual(
    IN p_usuario_id INT,
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    SELECT 
        COALESCE(SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END), 0) as ingresos,
        COALESCE(SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END), 0) as gastos,
        COALESCE(SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END), 0) as balance,
        COUNT(*) as total_transacciones
    FROM transacciones 
    WHERE usuario_id = p_usuario_id 
    AND MONTH(fecha_transaccion) = p_mes 
    AND YEAR(fecha_transaccion) = p_anio;
END //

DELIMITER ;

-- =====================================================
-- DISPARADORES (TRIGGERS)
-- =====================================================

DELIMITER //

-- Trigger para actualizar presupuesto automáticamente
CREATE TRIGGER actualizar_presupuesto_despues_transaccion
AFTER INSERT ON transacciones
FOR EACH ROW
BEGIN
    IF NEW.tipo = 'gasto' THEN
        UPDATE presupuestos 
        SET monto_actual = monto_actual + NEW.monto 
        WHERE categoria_id = NEW.categoria_id 
        AND usuario_id = NEW.usuario_id 
        AND activo = TRUE 
        AND NEW.fecha_transaccion BETWEEN fecha_inicio AND fecha_fin;
    END IF;
END //

-- Trigger para actualizar meta de ahorro
CREATE TRIGGER actualizar_meta_ahorro_despues_transaccion
AFTER INSERT ON transacciones
FOR EACH ROW
BEGIN
    IF NEW.tipo = 'gasto' THEN
        -- Si es una transacción de ahorro, actualizar la meta correspondiente
        UPDATE metas_ahorro 
        SET monto_actual = monto_actual + NEW.monto 
        WHERE cuenta_destino_id = NEW.cuenta_id 
        AND usuario_id = NEW.usuario_id 
        AND activa = TRUE 
        AND monto_actual < monto_objetivo;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- FINALIZACIÓN
-- =====================================================

-- Mostrar mensaje de éxito
SELECT 
    'Base de datos FINT creada exitosamente (Versión corregida)' as mensaje,
    'Usuario: admin / Contraseña: admin' as credenciales,
    'Total tablas creadas: 11' as tablas,
    'Total vistas creadas: 3' as vistas,
    'Total procedimientos: 3' as procedimientos,
    'Total triggers: 2' as triggers;
