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
    database: 'acosenar'
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
        
        // Buscar usuario en la tabla login con campos "correo" y "contrasena"
        const [rows] = await pool.execute(
            'SELECT id, correo, contrasena FROM login WHERE correo = ? AND contrasena = ?',
            [email, password]
        );
        
        if (rows.length > 0) {
            const user = rows[0];
            const token = Math.random().toString(36).substring(2);
            
            // Guardar token en sessions
            await pool.execute(
                'INSERT INTO sessions (user_id, token, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))',
                [user.id, token]
            );
            
            res.json({
                success: true,
                data: { 
                    user: { 
                        id: user.id, 
                        nombre: user.correo, 
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
            'SELECT user_id FROM sessions WHERE token = ? AND expires_at > NOW()',
            [token]
        );
        
        if (sessions.length === 0) {
            return res.json({ success: false, message: 'Token inválido' });
        }
        
        const userId = sessions[0].user_id;
        
        // Datos financieros
        const [financial] = await pool.execute(
            'SELECT balance, income, expenses FROM financial_data WHERE user_id = ?',
            [userId]
        );
        
        // Transacciones
        const [transactions] = await pool.execute(
            'SELECT id, description, amount, category, type, DATE_FORMAT(date, "%d/%m/%Y") as date FROM transactions WHERE user_id = ? ORDER BY date DESC LIMIT 10',
            [userId]
        );
        
        // Presupuestos
        const [budgets] = await pool.execute(
            'SELECT category, budget, spent FROM budgets WHERE user_id = ?',
            [userId]
        );
        
        const data = financial[0] || { balance: 0, income: 0, expenses: 0 };
        
        res.json({
            success: true,
            data: {
                balance: parseFloat(data.balance),
                income: parseFloat(data.income),
                expenses: parseFloat(data.expenses),
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
        const { description, amount, category, type } = req.body;
        
        const [sessions] = await pool.execute(
            'SELECT user_id FROM sessions WHERE token = ? AND expires_at > NOW()',
            [token]
        );
        
        if (sessions.length === 0) {
            return res.json({ success: false, message: 'Token inválido' });
        }
        
        const userId = sessions[0].user_id;
        
        await pool.execute(
            'INSERT INTO transactions (user_id, description, amount, category, type, date) VALUES (?, ?, ?, ?, ?, CURDATE())',
            [userId, description, parseFloat(amount), category, type]
        );
        
        res.json({ success: true, message: 'Transacción guardada' });
    } catch (error) {
        res.json({ success: false, message: error.message });
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
        console.log('📊 Base de datos: MySQL acosenar');
        console.log('🔑 Endpoints:');
        console.log('   POST /api/login - Iniciar sesión');
        console.log('   GET  /api/financial-data - Obtener datos');
        console.log('   POST /api/transaction - Guardar transacción');
        console.log('   GET  /api/health - Verificar estado');
    });
});
