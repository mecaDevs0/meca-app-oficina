import 'package:flutter/material.dart';

abstract class AppColors {
  // Paleta de cores do Meca Oficina
  static const primaryColor = Color(0xFF252940); // Azul primário
  static const secondaryColor = Color(0xFF00C977); // Verde secundário
  static const tertiaryColor = Color(0xFF64AF7D); // Verde terciário
  
  // Cores de fundo
  static const backgroundColor = Color(0xFFFFFFFF); // Branco
  static const surfaceColor = Color(0xFFEEEEEE); // Cinza claro
  
  // Cores de texto
  static const fontDarkGray = Color(0xFF1B1D2E); // Texto escuro
  static const grayMedium = Color(0xFF569775); // Texto médio
  
  // Cores de borda e linha
  static const grayBorderColor = Color(0xFFDBDBDB); // Borda cinza
  static const grayLineColor = Color(0xFFDBDBDB); // Linha cinza
  
  // Cores de estado
  static const successColor = Color(0xFF00C977); // Verde sucesso
  static const errorColor = Color(0xFFE8867C); // Vermelho erro
  static const warningColor = Color(0xFFFFA726); // Laranja aviso
  static const infoColor = Color(0xFF7896D8); // Azul informação
  
  // Cores auxiliares
  static const hintTextColor = Color(0xFFC3CFD9);
  static const apricot = Color(0xFFE8867C);
  static const black = Color(0xFF010101);
  static const abbey = Color(0xFF52535C);
  static const ceriseRed = Color(0xFFDD295C);
  static const mercury = Color(0xFFE5E5E5);
  static const silver = Color(0xFFBCBCBC);
  static const chetwodeBlue = Color(0xFF7896D8);
  static const alto = Color(0xFFD9D9D9);
  static const shamrock = Color(0xFF2FD65C);
  static const hintOfGreen = Color(0xFFE7FFED);
  static const caribbeanGreen = Color(0xFF00C977);
  static const mineShaft = Color(0xFF2D2D2D);
  static const boulder = Color(0xFF757575);
  static const halfBaked = Color(0xFF73ABCD);
  static const baliHai = Color(0xFF8F9BB3);
  static const cloudBurst = Color(0xFF222B45);
  static const dustyGray = Color(0xFF9C9C9C);
  static const tundora = Color(0xFF414141);
  static const whiteIce = Color(0xFFE1FBF0);
  
  // Cores adicionais para compatibilidade
  static const primaryDark = Color(0xFF101221);
  static const gray100 = Color(0xFFF5F5F5);
  static const gray300 = Color(0xFFE0E0E0);
  static const gray500 = Color(0xFF9E9E9E);
  
  // Legacy colors for compatibility
  static const success = successColor;
  static const successLight = hintOfGreen;
  static const warning = warningColor;
  static const warningLight = Color(0xFFFEF3C7);
  static const error = errorColor;
  static const errorLight = Color(0xFFFEE2E2);
  static const info = infoColor;
  static const infoLight = Color(0xFFDBEAFE);
  static const white = backgroundColor;
  static const gray900 = fontDarkGray;
  static const gray800 = mineShaft;
  static const gray700 = tundora;
  static const gray600 = abbey;
  static const gray400 = silver;
  static const gray200 = mercury;
  static const gray50 = Color(0xFFFAFAFA);
}
