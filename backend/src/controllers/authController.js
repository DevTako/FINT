const { pool } = require('../config/database');
const bcrypt = require('bcryptjs');

// Login
async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Correo y contraseña requeridos' });
    }

    const [rows] = await pool.execute(
      'SELECT id, nombre, correo, contrasena FROM usuarios WHERE correo = ? AND activo = TRUE',
      [email]
    );

    if (rows.length > 0) {
      const user = rows[0];
      let passwordMatches = false;

      // Soporta hashes bcrypt y migración si era texto plano
      if (user.contrasena.startsWith('$2a$') || user.contrasena.startsWith('$2b$')) {
        passwordMatches = await bcrypt.compare(password, user.contrasena);
      } else {
        passwordMatches = (user.contrasena === password);
        // Si coincidió en texto plano, actualizamos automáticamente a bcrypt hash
        if (passwordMatches) {
          const newHash = await bcrypt.hash(password, 10);
          await pool.execute('UPDATE usuarios SET contrasena = ? WHERE id = ?', [newHash, user.id]);
        }
      }

      if (!passwordMatches) {
        return res.status(401).json({ success: false, message: 'Credenciales incorrectas' });
      }

      const token = 'token_' + Math.random().toString(36).substring(2) + Date.now().toString(36);

      await pool.execute(
        'INSERT INTO sesiones (usuario_id, token, fecha_expiracion) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))',
        [user.id, token]
      );

      return res.json({
        success: true,
        data: {
          user: { id: user.id, nombre: user.nombre, email: user.correo },
          token,
          user_id: user.id,
        },
      });
    } else {
      return res.status(401).json({ success: false, message: 'Credenciales incorrectas' });
    }
  } catch (error) {
    console.error('Error en login:', error);
    return res.status(500).json({ success: false, message: 'Error interno del servidor' });
  }
}

// Register
async function register(req, res) {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Nombre, correo y contraseña son requeridos' });
    }

    // Verificar si el usuario ya existe
    const [existing] = await pool.execute('SELECT id FROM usuarios WHERE correo = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: 'El correo ya está registrado' });
    }

    // Hashear contraseña de forma segura
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insertar usuario
    const [result] = await pool.execute(
      'INSERT INTO usuarios (nombre, correo, contrasena) VALUES (?, ?, ?)',
      [name, email, hashedPassword]
    );

    const userId = result.insertId;
    const token = 'token_' + Math.random().toString(36).substring(2) + Date.now().toString(36);

    await pool.execute(
      'INSERT INTO sesiones (usuario_id, token, fecha_expiracion) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))',
      [userId, token]
    );

    // Crear cuenta principal predeterminada
    await pool.execute(
      'INSERT INTO cuentas (nombre, tipo, banco, saldo_inicial, saldo_actual, usuario_id) VALUES (?, ?, ?, ?, ?, ?)',
      ['Cuenta Principal', 'bancaria', 'Banco Principal', 0.00, 0.00, userId]
    );

    return res.status(201).json({
      success: true,
      message: 'Usuario registrado exitosamente',
      data: {
        user: { id: userId, nombre: name, email },
        token,
        user_id: userId,
      },
    });
  } catch (error) {
    console.error('Error en registro:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}

// Update Profile
async function updateProfile(req, res) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { name, email, phone, housingZone } = req.body;

    if (!name || !email) {
      return res.status(400).json({ success: false, message: 'Nombre y correo requeridos' });
    }

    const [sessions] = await pool.execute(
      'SELECT usuario_id FROM sesiones WHERE token = ? AND activa = TRUE',
      [token]
    );

    if (sessions.length === 0) {
      return res.status(401).json({ success: false, message: 'Token inválido o expirado' });
    }

    const userId = sessions[0].usuario_id;

    // Verificar si el correo ya existe en otro usuario
    const [existing] = await pool.execute(
      'SELECT id FROM usuarios WHERE correo = ? AND id != ?',
      [email, userId]
    );
    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: 'El correo ya está en uso' });
    }

    await pool.execute(
      'UPDATE usuarios SET nombre = ?, correo = ?, telefono = ?, zona_vivienda = ? WHERE id = ?',
      [name, email, phone || null, housingZone || null, userId]
    );

    return res.json({ success: true, message: 'Perfil actualizado correctamente' });
  } catch (error) {
    console.error('Error al actualizar perfil:', error);
    return res.status(500).json({ success: false, message: 'Error interno del servidor' });
  }
}

// Delete Account
async function deleteAccount(req, res) {
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

    // Eliminar el usuario (cuyo ON DELETE CASCADE borrará todo)
    await pool.execute('DELETE FROM usuarios WHERE id = ?', [userId]);

    return res.json({ success: true, message: 'Cuenta eliminada correctamente' });
  } catch (error) {
    console.error('Error al eliminar cuenta:', error);
    return res.status(500).json({ success: false, message: 'Error interno del servidor' });
  }
}

module.exports = { login, register, updateProfile, deleteAccount };
