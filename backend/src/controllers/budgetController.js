const { pool } = require('../config/database');

async function getBudgets(req, res) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const [sessions] = await pool.execute('SELECT usuario_id FROM sesiones WHERE token = ? AND activa = TRUE', [token]);

    if (sessions.length === 0) {
      return res.status(401).json({ success: false, message: 'Token inválido' });
    }

    const userId = sessions[0].usuario_id;
    const [budgets] = await pool.execute(
      `SELECT p.id, p.nombre, cat.nombre as categoria, p.monto_limite, p.monto_actual, 
              ROUND((p.monto_actual / p.monto_limite) * 100, 2) as porcentaje_usado,
              p.periodo
       FROM presupuestos p 
       JOIN categorias cat ON p.categoria_id = cat.id 
       WHERE p.usuario_id = ? AND p.activo = TRUE`,
      [userId]
    );

    return res.json({ success: true, data: budgets });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function createBudget(req, res) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { nombre, categoria, monto_limite, periodo } = req.body;

    const [sessions] = await pool.execute('SELECT usuario_id FROM sesiones WHERE token = ? AND activa = TRUE', [token]);
    if (sessions.length === 0) {
      return res.status(401).json({ success: false, message: 'Token inválido' });
    }

    const userId = sessions[0].usuario_id;

    // Buscar categoría
    const [cats] = await pool.execute('SELECT id FROM categorias WHERE nombre = ? LIMIT 1', [categoria]);
    const categoriaId = cats.length > 0 ? cats[0].id : 5; // Default Alimentos

    const fechaInicio = new Date().toISOString().split('T')[0];
    const fechaFin = new Date(Date.now() + 30*24*60*60*1000).toISOString().split('T')[0];

    const [result] = await pool.execute(
      `INSERT INTO presupuestos (nombre, categoria_id, usuario_id, monto_limite, periodo, fecha_inicio, fecha_fin)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [nombre || `Presupuesto ${categoria}`, categoriaId, userId, parseFloat(monto_limite), periodo || 'mensual', fechaInicio, fechaFin]
    );

    return res.json({ success: true, message: 'Presupuesto creado', id: result.insertId });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = { getBudgets, createBudget };
