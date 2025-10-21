import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';
import '../../widgets/theme_switch_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _workshopData;
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _historyBookings = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWorkshopData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkshopData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final workshopResponse = await _apiService.getWorkshopDashboard();
      if (workshopResponse['success']) {
        setState(() {
          _workshopData = workshopResponse['data'];
        });
      }

      final bookingsResponse = await _apiService.getMyBookings();
      if (bookingsResponse['success']) {
        final data = bookingsResponse['data'];
        final bookingsList = data is Map ? (data['bookings'] ?? []) : data ?? [];
        final bookings = List<Map<String, dynamic>>.from(bookingsList);
        setState(() {
          _upcomingBookings = bookings.where((b) => b['status'] == 'pendente_oficina' || b['status'] == 'confirmado').toList();
          _historyBookings = bookings.where((b) => b['status'] == 'concluido' || b['status'] == 'cancelado').toList();
        });
      }
      
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _isDataBankInvalid {
    // Verifica se dados_bancarios está preenchido
    final bankData = _workshopData?['dados_bancarios'];
    return bankData == null || bankData['bank_name'] == null;
  }

  bool get _isAgendaInvalid {
    // Verifica se horario_funcionamento tem algum dia configurado
    final schedule = _workshopData?['horario_funcionamento'];
    if (schedule == null) return true;
    
    // Verifica se tem pelo menos um dia com is_open = true
    for (var day in schedule.values) {
      if (day['is_open'] == true) return false;
    }
    return true;
  }

  bool get _isServiceInvalid {
    // Verifica se tem serviços ativos
    final services = _workshopData?['services'];
    return services == null || (services as List).isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? AnimationWidgets.buildLoadingWidget(message: 'Carregando dados da oficina...')
          : RefreshIndicator(
              onRefresh: _loadWorkshopData,
              color: const Color(0xFF00C977),
              backgroundColor: cardColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header futurista
                  SliverAppBar(
                    expandedHeight: 140,
                    floating: false,
                    pinned: true,
                    backgroundColor: bgColor,
                    elevation: 0,
                    actions: [
                      const ThemeSwitchButton(),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark 
                                ? [
                                    const Color(0xFF0A0A0A),
                                    const Color(0xFF1A1A1A),
                                  ]
                                : [
                                    const Color(0xFFF5F7FA),
                                    const Color(0xFFE5E7EB),
                                  ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Logo MECA futurista
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF00C977),
                                            Color(0xFF00A86B),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00C977).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'assets/images/meca_logo.png',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bem-vindo de volta!',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Oficina MECA',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryTextColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          
                          // Quick stats
                          _buildQuickStats(),
                          const SizedBox(height: 32),
                          
                          // Configuration cards
                          if (_isDataBankInvalid || _isAgendaInvalid || _isServiceInvalid) ...[
                            Text(
                              'Configuração Necessária',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isDataBankInvalid)
                              _buildConfigCard(
                                icon: Icons.account_balance,
                                title: 'Conta Bancária',
                                subtitle: 'Configure sua conta para receber pagamentos',
                                onTap: () async {
                                  final result = await Navigator.pushNamed(context, '/config/bank');
                                  if (result == true) {
                                    _loadWorkshopData(); // Recarregar dados
                                  }
                                },
                                color: const Color(0xFF3B82F6),
                              ),
                            if (_isAgendaInvalid)
                              _buildConfigCard(
                                icon: Icons.schedule,
                                title: 'Configurar Agenda',
                                subtitle: 'Defina seus horários de atendimento',
                                onTap: () async {
                                  final result = await Navigator.pushNamed(context, '/config/agenda');
                                  if (result == true) {
                                    _loadWorkshopData(); // Recarregar dados
                                  }
                                },
                                color: const Color(0xFF8B5CF6),
                              ),
                            if (_isServiceInvalid)
                              _buildConfigCard(
                                icon: Icons.build,
                                title: 'Serviços',
                                subtitle: 'Selecione os serviços que você oferece',
                                onTap: () async {
                                  final result = await Navigator.pushNamed(context, '/config/services');
                                  if (result == true) {
                                    _loadWorkshopData(); // Recarregar dados
                                  }
                                },
                                color: const Color(0xFFF59E0B),
                              ),
                            const SizedBox(height: 32),
                          ],
                          
                          // Appointments section
                          Text(
                            'Agendamentos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Tab bar
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ThemeService.getBorderColor(isDark),
                                width: 1,
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: const Color(0xFF00C977),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: secondaryTextColor,
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Próximos (${_upcomingBookings.length})'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.history, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Histórico (${_historyBookings.length})'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Tab content
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildUpcomingTab(),
                                _buildHistoryTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStats() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_today,
              value: '${_upcomingBookings.length}',
              label: 'Próximos',
              color: const Color(0xFF00C977),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: borderColor,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.history,
              value: '${_historyBookings.length}',
              label: 'Histórico',
              color: const Color(0xFF8B8B8B),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: borderColor,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.build,
              value: '${_workshopData?['services']?.length ?? 0}',
              label: 'Serviços',
              color: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDark ? 0.1 : 0.15),
                color.withOpacity(isDark ? 0.05 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.2 : 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    if (_upcomingBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00C977).withOpacity(0.1),
                      const Color(0xFF00C977).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 60,
                  color: Color(0xFF00C977),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum agendamento próximo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Novos agendamentos aparecerão aqui\nquando clientes solicitarem seus serviços',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: _upcomingBookings.length,
      itemBuilder: (context, index) {
        final booking = _upcomingBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildHistoryTab() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    if (_historyBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      secondaryTextColor.withOpacity(0.1),
                      secondaryTextColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.history,
                  size: 60,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum histórico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seus agendamentos concluídos\naparecerão aqui',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: _historyBookings.length,
      itemBuilder: (context, index) {
        final booking = _historyBookings[index];
        return _buildBookingCard(booking, isHistory: true);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {bool isHistory = false}) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    final status = booking['status'] as String?;
    final customerName = booking['customer_name'] as String? ?? 'Cliente';
    final serviceName = booking['service_name'] as String? ?? 'Serviço';
    final appointmentDate = booking['appointment_date'] as String?;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'pendente_oficina':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending;
        break;
      case 'confirmado':
        statusColor = const Color(0xFF00C977);
        statusIcon = Icons.check_circle;
        break;
      case 'concluido':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.done_all;
        break;
      case 'cancelado':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = secondaryTextColor;
        statusIcon = Icons.help;
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      serviceName,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isHistory && status == 'pendente_oficina')
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/booking-detail',
                    arguments: booking,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (appointmentDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(appointmentDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (appointmentDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(appointmentDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
