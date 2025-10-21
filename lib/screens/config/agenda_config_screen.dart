import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/beautiful_error_snackbar.dart';
import '../../widgets/theme_switch_widget.dart';

class AgendaConfigScreen extends StatefulWidget {
  const AgendaConfigScreen({Key? key}) : super(key: key);

  @override
  State<AgendaConfigScreen> createState() => _AgendaConfigScreenState();
}

class _AgendaConfigScreenState extends State<AgendaConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _schedule = {};
  final ApiService _apiService = ApiService();

  final List<String> _days = [
    'monday',
    'tuesday', 
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  final Map<String, String> _dayNames = {
    'monday': 'Segunda-feira',
    'tuesday': 'Terça-feira',
    'wednesday': 'Quarta-feira',
    'thursday': 'Quinta-feira',
    'friday': 'Sexta-feira',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      final result = await _apiService.getSchedule();
      
      if (result['success']) {
        setState(() {
          _schedule = result['data'] ?? {};
        });
      } else {
        BeautifulErrorSnackbar.show(
          context,
          'Erro ao carregar agenda: ${result['error']}',
          title: 'Erro',
        );
      }
    } catch (e) {
      BeautifulErrorSnackbar.show(
        context,
        'Erro: $e',
        title: 'Erro',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    
    try {
      await _apiService.loadToken();
      final result = await _apiService.updateSchedule(_schedule);
      
      if (result['success']) {
        BeautifulErrorSnackbar.showSuccess(
          context,
          'Agenda salva com sucesso!',
          title: 'Sucesso',
        );
        Navigator.pop(context, true); // Passa true para indicar sucesso
      } else {
        BeautifulErrorSnackbar.show(
          context,
          'Erro: ${result['error']}',
          title: 'Erro',
        );
      }
    } catch (e) {
      BeautifulErrorSnackbar.show(
        context,
        'Erro: $e',
        title: 'Erro',
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _selectAllDays() {
    setState(() {
      for (String day in _days) {
        _schedule[day] = {
          'is_open': true,
          'start_time': '08:00',
          'end_time': '18:00',
          'break_start': null,
          'break_end': null,
        };
      }
    });
  }

  void _deselectAllDays() {
    setState(() {
      for (String day in _days) {
        _schedule[day] = {
          'is_open': false,
          'start_time': null,
          'end_time': null,
          'break_start': null,
          'break_end': null,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Horários de Funcionamento'),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          const ThemeSwitchButton(),
          TextButton(
            onPressed: _isSaving ? null : _saveSchedule,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Color(0xFF00C977),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Horários de Funcionamento',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure os horários de atendimento para cada dia da semana',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Select All / Deselect All buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          title: 'Selecionar Todos',
                          icon: Icons.check_circle_outline,
                          onTap: _selectAllDays,
                          color: const Color(0xFF00C977),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          title: 'Desmarcar Todos',
                          icon: Icons.cancel_outlined,
                          onTap: _deselectAllDays,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Days list
                  ..._days.map((day) => _buildDayCard(day)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String day) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    
    final dayData = _schedule[day] ?? {
      'is_open': false,
      'start_time': '08:00',
      'end_time': '18:00',
      'break_start': null,
      'break_end': null,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with checkbox
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _schedule[day] = {
                      ...dayData,
                      'is_open': !dayData['is_open'],
                    };
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dayData['is_open'] 
                        ? const Color(0xFF00C977) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: dayData['is_open'] 
                          ? const Color(0xFF00C977) 
                          : const Color(0xFF666666),
                      width: 2,
                    ),
                  ),
                  child: dayData['is_open']
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _dayNames[day]!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),

          if (dayData['is_open']) ...[
            const SizedBox(height: 20),
            
            // Time inputs
            Row(
              children: [
                Expanded(
                  child: _buildTimeInput(
                    label: 'Abertura',
                    value: dayData['start_time'] ?? '08:00',
                    onChanged: (value) {
                      setState(() {
                        _schedule[day] = {
                          ...dayData,
                          'start_time': value,
                        };
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeInput(
                    label: 'Fechamento',
                    value: dayData['end_time'] ?? '18:00',
                    onChanged: (value) {
                      setState(() {
                        _schedule[day] = {
                          ...dayData,
                          'end_time': value,
                        };
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTimeInput(
                    label: 'Início do Almoço (opcional)',
                    value: dayData['lunch_start'] ?? '',
                    onChanged: (value) {
                      setState(() {
                        _schedule[day] = {
                          ...dayData,
                          'lunch_start': value,
                        };
                      });
                    },
                    isOptional: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeInput(
                    label: 'Fim do Almoço (opcional)',
                    value: dayData['lunch_end'] ?? '',
                    onChanged: (value) {
                      setState(() {
                        _schedule[day] = {
                          ...dayData,
                          'lunch_end': value,
                        };
                      });
                    },
                    isOptional: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required String value,
    required Function(String) onChanged,
    bool isOptional = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final inputColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectTime(context, value, onChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: secondaryTextColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.isEmpty ? (isOptional ? 'Selecionar' : '08:00') : value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value.isEmpty && isOptional 
                          ? secondaryTextColor 
                          : textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, String currentValue, Function(String) onChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentValue.isNotEmpty 
          ? TimeOfDay(
              hour: int.parse(currentValue.split(':')[0]),
              minute: int.parse(currentValue.split(':')[1]),
            )
          : const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C977),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(timeString);
    }
  }
}
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentValue.isNotEmpty 
          ? TimeOfDay(
              hour: int.parse(currentValue.split(':')[0]),
              minute: int.parse(currentValue.split(':')[1]),
            )
          : const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C977),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(timeString);
    }
  }
}