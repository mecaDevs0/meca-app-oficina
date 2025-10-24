import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/theme_switch_widget.dart';

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
      
      // Carregar configuração atual da oficina
      final response = await _apiService.getWorkshopProfile();
      if (response['success']) {
        final workshop = response['data']['workshop'];
        setState(() {
          _acceptsInstallment = workshop['accepts_installment'] ?? true;
          _maxInstallments = workshop['max_installments'] ?? 12;
        });
      }
    } catch (e) {
      print('Erro ao carregar configuração: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInstallmentConfig() async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.updateWorkshopProfile({
        'accepts_installment': _acceptsInstallment,
        'max_installments': _maxInstallments,
      });
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuração de parcelamento atualizada!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.isDarkMode 
              ? const Color(0xFF0A0A0A) 
              : const Color(0xFFFAFAFA),
          appBar: AppBar(
            title: const Text('Parcelamento'),
            backgroundColor: themeService.isDarkMode 
                ? const Color(0xFF0A0A0A) 
                : const Color(0xFF00C977),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: const [
              ThemeSwitchButton(),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode 
                              ? const Color(0xFF1A1A1A) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.credit_card,
                                  color: Color(0xFF00C977),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Configuração de Parcelamento',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure como sua oficina aceita pagamentos parcelados',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeService.isDarkMode 
                                    ? const Color(0xFF8B8B8B) 
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Configuração principal
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode 
                              ? const Color(0xFF1A1A1A) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
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
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Aceitar Parcelamento',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Permitir que clientes paguem em parcelas',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: themeService.isDarkMode 
                                              ? const Color(0xFF8B8B8B) 
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _acceptsInstallment,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptsInstallment = value;
                                    });
                                    _saveInstallmentConfig();
                                  },
                                  activeColor: const Color(0xFF00C977),
                                ),
                              ],
                            ),
                            
                            if (_acceptsInstallment) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              const Text(
                                'Máximo de Parcelas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_maxInstallments parcelas',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00C977),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Slider(
                                value: _maxInstallments.toDouble(),
                                min: 1,
                                max: 24,
                                divisions: 23,
                                onChanged: (value) {
                                  setState(() {
                                    _maxInstallments = value.round();
                                  });
                                  _saveInstallmentConfig();
                                },
                                activeColor: const Color(0xFF00C977),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C977).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF00C977).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF00C977),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'MECA gerencia automaticamente a configuração de parcelamento. Você receberá o valor total menos a taxa de 5% da MECA.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: themeService.isDarkMode 
                                              ? const Color(0xFF8B8B8B) 
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Informações sobre taxas
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode 
                              ? const Color(0xFF1A1A1A) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  color: Color(0xFF00C977),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Taxa MECA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'A MECA cobra uma taxa de 5% sobre todos os pagamentos processados. Esta taxa é automaticamente deduzida do valor recebido pela oficina.',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeService.isDarkMode 
                                    ? const Color(0xFF8B8B8B) 
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeeInfo(
                                    'Valor do Serviço',
                                    'R\$ 100,00',
                                    themeService.isDarkMode,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFeeInfo(
                                    'Taxa MECA (5%)',
                                    'R\$ 5,00',
                                    themeService.isDarkMode,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFeeInfo(
                                    'Valor Líquido',
                                    'R\$ 95,00',
                                    themeService.isDarkMode,
                                    isHighlight: true,
                                  ),
                                ),
                              ],
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

  Widget _buildFeeInfo(String label, String value, bool isDarkMode, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight 
            ? const Color(0xFF00C977).withOpacity(0.1)
            : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(8),
        border: isHighlight 
            ? Border.all(color: const Color(0xFF00C977).withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF8B8B8B) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF00C977) : null,
            ),
          ),
        ],
      ),
    );
  }
}

