const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const transactionController = require('../controllers/transactionController');
const budgetController = require('../controllers/budgetController');
const currencyController = require('../controllers/currencyController');

// Auth
router.post('/login', authController.login);
router.post('/register', authController.register);
router.put('/profile', authController.updateProfile);
router.delete('/profile', authController.deleteAccount);

// Transacciones y Finanzas
router.get('/financial-data', transactionController.getFinancialData);
router.post('/transaction', transactionController.addTransaction);

// Presupuestos
router.get('/budgets', budgetController.getBudgets);
router.post('/budget', budgetController.createBudget);

// Divisas y Mercado
router.get('/currency/rates', currencyController.getRates);
router.get('/currency/venezuela', currencyController.getVenezuelaRates);
router.post('/currency/convert', currencyController.convert);

// Health Check
router.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Servidor FINT v2 funcionando correctamente' });
});

module.exports = router;
