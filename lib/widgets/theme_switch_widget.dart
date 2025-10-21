import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

class ThemeSwitchWidget extends StatelessWidget {
  final bool showLabel;
  final double? size;

  const ThemeSwitchWidget({
    Key? key,
    this.showLabel = true,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: () => themeService.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeService.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeService.isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone do tema
                Container(
                  width: size ?? 24,
                  height: size ?? 24,
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    themeService.isDarkMode 
                        ? Icons.dark_mode 
                        : Icons.light_mode,
                    color: Colors.white,
                    size: (size ?? 24) * 0.6,
                  ),
                ),
                
                if (showLabel) ...[
                  const SizedBox(width: 12),
                  Text(
                    themeService.isDarkMode ? 'Modo Escuro' : 'Modo Claro',
                    style: TextStyle(
                      color: themeService.isDarkMode ? Colors.white : const Color(0xFF252940),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ThemeSwitchButton extends StatefulWidget {
  const ThemeSwitchButton({Key? key}) : super(key: key);

  @override
  State<ThemeSwitchButton> createState() => _ThemeSwitchButtonState();
}

class _ThemeSwitchButtonState extends State<ThemeSwitchButton> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: _isToggling ? null : () async {
              setState(() => _isToggling = true);
              print('Theme switch pressed - current: ${themeService.isDarkMode}');
              themeService.toggleTheme();
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                setState(() => _isToggling = false);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeService.isDarkMode 
                    ? const Color(0xFF00C977).withOpacity(0.15)
                    : const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: themeService.isDarkMode 
                      ? const Color(0xFF00C977).withOpacity(0.3)
                      : const Color(0xFF3B82F6).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                themeService.isDarkMode 
                    ? Icons.dark_mode 
                    : Icons.light_mode,
                color: themeService.isDarkMode 
                    ? const Color(0xFF00C977) 
                    : const Color(0xFF3B82F6),
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ThemeSwitchCard extends StatelessWidget {
  const ThemeSwitchCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeService.isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Ícone do tema atual
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: themeService.isDarkMode 
                      ? const Color(0xFF00C977).withOpacity(0.1)
                      : const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  themeService.isDarkMode 
                      ? Icons.dark_mode 
                      : Icons.light_mode,
                  color: themeService.isDarkMode 
                      ? const Color(0xFF00C977) 
                      : const Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informações do tema
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema da Aplicação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeService.isDarkMode ? Colors.white : const Color(0xFF252940),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      themeService.isDarkMode 
                          ? 'Modo escuro ativo' 
                          : 'Modo claro ativo',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.isDarkMode ? const Color(0xFF8B8B8B) : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Switch
              Switch(
                value: !themeService.isDarkMode, // Invertido: true = claro, false = escuro
                onChanged: (value) => themeService.toggleTheme(),
                activeColor: const Color(0xFF00C977),
                activeTrackColor: const Color(0xFF00C977).withOpacity(0.3),
                inactiveThumbColor: const Color(0xFF8B8B8B),
                inactiveTrackColor: const Color(0xFF333333),
              ),
            ],
          ),
        );
      },
    );
  }
}
                    ),

                    ),
                  ],
                ),
              ),
              
              // Switch
              Switch(
                value: !themeService.isDarkMode, // Invertido: true = claro, false = escuro
                onChanged: (value) => themeService.toggleTheme(),
                activeColor: const Color(0xFF00C977),
                activeTrackColor: const Color(0xFF00C977).withOpacity(0.3),
                inactiveThumbColor: const Color(0xFF8B8B8B),
                inactiveTrackColor: const Color(0xFF333333),
              ),
            ],
          ),
        );
      },
    );
  }
}
                    ),
