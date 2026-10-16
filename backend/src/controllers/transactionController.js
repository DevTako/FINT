const { pool } = require('../config/database');

async function getFinancialData(req, res) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    const [sessions] = await pool.execute(
      'SELECT usuario_id FROM sesiones WHERE token = ? AND activa = TRUE',
      [token]
    );

    if (sessions.length === 0) {
      return res.status(401).json({ success: false, message: 'Token inválido o expirado' });
    }

    const userId = sessions[0].usuario_id;

    // Obtener información del usuario
    const [userRows] = await pool.execute(
      'SELECT nombre, correo, telefono, zona_vivienda, fecha_registro FROM usuarios WHERE id = ?',
      [userId]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Usuario no encontrado' });
    }
    const user = userRows[0];

    // Totales del mes
    const [totalsRows] = await pool.execute(
      `SELECT
          COALESCE(SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END), 0) AS total_ingresos,
          COALESCE(SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END), 0) AS total_gastos
       FROM transacciones
       WHERE usuario_id = ?
         AND YEAR(fecha_transaccion) = YEAR(CURDATE())
         AND MONTH(fecha_transaccion) = MONTH(CURDATE())`,
      [userId]
    );

    // Transacciones
    const [transactions] = await pool.execute(
      `SELECT t.id, t.descripcion, t.monto, t.tipo, c.nombre as categoria, cu.nombre as cuenta, 
              t.fecha_transaccion, t.nota 
       FROM transacciones t 
       JOIN categorias c ON t.categoria_id = c.id 
       JOIN cuentas cu ON t.cuenta_id = cu.id 
       WHERE t.usuario_id = ? 
       ORDER BY t.fecha_transaccion DESC, t.created_at DESC 
       LIMIT 20`,
      [userId]
    );

    // Presupuestos
    const [budgets] = await pool.execute(
      `SELECT p.id, p.nombre, cat.nombre as categoria, p.monto_limite, p.monto_actual, 
              ROUND((p.monto_actual / p.monto_limite) * 100, 2) as porcentaje_usado 
       FROM presupuestos p 
       JOIN categorias cat ON p.categoria_id = cat.id 
       WHERE p.usuario_id = ? AND p.activo = TRUE`,
      [userId]
    );

    const totals = totalsRows[0] || { total_ingresos: 0, total_gastos: 0 };
    const balance = parseFloat(totals.total_ingresos) - parseFloat(totals.total_gastos);

    return res.json({
      success: true,
      data: {
        balance,
        income: parseFloat(totals.total_ingresos),
        expenses: parseFloat(totals.total_gastos),
        transactions,
        budgets,
        user: {
          nombre: user.nombre,
          correo: user.correo,
          telefono: user.telefono || '',
          zona_vivienda: user.zona_vivienda || '',
          fecha_registro: user.fecha_registro,
        },
      },
    });
  } catch (error) {
    console.error('Error al obtener datos financieros:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function addTransaction(req, res) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { descripcion, monto, tipo, categoria, fecha_transaccion, nota } = req.body;

    if (!descripcion || !monto || !tipo || !categoria) {
      return res.status(400).json({ success: false, message: 'Campos requeridos incompletos' });
    }

    const [sessions] = await pool.execute(
      'SELECT usuario_id FROM sesiones WHERE token = ? AND activa = TRUE',
      [token]
    );

    if (sessions.length === 0) {
      return res.status(401).json({ success: false, message: 'Token inválido' });
    }

    const userId = sessions[0].usuario_id;

    // Buscar o crear categoría
    let categoriaId;
    const [existingCat] = await pool.execute(
      'SELECT id FROM categorias WHERE nombre = ? AND (usuario_id IS NULL OR usuario_id = ?)',
      [categoria, userId]
    );

    if (existingCat.length > 0) {
      categoriaId = existingCat[0].id;
    } else {
      const [newCat] = await pool.execute(
        'INSERT INTO categorias (nombre, tipo, icono, color, usuario_id) VALUES (?, ?, ?, ?, ?)',
        [categoria, tipo, 'category', '#4CAF50', userId]
      );
      categoriaId = newCat.insertId;
    }

    // Buscar cuenta
    const [cuentas] = await pool.execute(
      'SELECT id FROM cuentas WHERE usuario_id = ? AND activa = TRUE LIMIT 1',
      [userId]
    );

    if (cuentas.length === 0) {
      return res.status(400).json({ success: false, message: 'No hay cuentas activas para el usuario' });
    }

    const cuentaId = cuentas[0].id;
    const fecha = fecha_transaccion || new Date().toISOString().split('T')[0];

    const [result] = await pool.execute(
      `INSERT INTO transacciones (descripcion, monto, tipo, categoria_id, cuenta_id, usuario_id, fecha_transaccion, nota)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [descripcion.trim(), parseFloat(monto), tipo, categoriaId, cuentaId, userId, fecha, nota || '']
    );

    // Actualizar saldo de cuenta
    if (tipo === 'ingreso') {
      await pool.execute('UPDATE cuentas SET saldo_actual = saldo_actual + ? WHERE id = ?', [parseFloat(monto), cuentaId]);
    } else {
      await pool.execute('UPDATE cuentas SET saldo_actual = saldo_actual - ? WHERE id = ?', [parseFloat(monto), cuentaId]);
    }

    return res.json({
      success: true,
      message: 'Transacción registrada exitosamente',
      data: { id: result.insertId, descripcion, monto, tipo, categoria, fecha },
    });
  } catch (error) {
    console.error('Error al agregar transacción:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = { getFinancialData, addTransaction };
