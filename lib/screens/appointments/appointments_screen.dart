import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    
    try {
      final response = await _apiService.getMyBookings();
      if (response['success']) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(response['data']['bookings'] ?? []);
        });
      }
    } catch (e) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Meus Agendamentos',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF00C977),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              tabs: const [
                Tab(text: 'Pendentes'),
                Tab(text: 'Confirmados'),
                Tab(text: 'Aguardando Cliente'),
                Tab(text: 'Histórico'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_getBookingsByStatus('pending')),
                _buildConfirmedBookingsList(), // Separar confirmados atuais e antigos
                _buildBookingsList(_getBookingsByStatus('pending_client')),
                _buildBookingsList(_getBookingsByStatus('completed')),
              ],
            ),
    );
  }

  List<Map<String, dynamic>> _getBookingsByStatus(String status) {
    if (status == 'pending') {
      return _bookings.where((b) {
        final s = (b['status'] ?? '').toLowerCase();
        return s == 'pending' || s == 'pendente' || s == 'pendente_oficina';
      }).toList();
    } else if (status == 'confirmed') {
      return _bookings.where((b) {
        final s = (b['status'] ?? '').toLowerCase();
        // IMPORTANTE: pendente_cliente NÃO deve aparecer em "Confirmados"
        // pendente_cliente é quando a oficina finalizou e está aguardando aprovação do cliente
        // Deve aparecer apenas em "Confirmados" os que estão realmente confirmados ou em andamento
        return s == 'confirmed' || s == 'confirmado' || 
               s == 'in_progress' || s == 'em_andamento' ||
               s == 'started';
        // REMOVIDO: s == 'pendente_cliente' - este status deve ter tratamento separado
      }).toList();
    } else if (status == 'pending_client') {
      // Nova aba específica para agendamentos aguardando aprovação do cliente
      return _bookings.where((b) {
        final s = (b['status'] ?? '').toLowerCase();
        return s == 'pendente_cliente';
      }).toList();
    } else {
      return _bookings.where((b) {
        final s = (b['status'] ?? '').toLowerCase();
        return s == 'completed' || s == 'concluido' || s == 'concluído' ||
               s == 'finalizado_aguardando_pagamento' || s == 'pago' || s == 'paid' ||
               s == 'cancelled' || s == 'cancelado';
      }).toList();
    }
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum agendamento encontrado',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00C977),
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index], isDarkMode);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          // Aguardar retorno da tela de detalhes e recarregar lista
          final result = await Navigator.pushNamed(
            context,
            '/booking-detail',
            arguments: booking,
          );
          // Recarregar lista quando voltar para garantir que o status está atualizado
          if (result == true || mounted) {
            await _loadBookings();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do agendamento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking['service_name'] ?? 'Serviço',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
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
              // Aviso especial para status aguardando aprovação
              if ((booking['status'] ?? '').toLowerCase() == 'pendente_cliente') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aguardando aprovação do cliente. O cliente precisa aprovar o orçamento antes do pagamento.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              
              // Cliente
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking['customer_name'] ?? 'Cliente',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Data e hora
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(booking['appointment_date']),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Veículo
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking['vehicle_info'] ?? 'Veículo não informado',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              if (booking['estimated_price'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'R\$ ${booking['estimated_price'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C977),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = (status ?? '').toLowerCase();
    switch (normalizedStatus) {
      case 'pending':
      case 'pendente':
      case 'pendente_oficina':
        return Colors.orange;
      case 'confirmed':
      case 'confirmado':
        return Colors.blue;
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
        return Colors.purple;
      case 'pendente_cliente':
        return Colors.amber.shade700;
      case 'finalizado_aguardando_pagamento':
        return Colors.blue.shade700;
      case 'pago':
      case 'paid':
      case 'completed':
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

  String _getStatusText(String status) {
    final normalizedStatus = (status ?? '').toLowerCase();
    switch (normalizedStatus) {
      case 'pending':
      case 'pendente':
      case 'pendente_oficina':
        return 'Pendente';
      case 'confirmed':
      case 'confirmado':
        return 'Confirmado';
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
        return 'Em Andamento';
      case 'pendente_cliente':
        return 'Aguardando Aprovação';
      case 'finalizado_aguardando_pagamento':
        return 'Aguardando Pagamento';
      case 'pago':
      case 'paid':
        return 'Pago';
      case 'completed':
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      default:
        return status ?? 'Desconhecido';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Data não informada';
    
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  // Separar agendamentos confirmados em atuais e antigos
  Widget _buildConfirmedBookingsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirmedBookings = _getBookingsByStatus('confirmed');
    
    // Separar por data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final currentBookings = <Map<String, dynamic>>[];
    final pastBookings = <Map<String, dynamic>>[];
    
    for (final booking in confirmedBookings) {
      try {
        final appointmentDate = booking['appointment_date'];
        if (appointmentDate != null) {
          final date = DateTime.parse(appointmentDate);
          final bookingDate = DateTime(date.year, date.month, date.day);
          
          if (bookingDate.isBefore(today)) {
            pastBookings.add(booking);
          } else {
            currentBookings.add(booking);
          }
        } else {
          // Se não tiver data, considerar como atual
          currentBookings.add(booking);
        }
      } catch (e) {
        // Se houver erro ao parsear data, considerar como atual
        currentBookings.add(booking);
      }
    }
    
    return RefreshIndicator(
      color: const Color(0xFF00C977),
      onRefresh: _loadBookings,
      child: CustomScrollView(
        slivers: [
          // Agendamentos atuais
          if (currentBookings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Agendamentos Confirmados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildBookingCard(currentBookings[index], isDarkMode),
                childCount: currentBookings.length,
              ),
            ),
          ],
          
          // Separador para agendamentos antigos
          if (pastBookings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              Colors.orange.shade900.withOpacity(0.3),
                              Colors.orange.shade800.withOpacity(0.2),
                            ]
                          : [
                              Colors.orange.shade50,
                              Colors.orange.shade100.withOpacity(0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.orange.shade700.withOpacity(0.3)
                          : Colors.orange.shade200.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade200.withOpacity(isDarkMode ? 0.1 : 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ícone com background circular
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade400.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Agendamentos Anteriores',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? Colors.orange.shade200
                                    : Colors.orange.shade900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Datas anteriores ao dia atual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.orange.shade300.withOpacity(0.8)
                                    : Colors.orange.shade700.withOpacity(0.8),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildBookingCard(pastBookings[index], isDarkMode),
                childCount: pastBookings.length,
              ),
            ),
          ],
          
          // Mensagem quando não há agendamentos
          if (currentBookings.isEmpty && pastBookings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 80,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nenhum agendamento confirmado encontrado',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}






