class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;
}

abstract class Currencies {
  static const List<Currency> all = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
    Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
    Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
    Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
    Currency(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$'),
    Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
    Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
    Currency(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿'),
    Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
    Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨'),
    Currency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£'),
    Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦'),
    Currency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳'),
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
    Currency(code: 'XOF', name: 'West African CFA Franc', symbol: 'CFA'),
    Currency(code: 'XAF', name: 'Central African CFA Franc', symbol: 'FCFA'),
  ];

  static Currency? detect(String locale) {
    final code =
        locale.split('_').lastOrNull?.toUpperCase() ?? locale.toUpperCase();
    try {
      return all.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }
}
