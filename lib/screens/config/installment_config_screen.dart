import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class InstallmentConfigScreen extends StatefulWidget {
  const InstallmentConfigScreen({Key? key}) : super(key: key);

  @override
  State<InstallmentConfigScreen> createState() => _InstallmentConfigScreenState();
}

class _InstallmentConfigScreenState extends State<InstallmentConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _acceptsInstallment = true;
  int _maxInstallments = 12;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadInstallmentConfig();
  }

  Future<void> _loadInstallmentConfig() async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await _apiService.loadToken();
      final response = await _apiService.getWorkshopProfile();
      if (response['success'] && response['data'] != null) {
        final workshop = response['data']['workshop'] ?? response['data'] as Map<String, dynamic>?;
        if (workshop != null) {
          setState(() {
            _acceptsInstallment = workshop['accepts_installment'] ?? true;
            _maxInstallments = (workshop['max_installments'] is int)
                ? (workshop['max_installments'] as int).clamp(1, 24)
                : (int.tryParse(workshop['max_installments']?.toString() ?? '12') ?? 12).clamp(1, 24);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveInstallmentConfig() async {
    setState(() => _isSaving = true);
    try {
      final response = await _apiService.updateWorkshopProfile({
        'accepts_installment': _acceptsInstallment,
        'max_installments': _maxInstallments,
      });
      if (!mounted) return;
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Salvo'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mecaFeePercent = (AppConfig.mecaPlatformFee * 100).toStringAsFixed(0);
    final surface = isDark ? const Color(0xFF161616) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF1A1A);
    final muted = isDark ? const Color(0xFF737373) : const Color(0xFF737373);

    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text('Parcelamento'),
            backgroundColor: isDark ? const Color(0xFF0C0C0C) : Colors.white,
            foregroundColor: onSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card único: configuração
                      Material(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: isDark ? Border.all(color: const Color(0xFF262626), width: 1) : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Toggle
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Aceitar parcelamento',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Clientes podem pagar em até N parcelas no cartão',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: muted,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Switch.adaptive(
                                    value: _acceptsInstallment,
                                    onChanged: _isSaving
                                        ? null
                                        : (value) {
                                            setState(() => _acceptsInstallment = value);
                                            _saveInstallmentConfig();
                                          },
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                              if (_acceptsInstallment) ...[
                                const SizedBox(height: 28),
                                Text(
                                  'Máximo de parcelas',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$_maxInstallments',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'parcelas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: theme.colorScheme.primary,
                                    inactiveTrackColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                                    thumbColor: theme.colorScheme.primary,
                                    overlayColor: theme.colorScheme.primary.withOpacity(0.12),
                                    trackHeight: 6,
                                  ),
                                  child: Slider(
                                    value: _maxInstallments.toDouble(),
                                    min: 1,
                                    max: 24,
                                    divisions: 23,
                                    onChanged: _isSaving
                                        ? null
                                        : (value) {
                                            setState(() => _maxInstallments = value.round());
                                            _saveInstallmentConfig();
                                          },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('1', style: TextStyle(fontSize: 12, color: muted)),
                                    Text('24', style: TextStyle(fontSize: 12, color: muted)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'O MECA cuida do parcelamento. Você recebe o valor do serviço (descontada a taxa da plataforma).',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Nota sobre taxa — uma linha só, sem card pesado
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Taxa de $mecaFeePercent% sobre pagamentos; juros do parcelamento são do PagBank e pagos pelo cliente.',
                                style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
