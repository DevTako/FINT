class CurrencyInfo {
  final String code;
  final String name;
  final String flag;
  final String symbol;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.symbol,
  });
}

class CurrencyFormatter {
  CurrencyFormatter._();

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'USD', name: 'Dólar Estadounidense', flag: '🇺🇸', symbol: '\$'),
    CurrencyInfo(code: 'EUR', name: 'Euro (Unión Europea)', flag: '🇪🇺', symbol: '€'),
    CurrencyInfo(code: 'MXN', name: 'Peso Mexicano', flag: '🇲🇽', symbol: '\$'),
    CurrencyInfo(code: 'COP', name: 'Peso Colombiano', flag: '🇨🇴', symbol: '\$'),
    CurrencyInfo(code: 'VES', name: 'Bolívar Venezolano', flag: '🇻🇪', symbol: 'Bs.'),
    CurrencyInfo(code: 'ARS', name: 'Peso Argentino', flag: '🇦🇷', symbol: '\$'),
    CurrencyInfo(code: 'BRL', name: 'Real Brasileño', flag: '🇧🇷', symbol: 'R\$'),
    CurrencyInfo(code: 'CLP', name: 'Peso Chileno', flag: '🇨🇱', symbol: '\$'),
    CurrencyInfo(code: 'PEN', name: 'Sol Peruano', flag: '🇵🇪', symbol: 'S/'),
  ];

  static CurrencyInfo getInfo(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => CurrencyInfo(code: code.toUpperCase(), name: code, flag: '🌐', symbol: '\$'),
    );
  }

  /// Formatea un número con la separación estándar para monedas (miles con punto y decimales con coma).
  /// Ejemplos:
  /// 87912.25 -> "87.912,25"
  /// 879.12 -> "879,12"
  /// 100673.30 -> "100.673,30"
  /// 1006.73 -> "1.006,73"
  static String formatNumber(double value, {int decimals = 2}) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(decimals).split('.');

    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    final len = integerPart.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    final formatted = decimals > 0 ? '$buffer,$decimalPart' : buffer.toString();
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formato completo con símbolo y código de divisa
  static String format(double amount, {String currencySymbol = '\$', String currencyCode = 'USD'}) {
    final isHighValueCurrency = ['COP', 'ARS', 'CLP'].contains(currencyCode.toUpperCase());
    final decimals = isHighValueCurrency ? 0 : 2;
    final formattedNumber = formatNumber(amount, decimals: decimals);

    if (currencyCode.trim().isEmpty) {
      return '$currencySymbol $formattedNumber';
    }
    return '$currencySymbol $formattedNumber ${currencyCode.toUpperCase()}'.trim();
  }

  /// Formato de Bolívares (VES)
  static String formatVes(double amount, {int decimals = 2}) {
    return '${formatNumber(amount, decimals: decimals)} Bs.';
  }

  static String symbolFor(String currencyCode) {
    return getInfo(currencyCode).symbol;
  }
}
