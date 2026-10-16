const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'fint_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
};

const pool = mysql.createPool(dbConfig);

async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Base de datos MySQL conectada correctamente');
    
    // Ejecutar migración para añadir zona_vivienda
    try {
      await connection.execute(
        'ALTER TABLE usuarios ADD COLUMN zona_vivienda VARCHAR(255) NULL'
      );
      console.log('✅ Columna "zona_vivienda" agregada a la tabla usuarios');
    } catch (e) {
      if (e.errno !== 1060 && e.code !== 'ER_DUP_FIELDNAME') {
        console.error('Error al migrar base de datos:', e.message);
      }
    }
    
    connection.release();
  } catch (error) {
    console.error('❌ Error conectando a MySQL:', error.message);
  }
}

module.exports = { pool, testConnection };
