const axios = require('axios');
const NodeCache = require('node-cache');

// Cache de tasas de cambio con TTL de 4 horas (14400 segundos)
const rateCache = new NodeCache({ stdTTL: 14400, checkperiod: 600 });

/**
 * Obtiene las tasas de cambio para una moneda base dada
 * @param {string} base - Moneda base (USD, EUR, MXN, COP, VES, etc.)
 */
async function getExchangeRates(base = 'USD') {
  const cacheKey = `rates_${base.toUpperCase()}`;
  const cachedRates = rateCache.get(cacheKey);

  if (cachedRates) {
    return { success: true, base: base.toUpperCase(), rates: cachedRates, source: 'cache' };
  }

  // 1. Probar ExchangeRate-API (si existe API key) o su endpoint público
  try {
    const apiKey = process.env.EXCHANGE_RATE_API_KEY;
    const url = apiKey
      ? `https://v6.exchangerate-api.com/v6/${apiKey}/latest/${base.toUpperCase()}`
      : `https://open.er-api.com/v6/latest/${base.toUpperCase()}`;

    const response = await axios.get(url, { timeout: 6000 });
    const rates = response.data.conversion_rates || response.data.rates;

    if (rates) {
      rateCache.set(cacheKey, rates);
      return { success: true, base: base.toUpperCase(), rates, source: 'exchangerate-api' };
    }
  } catch (error) {
    console.warn('⚠️ ExchangeRate-API falló, probando proveedor secundario:', error.message);
  }

  // 2. Fallback: Frankfurter API (para divisas principales)
  try {
    const url = `https://api.frankfurter.dev/v2/rates?base=${base.toUpperCase()}`;
    const response = await axios.get(url, { timeout: 6000 });

    if (response.data && response.data.rates) {
      const rates = response.data.rates;
      rates[base.toUpperCase()] = 1.0; // Incluir la misma base
      rateCache.set(cacheKey, rates);
      return { success: true, base: base.toUpperCase(), rates, source: 'frankfurter' };
    }
  } catch (error) {
    console.error('❌ Frankfurter API falló:', error.message);
  }

  // 3. Fallback de emergencia si no hay internet: tasas fijas de respaldo
  const fallbackRates = {
    USD: 1.0,
    EUR: 0.92,
    MXN: 18.50,
    COP: 4100.0,
    VES: 36.5,
    ARS: 950.0,
    BRL: 5.60,
    CLP: 940.0,
    PEN: 3.75,
  };

  return {
    success: true,
    base: base.toUpperCase(),
    rates: fallbackRates,
    source: 'offline-fallback',
  };
}

/**
 * Convierte un monto entre dos divisas
 */
async function convertCurrency(amount, from, to) {
  const ratesData = await getExchangeRates(from);
  const rate = ratesData.rates[to.toUpperCase()];

  if (!rate) {
    throw new Error(`Moneda de destino "${to}" no encontrada`);
  }

  const convertedAmount = amount * rate;
  return {
    amount,
    from: from.toUpperCase(),
    to: to.toUpperCase(),
    rate,
    result: parseFloat(convertedAmount.toFixed(2)),
  };
}

module.exports = { getExchangeRates, convertCurrency };
