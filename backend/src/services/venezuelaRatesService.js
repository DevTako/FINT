const axios = require('axios');
const cheerio = require('cheerio');
const https = require('https');
const NodeCache = require('node-cache');

// Cache con tiempo de vida (TTL) de 15 minutos (900s)
const veRatesCache = new NodeCache({ stdTTL: 900, checkperiod: 120 });

// Agente HTTPS para omitir problemas de certificados del portal BCV
const httpsAgent = new https.Agent({
  rejectUnauthorized: false,
});

/**
 * Obtener la tasa oficial del Banco Central de Venezuela (BCV)
 * Incluye scraping directo a bcv.org.ve y fallback a DolarApi VE.
 */
async function getBcvRate() {
  const cacheKey = 'rate_bcv';
  const cached = veRatesCache.get(cacheKey);
  if (cached) return cached;

  // 1. Scraping directo a la web oficial del BCV
  try {
    const response = await axios.get('https://www.bcv.org.ve/', {
      httpsAgent,
      timeout: 8000,
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    });

    const $ = cheerio.load(response.data);
    const usdRaw = $('#dolar strong').text().trim().replace(',', '.');
    const eurRaw = $('#euro strong').text().trim().replace(',', '.');
    const dateRaw = $('div.pull-right.dinpro span.date-display-single').text().trim();

    const usdPrice = parseFloat(usdRaw);
    const eurPrice = parseFloat(eurRaw);

    if (!isNaN(usdPrice) && usdPrice > 0) {
      const data = {
        success: true,
        source: 'bcv_direct',
        usd: usdPrice,
        eur: isNaN(eurPrice) ? null : eurPrice,
        date: dateRaw || new Date().toISOString(),
        timestamp: Date.now(),
      };
      veRatesCache.set(cacheKey, data);
      return data;
    }
  } catch (error) {
    console.warn('⚠️ Scraping directo a bcv.org.ve falló:', error.message);
  }

  // 2. Fallback a DolarApi Venezuela (Refleja el valor exacto publicado por BCV)
  try {
    const fallbackResponse = await axios.get('https://ve.dolarapi.com/v1/dolares/oficial', {
      timeout: 6000,
    });

    if (fallbackResponse.data && fallbackResponse.data.promedio) {
      const data = {
        success: true,
        source: 'bcv_dolarapi',
        usd: parseFloat(fallbackResponse.data.promedio),
        eur: null,
        date: fallbackResponse.data.fechaActualizacion || new Date().toISOString(),
        timestamp: Date.now(),
      };
      veRatesCache.set(cacheKey, data);
      return data;
    }
  } catch (error) {
    console.warn('⚠️ Fallback DolarApi BCV falló:', error.message);
  }

  // 3. Respaldo histórico de emergencia
  return {
    success: false,
    source: 'bcv_fallback_offline',
    usd: 36.50,
    eur: 39.80,
    date: new Date().toISOString(),
    timestamp: Date.now(),
  };
}

/**
 * Obtener la tasa de USDT y USDC en Binance P2P (VES) y Spot
 */
async function getBinanceRates() {
  const cacheKey = 'rate_binance_p2p';
  const cached = veRatesCache.get(cacheKey);
  if (cached) return cached;

  let usdtPrice = null;
  let usdcPrice = null;

  // 1. Obtener precio promedio de compra/venta en Binance P2P vía CriptoYa (sin bloqueo 403)
  try {
    const p2pRes = await axios.get('https://criptoya.com/api/binancep2p/usdt/ves/10', {
      timeout: 5000,
    });
    if (p2pRes.data && p2pRes.data.ask && p2pRes.data.bid) {
      usdtPrice = parseFloat(((p2pRes.data.ask + p2pRes.data.bid) / 2).toFixed(2));
    } else if (p2pRes.data?.ask) {
      usdtPrice = parseFloat(p2pRes.data.ask.toFixed(2));
    }
  } catch (_) {
    // Silencioso, continuamos con el siguiente proveedor
  }

  // 2. Si no respondió CriptoYa, consultar DolarApi paralelo
  if (!usdtPrice) {
    try {
      const cryptoFallback = await axios.get('https://ve.dolarapi.com/v1/dolares/paralelo', {
        timeout: 5000,
      });
      if (cryptoFallback.data?.promedio) {
        usdtPrice = parseFloat(cryptoFallback.data.promedio.toFixed(2));
      }
    } catch (_) {}
  }

  // 3. Fallback de contingencia si no hay internet
  if (!usdtPrice) {
    usdtPrice = 1006.50;
  }

  // 4. Ratio USDC/USDT
  let usdcToUsdtRatio = 1.0;
  try {
    const spotResponse = await axios.get(
      'https://api.binance.com/api/v3/ticker/price?symbol=USDCUSDT',
      { timeout: 4000 }
    );
    if (spotResponse.data?.price) {
      usdcToUsdtRatio = parseFloat(spotResponse.data.price);
    }
  } catch (_) {}

  usdcPrice = parseFloat((usdtPrice * usdcToUsdtRatio).toFixed(2));

  const result = {
    success: true,
    source: 'binance_p2p',
    usdt: usdtPrice,
    usdc: usdcPrice,
    ratio_usdc_usdt: usdcToUsdtRatio,
    timestamp: Date.now(),
  };

  veRatesCache.set(cacheKey, result);
  return result;
}

/**
 * Resumen consolidado: Dólar Oficial BCV + Binance P2P (USDT, USDC) y cálculo de brecha
 */
async function getVenezuelaMarketSummary() {
  const [bcv, binance] = await Promise.all([getBcvRate(), getBinanceRates()]);

  const bcvUsd = bcv.usd || 0;
  const binanceUsdt = binance.usdt || 0;
  const binanceUsdc = binance.usdc || 0;

  // Cálculo de brecha porcentual entre BCV y Binance USDT
  let spreadPercentage = 0;
  if (bcvUsd > 0 && binanceUsdt > 0) {
    spreadPercentage = parseFloat((((binanceUsdt - bcvUsd) / bcvUsd) * 100).toFixed(2));
  }

  return {
    success: true,
    timestamp: new Date().toISOString(),
    bcv: {
      usd: bcvUsd,
      eur: bcv.eur,
      source: bcv.source,
      date: bcv.date,
    },
    binance: {
      usdt: binanceUsdt,
      usdc: binanceUsdc,
      source: binance.source,
    },
    spread: {
      percentage: spreadPercentage,
      diff_ves: parseFloat((binanceUsdt - bcvUsd).toFixed(4)),
    },
  };
}

module.exports = {
  getBcvRate,
  getBinanceRates,
  getVenezuelaMarketSummary,
};
