-- Base de datos para aplicación financiera FINT
-- Compatible con MySQL/MariaDB

-- Crear base de datos
CREATE DATABASE IF NOT EXISTS acosenar;
USE acosenar;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de datos financieros
CREATE TABLE IF NOT EXISTS financial_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00,
    income DECIMAL(10,2) DEFAULT 0.00,
    expenses DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_data (user_id)
);

-- Tabla de transacciones
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    type ENUM('income', 'expense') NOT NULL,
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Tabla de presupuestos
CREATE TABLE IF NOT EXISTS budgets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    category VARCHAR(100) NOT NULL,
    budget DECIMAL(10,2) NOT NULL,
    spent DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_budget (user_id, category)
);

-- Tabla de sesiones/tokens
CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insertar usuario demo para pruebas
INSERT INTO users (name, email, password) VALUES 
('Administrador', 'admin@ejemplo.com', '4321')
ON DUPLICATE KEY UPDATE password = password;

-- Insertar datos financieros demo
INSERT INTO financial_data (user_id, balance, income, expenses) 
SELECT u.id, 5000.00, 3000.00, 2200.00 
FROM users u WHERE u.email = 'admin@ejemplo.com'
ON DUPLICATE KEY UPDATE 
    balance = VALUES(balance),
    income = VALUES(income),
    expenses = VALUES(expenses);

-- Insertar transacciones demo
INSERT INTO transactions (user_id, description, amount, category, type, date)
SELECT u.id, 
    'Salario mensual', 3000.00, 'Ingresos', 'income', CURDATE()
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 
    'Supermercado', -500.00, 'Alimentos', 'expense', CURDATE()
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 
    'Transporte', -200.00, 'Transporte', 'expense', CURDATE()
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 
    'Servicios', -800.00, 'Servicios', 'expense', CURDATE()
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 
    'Vivienda', -700.00, 'Vivienda', 'expense', CURDATE()
FROM users u WHERE u.email = 'admin@ejemplo.com';

-- Insertar presupuestos demo
INSERT INTO budgets (user_id, category, budget, spent)
SELECT u.id, 'Alimentos', 600.00, 500.00
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 'Transporte', 250.00, 200.00
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 'Vivienda', 800.00, 700.00
FROM users u WHERE u.email = 'admin@ejemplo.com'
UNION ALL
SELECT u.id, 'Servicios', 900.00, 800.00
FROM users u WHERE u.email = 'admin@ejemplo.com';

-- Índices para mejor rendimiento
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date);
CREATE INDEX idx_transactions_user_type ON transactions(user_id, type);
CREATE INDEX idx_budgets_user_category ON budgets(user_id, category);

-- Vista para obtener datos completos del usuario
CREATE VIEW user_financial_summary AS
SELECT 
    u.id,
    u.name,
    u.email,
    fd.balance,
    fd.income,
    fd.expenses,
    (fd.income - fd.expenses) as savings,
    fd.updated_at as last_updated
FROM users u
LEFT JOIN financial_data fd ON u.id = fd.user_id;

-- Vista para resumen de transacciones por mes
CREATE VIEW monthly_transactions_summary AS
SELECT 
    u.id as user_id,
    u.email,
    YEAR(t.date) as year,
    MONTH(t.date) as month,
    SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN t.type = 'expense' THEN ABS(t.amount) ELSE 0 END) as total_expenses,
    SUM(t.amount) as net_amount,
    COUNT(t.id) as transaction_count
FROM users u
JOIN transactions t ON u.id = t.user_id
GROUP BY u.id, u.email, YEAR(t.date), MONTH(t.date)
ORDER BY u.id, year DESC, month DESC;
