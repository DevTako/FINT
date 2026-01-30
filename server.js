const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Configuración MySQL
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'fint_db'
};

// Conexión a la base de datos
let pool;
async function initDB() {
    try {
        pool = mysql.createPool(dbConfig);
        console.log('✅ Conectado a MySQL');
    } catch (error) {
        console.error('❌ Error conectando a MySQL:', error);
    }
}

// Login
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Buscar usuario en la tabla usuarios con campos "correo" y "contrasena"
        const [rows] = await pool.execute(
            'SELECT id, nombre, correo FROM usuarios WHERE correo = ? AND contrasena = ?',
            [email, password]
        );
        
        if (rows.length > 0) {
            const user = rows[0];
            const token = Math.random().toString(36).substring(2);
            
            // Guardar token en sesiones (expira en 24 horas)
            await pool.execute(
                'INSERT INTO sesiones (usuario_id, token, fecha_expiracion) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))',
                [user.id, token]
            );
            
            res.json({
                success: true,
                data: { 
                    user: { 
                        id: user.id, 
                        nombre: user.nombre, 
                        email: user.correo 
                    }, 
                    token, 
                    user_id: user.id 
                }
            });
        } else {
            res.json({ success: false, message: 'Credenciales incorrectas' });
        }
    } catch (error) {
        res.json({ success: false, message: error.message });
    }
});

// Obtener datos financieros
app.get('/api/financial-data', async (req, res) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        
        const [sessions] = await pool.execute(
            'SELECT usuario_id FROM sesiones WHERE token = ? AND fecha_expiracion > NOW() AND activa = TRUE',
            [token]
        );
        
        if (sessions.length === 0) {
            return res.json({ success: false, message: 'Token inválido' });
        }
        
        const userId = sessions[0].usuario_id;

        // Totales del mes actual (coincide con "Resumen mensual")
        const [monthlyTotals] = await pool.execute(
            `SELECT
                COALESCE(SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END), 0) AS total_ingresos,
                COALESCE(SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END), 0) AS total_gastos
             FROM transacciones
             WHERE usuario_id = ?
               AND YEAR(fecha_transaccion) = YEAR(CURDATE())
               AND MONTH(fecha_transaccion) = MONTH(CURDATE())`,
            [userId]
        );
        
        // Obtener transacciones recientes (consulta directa sin vista)
        const [transactions] = await pool.execute(
            `SELECT t.id, t.descripcion, t.monto, t.tipo, c.nombre as categoria, cu.nombre as cuenta, 
                    t.fecha_transaccion, t.nota 
             FROM transacciones t 
             JOIN categorias c ON t.categoria_id = c.id 
             JOIN cuentas cu ON t.cuenta_id = cu.id 
             WHERE t.usuario_id = ? 
             ORDER BY t.fecha_transaccion DESC, t.created_at DESC 
             LIMIT 10`,
            [userId]
        );
        
        // Obtener presupuestos (consulta directa sin vista)
        const [budgets] = await pool.execute(
            `SELECT p.id, p.nombre, cat.nombre as categoria, p.monto_limite, p.monto_actual, 
                    ROUND((p.monto_actual / p.monto_limite) * 100, 2) as porcentaje_usado 
             FROM presupuestos p 
             JOIN categorias cat ON p.categoria_id = cat.id 
             WHERE p.usuario_id = ? AND p.activo = TRUE`,
            [userId]
        );

        const totals = monthlyTotals[0] || { total_ingresos: 0, total_gastos: 0 };
        const balance = parseFloat(totals.total_ingresos) - parseFloat(totals.total_gastos);
        
        res.json({
            success: true,
            data: {
                balance,
                income: parseFloat(totals.total_ingresos),
                expenses: parseFloat(totals.total_gastos),
                transactions,
                budgets
            }
        });
    } catch (error) {
        res.json({ success: false, message: error.message });
    }
});

// Guardar transacción
app.post('/api/transaction', async (req, res) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        const { descripcion, monto, tipo, categoria, fecha_transaccion, nota } = req.body;
        
        // Validar campos requeridos
        if (!descripcion || !monto || !tipo || !categoria) {
            return res.json({ 
                success: false, 
                message: 'Faltan campos requeridos: descripción, monto, tipo y categoría' 
            });
        }
        
        // Validar tipo
        if (tipo !== 'ingreso' && tipo !== 'gasto') {
            return res.json({ 
                success: false, 
                message: 'Tipo debe ser "ingreso" o "gasto"' 
            });
        }
        
        // Validar monto
        const montoNum = parseFloat(monto);
        if (isNaN(montoNum) || montoNum <= 0) {
            return res.json({ 
                success: false, 
                message: 'El monto debe ser un número positivo' 
            });
        }
        
        const [sessions] = await pool.execute(
            'SELECT usuario_id FROM sesiones WHERE token = ? AND fecha_expiracion > NOW() AND activa = TRUE',
            [token]
        );
        
        if (sessions.length === 0) {
            return res.json({ success: false, message: 'Token inválido' });
        }
        
        const userId = sessions[0].usuario_id;
        
        // Buscar o crear categoría
        let categoriaId;
        const [existingCategories] = await pool.execute(
            'SELECT id FROM categorias WHERE nombre = ? AND (usuario_id IS NULL OR usuario_id = ?)',
            [categoria, userId]
        );
        
        if (existingCategories.length > 0) {
            categoriaId = existingCategories[0].id;
        } else {
            // Crear nueva categoría personalizada para el usuario
            const [newCategory] = await pool.execute(
                'INSERT INTO categorias (nombre, tipo, icono, color, descripcion, predeterminada, usuario_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [
                    categoria, 
                    tipo, 
                    'category', 
                    tipo === 'ingreso' ? '#4CAF50' : '#F44336', 
                    `Categoría personalizada: ${categoria}`, 
                    false, 
                    userId
                ]
            );
            categoriaId = newCategory.insertId;
        }
        
        // Buscar cuenta principal del usuario
        const [cuentas] = await pool.execute(
            'SELECT id FROM cuentas WHERE usuario_id = ? AND activa = TRUE LIMIT 1',
            [userId]
        );
        
        if (cuentas.length === 0) {
            return res.json({ 
                success: false, 
                message: 'No tienes cuentas activas. Agrega una cuenta primero.' 
            });
        }
        
        const cuentaId = cuentas[0].id;
        
        // Preparar fecha y nota (asegurar que no sean undefined)
        const fechaTransaccion = fecha_transaccion || new Date().toISOString().split('T')[0];
        const notaTransaccion = (nota && nota.trim() !== '') ? nota.trim() : null;
        
        console.log('Datos a insertar:', {
            descripcion: descripcion.trim(),
            monto: montoNum,
            tipo,
            categoriaId,
            cuentaId,
            userId,
            fechaTransaccion,
            notaTransaccion
        });
        
        // Insertar transacción directamente
        const [result] = await pool.execute(
            `INSERT INTO transacciones 
             (descripcion, monto, tipo, categoria_id, cuenta_id, usuario_id, fecha_transaccion, nota, created_at) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
            [
                descripcion.trim(), 
                montoNum, 
                tipo, 
                categoriaId, 
                cuentaId, 
                userId, 
                fechaTransaccion, 
                notaTransaccion
            ]
        );
        
        res.json({ 
            success: true, 
            message: 'Transacción guardada correctamente',
            data: {
                id: result.insertId,
                descripcion: descripcion.trim(),
                monto: montoNum,
                tipo,
                categoria,
                fecha_transaccion: fechaTransaccion
            }
        });
    } catch (error) {
        console.error('Error guardando transacción:', error);
        res.json({ 
            success: false, 
            message: error.message || 'Error al guardar la transacción' 
        });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', message: 'Servidor funcionando' });
});

// Iniciar servidor
const PORT = 3000;
initDB().then(() => {
    app.listen(PORT, () => {
        console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
        console.log('📊 Base de datos: MySQL fint_db');
        console.log('🔑 Endpoints:');
        console.log('   POST /api/login - Iniciar sesión');
        console.log('   GET  /api/financial-data - Obtener datos');
        console.log('   POST /api/transaction - Guardar transacción');
        console.log('   GET  /api/health - Verificar estado');
    });
});
