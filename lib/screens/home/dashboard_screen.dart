import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  
  // Flags de configuração
  bool _needsBankSetup = false;
  bool _needsScheduleSetup = false;
  bool _needsServicesSetup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final profileResult = await _apiService.getProfile();
    final bookingsResult = await _apiService.getMyBookings();
    
    if (profileResult['success']) {
      _profile = profileResult['data'];
      _needsBankSetup = _profile?['bank_details_valid'] != true;
      _needsScheduleSetup = _profile?['schedule_valid'] != true;
      _needsServicesSetup = _profile?['services_valid'] != true;
    }
    
    if (bookingsResult['success']) {
      _bookings = (bookingsResult['data']['bookings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }
    
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pendingBookings = _bookings.where((b) => b['status'] == 'pending').toList();
    final confirmedBookings = _bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'in_progress').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
          : RefreshIndicator(
              color: const Color(0xFF00C977),
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bem-vindo de volta!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _profile?['name'] ?? 'Oficina',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF00C977),
                            ),
          ),
        ],
      ),
                    ),
                  ),

                  // Banners de Configuração Pendente
                  if (_needsBankSetup || _needsScheduleSetup || _needsServicesSetup)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
        children: [
                                Icon(Icons.warning_amber, color: Color(0xFFDBA800)),
                                SizedBox(width: 10),
                                Text(
                                  'Configurações Pendentes',
            style: TextStyle(
                                    fontSize: 16,
              fontWeight: FontWeight.bold,
                                    color: Color(0xFF252940),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            if (_needsBankSetup)
                              _buildSetupItem(
                                icon: Icons.account_balance,
                                title: 'Conta bancária',
                                subtitle: 'Configure para receber pagamentos',
                                onTap: () => Navigator.pushNamed(context, '/bank-account'),
                              ),
                            if (_needsScheduleSetup)
                              _buildSetupItem(
                                icon: Icons.schedule,
                                title: 'Configurar agenda',
                                subtitle: 'Defina seus horários de atendimento',
                                onTap: () => Navigator.pushNamed(context, '/config-schedule'),
                              ),
                            if (_needsServicesSetup)
                              _buildSetupItem(
                                icon: Icons.build,
                                title: 'Serviços',
                                subtitle: 'Adicione os serviços que você oferece',
                                onTap: () => Navigator.pushNamed(context, '/services'),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Tabs
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF00C977),
                        unselectedLabelColor: Colors.grey,
                        indicator: BoxDecoration(
                          color: const Color(0xFF00C977).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pending_actions, size: 18),
                                const SizedBox(width: 5),
                                Text('Próximos (${pendingBookings.length + confirmedBookings.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.history, size: 18),
                                const SizedBox(width: 5),
                                const Text('Histórico'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab Content
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNextBookings(pendingBookings + confirmedBookings),
                        _buildHistoricBookings(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSetupItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBA800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFDBA800)),
            ),
            const SizedBox(width: 15),
            Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                    title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                      color: Color(0xFF252940),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBookings(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'Nenhum agendamento próximo',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildHistoricBookings() {
    final historicBookings = _bookings.where(
      (b) => b['status'] == 'completed' || b['status'] == 'cancelled'
    ).toList();

    if (historicBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'Nenhum histórico disponível',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historicBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(historicBookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final statusConfig = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/booking-detail',
              arguments: booking,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${booking['id']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusConfig['color'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusConfig['label'],
                        style: TextStyle(
                          color: statusConfig['textColor'],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      booking['scheduled_date'] != null
                          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(booking['scheduled_date']))
                          : 'Data não definida',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 15),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      booking['scheduled_time'] ?? '00:00',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      booking['customer_name'] ?? 'Cliente',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                    Text(
                      '${booking['vehicle_brand']} ${booking['vehicle_model']} - ${booking['vehicle_plate']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    final configs = {
      'pending': {
        'label': 'Pendente',
        'color': const Color(0xFFFCF4E5),
        'textColor': const Color(0xFFDBA800),
      },
      'confirmed': {
        'label': 'Confirmado',
        'color': const Color(0xFFE3EDFA),
        'textColor': const Color(0xFF7896D8),
      },
      'in_progress': {
        'label': 'Em Andamento',
        'color': const Color(0xFFE8FFEE),
        'textColor': const Color(0xFF2FD65C),
      },
      'completed': {
        'label': 'Concluído',
        'color': const Color(0xFFE8FFEE),
        'textColor': const Color(0xFF2FD65C),
      },
    };
    
    return configs[status] ?? configs['pending']!;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}