import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class PagBankConfigScreen extends StatefulWidget {
  const PagBankConfigScreen({super.key});

  @override
  State<PagBankConfigScreen> createState() => _PagBankConfigScreenState();
}

class _PagBankConfigScreenState extends State<PagBankConfigScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isConnecting = false;
  Map<String, dynamic>? _pagbankData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPagBankData();
  }

  Future<void> _loadPagBankData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getPagBankAccount();
      if (response['success'] == true) {
        setState(() => _pagbankData = response['data'] as Map<String, dynamic>?);
      } else {
        setState(() => _errorMessage = response['error']?.toString() ?? 'Erro ao carregar dados PagBank.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao carregar dados PagBank: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleConnectPagBank() async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);
    String? feedback;

    try {
      final response = await _apiService.startPagBankConnect();
      if (response['success'] == true) {
        final data = Map<String, dynamic>.from(response['data'] ?? {});
        final authorizeUrl = (data['authorize_url'] ?? data['url'] ?? data['redirect_url'])?.toString();
        final expiresIn = data['expires_in_minutes'];

        if (authorizeUrl != null && authorizeUrl.isNotEmpty) {
          final uri = Uri.parse(authorizeUrl);
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) {
            feedback = 'Não foi possível abrir a página de autorização do PagBank.';
          } else {
            feedback = expiresIn != null
                ? 'Autorização PagBank aberta. Conclua o processo em até $expiresIn minutos.'
                : 'Autorização PagBank aberta em uma nova janela.';
          }
        } else {
          feedback = 'A API não retornou a URL de autorização do PagBank.';
        }
      } else {
        feedback = response['error']?.toString() ?? 'Falha ao iniciar o fluxo PagBank Connect.';
      }
    } catch (e) {
      feedback = 'Erro ao iniciar PagBank Connect: $e';
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
        if (feedback != null && feedback.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
        }
        await _loadPagBankData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final backgroundColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF5F7FA);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryText = ThemeService.getSecondaryTextColor(isDark);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'PagBank',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadPagBankData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    children: [
                      _buildStatusCard(isDark, textColor, secondaryText),
                      const SizedBox(height: 24),
                      _buildInfoCard(isDark, textColor, secondaryText),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(_pagbankData == null ? Icons.link : Icons.refresh),
                        label: Text(_pagbankData == null ? 'Conectar PagBank' : 'Reautorizar PagBank'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isConnecting ? null : _handleConnectPagBank,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatusCard(bool isDark, Color textColor, Color secondaryText) {
    final status = (_pagbankData?['status'] ?? 'pending').toString();
    final statusLabel = _statusLabel(status);
    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;

    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.3)
        : const Color.fromRGBO(158, 158, 158, 0.2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 201, 119, 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00C977)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status da conta PagBank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, Color textColor, Color secondaryText) {
    final accountInfo = [
      MapEntry('Nome', _pagbankData?['account_name']),
      MapEntry('CPF/CNPJ', _pagbankData?['account_document']),
      MapEntry('Banco', _pagbankData?['bank_name']),
      MapEntry('Agência', _pagbankData?['agency']),
      MapEntry('Conta', _pagbankData?['account']),
      MapEntry('Pix', _pagbankData?['pix_key']),
      MapEntry('Atualizado em', _pagbankData?['updated_at']),
    ];

    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;

    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.3)
        : const Color.fromRGBO(158, 158, 158, 0.15);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_pagbankData == null)
            Text(
              'Conecte sua conta PagBank para receber pagamentos automaticamente.',
              style: TextStyle(color: secondaryText),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: accountInfo
                  .where((entry) => entry.value != null && '${entry.value}'.isNotEmpty)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(color: secondaryText, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.value}',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return 'Conta conectada';
      case 'pending':
        return 'Conexão pendente';
      case 'rejected':
      case 'inactive':
        return 'Conexão inativa';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
      case 'inactive':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

