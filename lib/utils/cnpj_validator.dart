/// Validador de CNPJ
class CnpjValidator {
  /// Valida se um CNPJ é válido (formato e dígitos verificadores)
  static bool isValid(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) return false;
    
    // Remove formatação
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    
    // Deve ter 14 dígitos
    if (cnpjLimpo.length != 14) return false;
    
    // Verificar se todos os dígitos são iguais (CNPJ inválido)
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpjLimpo)) return false;
    
    // Validar dígitos verificadores
    final numbers = cnpjLimpo.substring(0, 12);
    final digits = cnpjLimpo.substring(12);
    
    // Calcular primeiro dígito verificador
    int sum = 0;
    int pos = 5;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(numbers[i]) * pos;
      pos--;
      if (pos < 2) pos = 9;
    }
    
    int result = sum % 11;
    result = result < 2 ? 0 : 11 - result;
    
    if (result != int.parse(digits[0])) return false;
    
    // Calcular segundo dígito verificador
    sum = 0;
    pos = 6;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpjLimpo[i]) * pos;
      pos--;
      if (pos < 2) pos = 9;
    }
    
    result = sum % 11;
    result = result < 2 ? 0 : 11 - result;
    
    return result == int.parse(digits[1]);
  }
  
  /// Retorna mensagem de erro específica para CNPJ inválido
  static String? validate(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cnpjLimpo.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }
    
    if (!isValid(cnpj)) {
      return 'CNPJ inválido. Verifique os dígitos verificadores.';
    }
    
    return null;
  }
}


