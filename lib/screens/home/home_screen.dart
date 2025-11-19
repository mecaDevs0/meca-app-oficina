import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../utils/page_transitions.dart';
import '../config/agenda_config_screen.dart';
import '../config/bank_account_screen.dart' show BankAccountScreen;
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
        
      } else {
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
        final pendingCount = bookings.where((b) {
          final status = (b['status'] ?? '').toString().toLowerCase();
          return status == 'pending' ||
              status == 'pendente_oficina' ||
              status == 'pending_oficina';
        }).length;

        final upcoming = bookings.where((b) {
          final status = (b['status'] ?? '').toString().toLowerCase();
          return status == 'pending' ||
              status == 'pendente_oficina' ||
              status == 'confirmed' ||
              status == 'confirmado' ||
              status == 'started' ||
              status == 'in_progress' ||
              status == 'em_andamento';
        }).toList()
          ..sort(
            (a, b) => (a['sort_timestamp'] ?? 0).compareTo(b['sort_timestamp'] ?? 0),
          );

        final history = bookings.where((b) {
          final status = (b['status'] ?? '').toString().toLowerCase();
          return status == 'completed' ||
              status == 'finished' ||
              status == 'concluido' ||
              status == 'cancelled';
        }).toList()
          ..sort(
            (a, b) => (b['sort_timestamp'] ?? 0).compareTo(a['sort_timestamp'] ?? 0),
          );

        setState(() {
          _upcomingBookings = upcoming;
          _historyBookings = history;
        });
        if (mounted) {
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.setPendingBookingsCount(pendingCount, resetBadge: pendingCount == 0);
        }
      }
      
    } catch (e) {
      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setPendingBookingsCount(0, resetBadge: true);
      }
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
    final customerName = (booking['customer_name'] ?? 'Cliente MECA').toString();
    final vehicleLabel = (booking['vehicle_display'] ??
            '${booking['vehicle_brand'] ?? ''} ${booking['vehicle_model'] ?? ''}')
        .toString()
        .trim();
    final serviceName = (booking['service_name'] ?? 'Serviço').toString();
    final notes = (booking['customer_notes'] ?? '').toString().trim();
    final attachments = booking['customer_uploads'] is List
        ? (booking['customer_uploads'] as List).length
        : 0;
    final appointment = _parseDate(booking['appointment_date'] ?? booking['scheduled_date']);
    final dateLabel =
        appointment != null ? DateFormat('dd/MM/yyyy').format(appointment) : 'Data não definida';
    final timeLabel =
        appointment != null ? DateFormat('HH:mm').format(appointment) : '--:--';
    final initials = customerName.trim().isNotEmpty
        ? customerName.trim().substring(0, 1).toUpperCase()
        : 'C';
    final secondaryText = isDark ? Colors.white60 : const Color(0xFF6B7280);

    final boxDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF111827), const Color(0xFF0F172A)]
            : [Colors.white, Colors.white],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E7EB),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.45)
              : const Color(0xFF00C977).withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return InkWell(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/booking-detail',
          arguments: booking,
        );
        if (result == true && mounted) {
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: boxDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C977), Color(0xFF0FBF9F)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleLabel.isNotEmpty
                            ? '$customerName · $vehicleLabel'
                            : customerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.05 : 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildIconChip(
                  icon: Icons.calendar_today_outlined,
                  label: dateLabel,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildIconChip(
                  icon: Icons.access_time_outlined,
                  label: '$timeLabel h',
                  isDark: isDark,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status'])
                        .withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(20),
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
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (attachments > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    attachments == 1
                        ? '1 foto enviada'
                        : '$attachments fotos enviadas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: false);
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        return DateTime.parse(trimmed).toLocal();
      } catch (_) {
        try {
          return DateTime.parse('${trimmed}Z').toLocal();
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    final normalized = status.toString().toLowerCase().trim();
    
    switch (normalized) {
      case 'pending':
      case 'pendente_oficina':
      case 'pendente':
        return Colors.orange;
      case 'confirmed':
      case 'confirmado':
        return const Color(0xFF00C977);
      case 'started':
      case 'in_progress':
      case 'em_andamento':
        return const Color(0xFF3B82F6);
      case 'pendente_cliente':
        return Colors.amber;
      case 'finalizado_aguardando_pagamento':
      case 'finalizado_cliente':
        return Colors.blue;
      case 'pago':
      case 'paid':
      case 'approved':
        return Colors.green;
      case 'completed':
      case 'finished':
      case 'concluido':
      case 'concluído':
        return Colors.green;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Desconhecido';
    
    final normalized = status.toString().toLowerCase().trim();
    
    switch (normalized) {
      case 'pending':
      case 'pendente_oficina':
      case 'pendente':
        return 'Pendente';
      case 'confirmed':
      case 'confirmado':
        return 'Confirmado';
      case 'started':
      case 'in_progress':
      case 'em_andamento':
        return 'Em Andamento';
      case 'pendente_cliente':
        return 'Aguardando Cliente';
      case 'finalizado_aguardando_pagamento':
      case 'finalizado_cliente':
        return 'Aguardando Pagamento';
      case 'pago':
      case 'paid':
      case 'approved':
        return 'Pago';
      case 'completed':
      case 'finished':
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      default:
        // Debug para identificar status não mapeados
        debugPrint('⚠️ [Home] Status não mapeado: $status (normalized: $normalized)');
        return 'Desconhecido';
    }
  }

}

