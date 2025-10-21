import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';
import '../../widgets/theme_switch_widget.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({Key? key}) : super(key: key);

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _financialData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final response = await _apiService.getFinancialSummary();
      if (response['success']) {
        setState(() {
          _financialData = response['data'];
        });
      }
      
    } catch (e) {
      print('Erro ao carregar dados financeiros: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final bgColor = themeService.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
    final textColor = themeService.isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor = themeService.isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    final cardColor = themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Financeiro'),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          const ThemeSwitchButton(),
        ],
      ),
      body: _isLoading
          ? AnimationWidgets.buildLoadingWidget(message: 'Carregando dados financeiros...')
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financeiro',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acompanhe seu faturamento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  
                  // Financial Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildFinancialCard(
                            title: 'Faturamento Total',
                            amount: (_financialData?['total_revenue'] ?? 0).toDouble(),
                            icon: Icons.attach_money,
                            color: const Color(0xFF10B981),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          _buildFinancialCard(
                            title: 'Este Mês',
                            amount: (_financialData?['monthly_revenue'] ?? 0).toDouble(),
                            icon: Icons.calendar_month,
                            color: const Color(0xFF3B82F6),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          _buildFinancialCard(
                            title: 'Esta Semana',
                            amount: (_financialData?['weekly_revenue'] ?? 0).toDouble(),
                            icon: Icons.date_range,
                            color: const Color(0xFF8B5CF6),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Statistics
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 24),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estatísticas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatsGrid(cardColor, textColor, secondaryTextColor),
                        ],
                      ),
                    ),
                  ),
                  
                  // Recent Transactions
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 24),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transações Recentes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: _buildTransactionsList(cardColor, textColor, secondaryTextColor),
                  ),
                  
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 24),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${(amount / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Color cardColor, Color textColor, Color secondaryTextColor) {
    final stats = [
      {
        'title': 'Serviços Realizados',
        'value': _financialData?['completed_services'] ?? 0,
        'icon': Icons.build,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Agendamentos',
        'value': _financialData?['total_bookings'] ?? 0,
        'icon': Icons.calendar_today,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Ticket Médio',
        'value': _financialData?['average_ticket'] ?? 0,
        'icon': Icons.trending_up,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Avaliação',
        'value': _financialData?['average_rating'] ?? 0,
        'icon': Icons.star,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'] == 'Ticket Médio' || stat['title'] == 'Avaliação'
                    ? stat['value'].toString()
                    : stat['value'].toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(Color cardColor, Color textColor, Color secondaryTextColor) {
    final transactions = _financialData?['recent_transactions'] as List<dynamic>? ?? [];
    
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação recente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas transações aparecerão aqui',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: index < transactions.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: secondaryTextColor.withOpacity(0.3),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['description'] ?? 'Serviço',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        _formatDate(transaction['date']),
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${(transaction['amount'] / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Data não informada';
    
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}

              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Data não informada';
    
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
