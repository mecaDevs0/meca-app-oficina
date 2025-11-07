import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class PagBankConfigScreen extends StatefulWidget {
  const PagBankConfigScreen({Key? key}) : super(key: key);

  @override
  State<PagBankConfigScreen> createState() => _PagBankConfigScreenState();
}

class _PagBankConfigScreenState extends State<PagBankConfigScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _bankData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getBankAccount();
      if (!mounted) return;
      setState(() {
        _bankData = response['success'] ? response['data'] as Map<String, dynamic>? : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados bancários: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _redirectToBankEdit() async {
    await Navigator.pushNamed(context, '/config/bank');
    if (mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final background = ThemeService.getBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryText = ThemeService.getSecondaryTextColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('Método de pagamento', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagamentos via PagBank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Os repasses são realizados automaticamente usando sua conta bancária cadastrada.',
                      style: TextStyle(color: secondaryText, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    _buildBankInfoCard(cardColor, textColor, secondaryText),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _redirectToBankEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar dados bancários'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Assim que você salva os dados bancários, a conta PagBank é sincronizada automaticamente para receber os pagamentos.',
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBankInfoCard(Color cardColor, Color textColor, Color secondaryText) {
    final data = _bankData ?? const {};
    final hasBankData = (data['bank_code'] ?? '').toString().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: secondaryText.withOpacity(0.2), width: 1.1),
      ),
      child: hasBankData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Banco', _formatBank(data), textColor, secondaryText),
                _buildInfoRow('Agência', data['agency'] ?? data['agency_number'] ?? '-', textColor, secondaryText),
                _buildInfoRow('Conta', data['account'] ?? data['account_number'] ?? '-', textColor, secondaryText),
                _buildInfoRow('Tipo', _translateAccountType(data['account_type']), textColor, secondaryText),
                _buildInfoRow('Titular', data['account_holder_name'] ?? '-', textColor, secondaryText),
                if ((data['account_holder_document'] ?? '').toString().isNotEmpty)
                  _buildInfoRow('Documento', data['account_holder_document'], textColor, secondaryText),
                if ((data['pix_key'] ?? '').toString().isNotEmpty)
                  _buildInfoRow('Chave Pix', data['pix_key'], textColor, secondaryText),
                if ((data['pix_key_type'] ?? '').toString().isNotEmpty)
                  _buildInfoRow('Tipo da chave', _translatePixType(data['pix_key_type']), textColor, secondaryText),
                const SizedBox(height: 12),
                Divider(color: secondaryText.withOpacity(0.2)),
                const SizedBox(height: 12),
                _buildAddressSection(data, textColor, secondaryText),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhuma conta bancária configurada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cadastre os dados bancários para começar a receber pagamentos pelo PagBank.',
                  style: TextStyle(color: secondaryText),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _redirectToBankEdit,
                  icon: const Icon(Icons.add_outlined),
                  label: const Text('Adicionar dados bancários'),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, Color primary, Color secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: secondary),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: TextStyle(fontWeight: FontWeight.w600, color: primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> data, Color primary, Color secondary) {
    final cep = data['bank_cep'];
    final street = data['bank_street'];
    final number = data['bank_number'];
    final neighborhood = data['bank_neighborhood'];
    final city = data['bank_city'];
    final state = data['bank_state'];
    final complement = data['bank_complement'];

    final hasAddress = [street, number, neighborhood, city, state].any((value) => (value ?? '').toString().isNotEmpty);

    if (!hasAddress) {
      return Text('Sem endereço vinculado', style: TextStyle(color: secondary));
    }

    final buffer = StringBuffer();
    if ((street ?? '').toString().isNotEmpty) buffer.write(street);
    if ((number ?? '').toString().isNotEmpty) buffer.write(', $number');
    if ((neighborhood ?? '').toString().isNotEmpty) buffer.write(' · $neighborhood');
    if ((city ?? '').toString().isNotEmpty) buffer.write(' - $city');
    if ((state ?? '').toString().isNotEmpty) buffer.write('/$state');
    if ((complement ?? '').toString().isNotEmpty) buffer.write(' ($complement)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Endereço bancário', style: TextStyle(fontWeight: FontWeight.w500, color: secondary)),
        const SizedBox(height: 6),
        Text(
          buffer.toString(),
          style: TextStyle(fontWeight: FontWeight.w600, color: primary),
        ),
        if ((cep ?? '').toString().isNotEmpty)
          Text('CEP: $cep', style: TextStyle(color: secondary)),
      ],
    );
  }

  String _formatBank(Map<String, dynamic> data) {
    final code = (data['bank_code'] ?? '').toString();
    final name = (data['bank_name'] ?? '').toString();
    if (code.isEmpty && name.isEmpty) return '-';
    if (name.isEmpty) return code;
    if (code.isEmpty) return name;
    return '$code · $name';
  }

  String _translateAccountType(dynamic value) {
    switch (value?.toString()) {
      case 'savings':
      case 'poupanca':
        return 'Poupança';
      default:
        return 'Conta corrente';
    }
  }

  String _translatePixType(dynamic value) {
    switch (value?.toString()) {
      case 'cpf':
        return 'CPF';
      case 'cnpj':
        return 'CNPJ';
      case 'email':
        return 'E-mail';
      case 'phone':
      case 'telefone':
        return 'Telefone';
      case 'aleatorio':
        return 'Chave aleatória';
      default:
        return 'Outro';
    }
  }
}



























