class PriceUtils {
  const PriceUtils._();

  /// Normaliza diferentes formatos de preço (int em centavos, double, string com "R$" etc).
  /// Retorna `null` quando o valor não é válido ou é zero/negativo.
  static double? extractPrice(dynamic value) {
    if (value == null) return null;

    double? normalized;
    bool originalHadDecimal = false;

    if (value is num) {
      normalized = value.toDouble();
    } else {
      final cleaned = value
          .toString()
          .trim()
          .replaceAll(RegExp(r'[^0-9,.\-]'), '')
          .replaceAll(',', '.');
      if (cleaned.contains('.')) {
        originalHadDecimal = true;
      }
      normalized = double.tryParse(cleaned);
    }

    if (normalized == null) return null;
    if (!originalHadDecimal && normalized.abs() >= 1000 && normalized % 1 == 0) {
      normalized = normalized / 100;
    }

    if (normalized <= 0) return null;
    return normalized;
  }

  /// Converte qualquer formato de preço em centavos (int).
  /// Aceita int, double, String ("2665072", "2665072.00", "2665072,00").
  /// Retorna 0 se não puder parsear.
  static int toCents(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    if (raw is String) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) return 0;
      final parsed = double.tryParse(cleaned.replaceAll(',', '.'));
      if (parsed != null) return parsed.round();
    }
    return 0;
  }

  static bool hasValidPrice(dynamic value) => extractPrice(value) != null;

  static String? formatCurrency(dynamic value) {
    final price = extractPrice(value);
    if (price == null) return null;
    return 'R\$ ${price.toStringAsFixed(2)}';
  }

  static String formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

