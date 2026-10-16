const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { testConnection } = require('./src/config/database');
const apiRoutes = require('./src/routes/api');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Montar rutas API
app.use('/api', apiRoutes);

// Iniciar servidor
testConnection().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Servidor FINT v2 corriendo en http://localhost:${PORT}`);
    console.log(`🔑 Endpoints activos:`);
    console.log(`   POST /api/login - Iniciar sesión`);
    console.log(`   POST /api/register - Registro de usuario`);
    console.log(`   GET  /api/financial-data - Datos financieros`);
    console.log(`   POST /api/transaction - Registrar transacción`);
    console.log(`   GET  /api/currency/rates - Tasas de cambio en vivo`);
    console.log(`   GET  /api/currency/venezuela - Tasas BCV y Binance P2P`);
    console.log(`   POST /api/currency/convert - Conversor de divisas`);
  });
});
