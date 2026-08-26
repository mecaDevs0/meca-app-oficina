import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class FinancialHistoryScreen extends StatefulWidget {
  const FinancialHistoryScreen({Key? key}) : super(key: key);

  @override
  State<FinancialHistoryScreen> createState() => _FinancialHistoryScreenState();
}

class _FinancialHistoryScreenState extends State<FinancialHistoryScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String _period = '30d';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      final now = DateTime.now();
      final days = _period == '7d' ? 7 : _period == '90d' ? 90 : 30;
      final startDate = now.subtract(Duration(days: days));
      final response = await _apiService.getFinancialSummary(
        startDate: startDate.toIso8601String().split('T').first,
        endDate: now.toIso8601String().split('T').first,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> raw = data?['recent_transactions'] is List
            ? data['recent_transactions'] as List
            : [];
        setState(() {
          _transactions =
              raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error']?.toString() ?? 'Erro ao carregar histórico';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao conectar com o servidor';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'R\$ 0,00';
    final num amount = value is String ? double.tryParse(value) ?? 0 : value;
    return _currencyFormat.format(amount);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return _dateFormat.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'paid':
      case 'confirmed':
        return const Color(0xFF00C977);
      case 'pending':
      case 'waiting_payment':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'canceled':
      case 'failed':
      case 'refunded':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'paid':
        return 'Pago';
      case 'pending':
        return 'Pendente';
      case 'cancelled':
      case 'canceled':
        return 'Cancelado';
      case 'refunded':
        return 'Estornado';
      default:
        return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
          appBar: AppBar(
            elevation: 0,
            backgroundColor:
                isDark ? const Color(0xFF1A1A1A) : Colors.white,
            title: Text(
              'Historico Financeiro',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF252940),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : const Color(0xFF252940),
            ),
          ),
          body: Column(
            children: [
              // Period filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildPeriodChip('7d', '7 dias', isDark),
                    const SizedBox(width: 8),
                    _buildPeriodChip('30d', '30 dias', isDark),
                    const SizedBox(width: 8),
                    _buildPeriodChip('90d', '90 dias', isDark),
                  ],
                ),
              ),
              // List
              Expanded(child: _buildBody(isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodChip(String value, String label, bool isDark) {
    final isSelected = _period == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF00C977),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black54),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          _period = value;
        });
        _loadTransactions();
      },
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C977)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00C977).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF00C977),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma transação encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF252940),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando clientes efetuarem pagamentos, eles aparecerao aqui.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00C977),
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) =>
            _buildTransactionCard(_transactions[index], isDark),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t, bool isDark) {
    final serviceName =
        t['service_name']?.toString() ?? t['customer_name']?.toString() ?? 'Transacao';
    final grossAmount = _formatCurrency(t['gross_amount'] ?? t['amount']);
    final netAmount = _formatCurrency(t['net_amount'] ?? t['split_amount']);
    final mecaFee = _formatCurrency(t['meca_fee_amount']);
    final gatewayFee =
        _formatCurrency(t['gateway_fee_amount'] ?? t['pagbank_fee_amount']);
    final method =
        (t['payment_method'] ?? '').toString().toUpperCase();
    final status = t['status']?.toString() ?? '';
    final date = _formatDate(t['created_at']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: service name + gross amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    color: Color(0xFF00C977),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF252940),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  grossAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF252940),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Badges row
            Row(
              children: [
                // Method badge
                _buildBadge(
                  method == 'PIX' ? 'PIX' : 'Cartao',
                  method == 'PIX'
                      ? const Color(0xFF00C977)
                      : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                // Status badge
                _buildBadge(_statusLabel(status), _statusColor(status)),
              ],
            ),
            const SizedBox(height: 12),
            // Financial breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildDetailColumn(
                      'Taxa MECA', mecaFee, isDark),
                  _buildDetailColumn(
                      'Tarifa financeira', gatewayFee, isDark),
                  _buildDetailColumn(
                      'Liquido', netAmount, isDark,
                      highlight: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, bool isDark,
      {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? const Color(0xFF00C977)
                  : (isDark ? Colors.white : const Color(0xFF252940)),
            ),
          ),
        ],
      ),
    );
  }
}
