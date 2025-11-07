import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../utils/page_transitions.dart';
import '../config/bank_account_screen.dart';
import '../config/agenda_config_screen.dart';
import '../config/services_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _showUpcoming = true; // Controla qual aba está selecionada
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _historyBookings = [];
  Map<String, dynamic>? _workshopData;
  List<Map<String, dynamic>> _services = [];
  final ApiService _apiService = ApiService();
  
  // Variáveis para controle de configuração
  bool _isDataBankInvalid = false;
  bool _isAgendaInvalid = false;
  bool _isServiceInvalid = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Carregar perfil da oficina
      final profileResponse = await _apiService.getProfile();
      if (profileResponse['success']) {
        setState(() {
          _workshopData = profileResponse['data'];
        });
      }
      
      // Buscar dados bancários diretamente da API
      final bankResponse = await _apiService.getBankAccount();
      bool hasBankData = false;
      if (bankResponse['success'] && bankResponse['data'] != null) {
        final bankData = bankResponse['data'];
        final bankCode = bankData['bank_code']?.toString().trim() ?? '';
        final agency = bankData['agency']?.toString().trim() ?? '';
        final account = bankData['account']?.toString().trim() ?? '';
        
        hasBankData = bankCode.isNotEmpty && agency.isNotEmpty && account.isNotEmpty;
        
        print('DEBUG: Validação dados bancários - bank_code: "$bankCode", agency: "$agency", account: "$account"');
        print('DEBUG: hasBankData: $hasBankData');
      } else {
        print('DEBUG: Erro ao buscar dados bancários: ${bankResponse['error']}');
      }
      
      // Buscar agenda diretamente da API
      final scheduleResponse = await _apiService.getSchedule();
      bool hasSchedule = false;
      if (scheduleResponse['success'] && scheduleResponse['data'] != null) {
        final scheduleData = scheduleResponse['data'];
        // Verificar se tem pelo menos um dia configurado
        if (scheduleData is Map) {
          hasSchedule = scheduleData.entries.any((entry) {
            final dayData = entry.value;
            if (dayData is Map) {
              return dayData['is_open'] == true;
            }
            return false;
          });
        }
      }
      
      // Buscar serviços da oficina diretamente da API
      final servicesResponse = await _apiService.getMyServices();
      bool hasServices = false;
      if (servicesResponse['success'] && servicesResponse['data'] != null) {
        final servicesData = servicesResponse['data'];
        final servicesList = servicesData is Map 
            ? (servicesData['services'] ?? [])
            : (servicesData is List ? servicesData : []);
        hasServices = servicesList.isNotEmpty;
        setState(() {
          _services = List<Map<String, dynamic>>.from(servicesList);
        });
      }
      
      // Atualizar flags de validação
      setState(() {
        _isDataBankInvalid = !hasBankData;
        _isAgendaInvalid = !hasSchedule;
        _isServiceInvalid = !hasServices;
      });
      
      // Carregar agendamentos
      final bookingsResponse = await _apiService.getMyBookings();
      if (bookingsResponse['success']) {
        final data = bookingsResponse['data'];
        final bookingsList = data is Map ? (data['bookings'] ?? []) : data ?? [];
        final bookings = List<Map<String, dynamic>>.from(bookingsList);
        setState(() {
          _upcomingBookings = bookings.where((b) => 
            b['status'] == 'pending' || 
            b['status'] == 'confirmed' || 
            b['status'] == 'started' ||
            b['status'] == 'pendente_oficina'
          ).toList();
          _historyBookings = bookings.where((b) => 
            b['status'] == 'completed' || 
            b['status'] == 'cancelled' || 
            b['status'] == 'finished' ||
            b['status'] == 'concluido'
          ).toList();
        });
      }
      
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF00C977) : const Color(0xFF00C977),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header com logo
                            _buildHeader(isDark, constraints.maxWidth),
                            
                            const SizedBox(height: 24),
                            
                            // Componente de 3 colunas (estatísticas)
                            _buildStatsCard(isDark),
                            
                            const SizedBox(height: 24),
                            
                            // Componente de configuração necessária
                            if (_isDataBankInvalid || _isAgendaInvalid || _isServiceInvalid)
                              _buildConfigNeededSection(isDark),
                            
                            if (_isDataBankInvalid || _isAgendaInvalid || _isServiceInvalid)
                              const SizedBox(height: 24),
                            
                            // Componente de agendamentos
                            _buildAppointmentsSection(isDark),
                          ],
                          ),
                        );
                      },
                    ),
                  ),
            ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, double maxWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo MECA
          SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(
              'assets/logos/icone_verde.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'MECA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _workshopData?['name'] ?? 'Oficina MECA',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Coluna 1: Próximos
          Expanded(
            child: _buildStatColumn(
              icon: Icons.calendar_today_outlined,
              value: '${_upcomingBookings.length}',
              label: 'Próximos',
              color: const Color(0xFF00C977),
              isDark: isDark,
            ),
          ),
          // Coluna 2: Histórico
          Expanded(
            child: _buildStatColumn(
              icon: Icons.history_outlined,
              value: '${_historyBookings.length}',
              label: 'Histórico',
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              isDark: isDark,
            ),
          ),
          // Coluna 3: Serviços
          Expanded(
            child: _buildStatColumn(
              icon: Icons.build_outlined,
              value: '${_services.length}',
              label: 'Serviços',
              color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigNeededSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuração Necessária',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (_isDataBankInvalid)
          _buildConfigCard(
            title: 'Conta Bancária',
            description: 'Configure sua conta para receber pagamentos',
            icon: Icons.account_balance_outlined,
            iconColor: const Color(0xFF3B82F6),
            bgColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideFromRight(const BankAccountScreen()),
              );
              // Recarregar dados se salvou com sucesso
              if (result == true) {
                _loadData();
              }
            },
            isDark: isDark,
          ),
        if (_isDataBankInvalid) const SizedBox(height: 12),
        if (_isAgendaInvalid)
          _buildConfigCard(
            title: 'Configurar Agenda',
            description: 'Defina seus horários de atendimento',
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF9333EA),
            bgColor: isDark ? const Color(0xFF3D1F5D) : const Color(0xFFF3E8FF),
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideFromRight(const AgendaConfigScreen()),
              );
              // Recarregar dados se salvou com sucesso
              if (result == true) {
                _loadData();
              }
            },
            isDark: isDark,
          ),
        if (_isAgendaInvalid) const SizedBox(height: 12),
        if (_isServiceInvalid)
          _buildConfigCard(
            title: 'Serviços',
            description: 'Selecione os serviços que você oferece',
            icon: Icons.build_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: isDark ? const Color(0xFF5D3A1F) : const Color(0xFFFEF3C7),
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideFromRight(ServicesConfigScreen()),
              );
              // Recarregar dados se salvou com sucesso
              if (result == true) {
                _loadData();
              }
            },
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildConfigCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agendamentos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Segmented control para Próximos/Histórico
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  label: 'Próximos (${_upcomingBookings.length})',
                  icon: Icons.calendar_today_outlined,
                  isSelected: _showUpcoming,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _showUpcoming = true;
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  label: 'Histórico (${_historyBookings.length})',
                  icon: Icons.history_outlined,
                  isSelected: !_showUpcoming,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _showUpcoming = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lista de agendamentos (próximos ou histórico) com animação
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: _showUpcoming && _upcomingBookings.isEmpty
              ? Container(
                  key: const ValueKey('empty-upcoming'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum agendamento próximo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seus agendamentos aparecerão aqui',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : !_showUpcoming && _historyBookings.isEmpty
                  ? Container(
                      key: const ValueKey('empty-history'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum histórico',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seus agendamentos concluídos aparecerão aqui',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: ValueKey(_showUpcoming ? 'upcoming-list' : 'history-list'),
                      children: [
                        ...(_showUpcoming ? _upcomingBookings : _historyBookings)
                            .take(5)
                            .map((booking) => _buildBookingCard(booking, isDark)),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00C977) : const Color(0xFF00C977))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF00C977),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['service_name'] ?? 'Serviço',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking['customer_name'] ?? 'Cliente',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (booking['appointment_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(booking['appointment_date']),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(booking['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(booking['status']),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(booking['status']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
      case 'pendente_oficina':
        return Colors.orange;
      case 'confirmed':
        return const Color(0xFF00C977);
      case 'started':
        return const Color(0xFF3B82F6);
      case 'completed':
      case 'finished':
      case 'concluido':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
      case 'pendente_oficina':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'started':
        return 'Em Andamento';
      case 'completed':
      case 'finished':
      case 'concluido':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }
}

