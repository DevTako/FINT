const { getExchangeRates, convertCurrency } = require('../services/currencyService');
const { getVenezuelaMarketSummary } = require('../services/venezuelaRatesService');

async function getRates(req, res) {
  try {
    const base = req.query.base || 'USD';
    const result = await getExchangeRates(base);
    return res.json(result);
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function getVenezuelaRates(req, res) {
  try {
    const summary = await getVenezuelaMarketSummary();
    return res.json(summary);
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function convert(req, res) {
  try {
    const { amount, from, to } = req.body;
    if (!amount || !from || !to) {
      return res.status(400).json({ success: false, message: 'Faltan parámetros amount, from, to' });
    }

    const result = await convertCurrency(parseFloat(amount), from, to);
    return res.json({ success: true, data: result });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = { getRates, getVenezuelaRates, convert };
