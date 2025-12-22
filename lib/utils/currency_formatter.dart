import 'package:flutter/services.dart';

/// Formatter para campos de moeda (R$)
/// Formata automaticamente como: R$ 1.234,56
class CurrencyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo exceto números
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Converter para centavos e depois para reais
    final value = int.parse(digitsOnly);
    final reais = value / 100.0;
    
    // Formatar com vírgula como separador decimal
    final formatted = reais.toStringAsFixed(2).replaceAll('.', ',');
    
    // Adicionar separador de milhar
    final parts = formatted.split(',');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';
    
    // Adicionar pontos como separadores de milhar (da direita para esquerda)
    String formattedInteger = '';
    int dotCount = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (dotCount > 0 && dotCount % 3 == 0) {
        formattedInteger = '.$formattedInteger';
      }
      formattedInteger = integerPart[i] + formattedInteger;
      dotCount++;
    }
    
    final finalText = 'R\$ $formattedInteger,$decimalPart';
    
    // Calcular nova posição do cursor (manter posição relativa)
    final oldLength = oldValue.text.length;
    final newLength = finalText.length;
    final oldOffset = oldValue.selection.baseOffset;
    final newOffset = oldOffset == oldLength ? newLength : (oldOffset * newLength / oldLength).round();
    
    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: newOffset.clamp(0, newLength)),
    );
  }
  
  /// Converter texto formatado de volta para centavos (int)
  static int? parseToCents(String formattedText) {
    try {
      // Remove R$ e espaços, substitui vírgula por ponto
      final cleaned = formattedText
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      
      final value = double.tryParse(cleaned);
      if (value == null) return null;
      
      // Converter para centavos
      return (value * 100).round();
    } catch (_) {
      return null;
    }
  }
  
  /// Converter texto formatado para double (reais)
  static double? parseToReais(String formattedText) {
    try {
      if (formattedText.isEmpty || formattedText.trim().isEmpty) return null;
      
      // Remove R$ e espaços, substitui vírgula por ponto, remove pontos de milhar
      final cleaned = formattedText
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '') // Remove separadores de milhar
          .replaceAll(',', '.'); // Converte vírgula decimal para ponto
      
      final value = double.tryParse(cleaned);
      return value != null && value > 0 ? value : null;
    } catch (_) {
      return null;
    }
  }
}







