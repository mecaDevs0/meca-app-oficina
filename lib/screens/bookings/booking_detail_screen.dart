import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  
  const BookingDetailScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = false;

  Future<void> _acceptBooking() async {
    setState(() => _loading = true);

    final result = await _apiService.confirmBooking(widget.booking['id']);

    if (result['success']) {
      print('Agendamento aceito com sucesso!');
    }

    setState(() => _loading = false);

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento aceito com sucesso!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  Future<void> _rejectBooking() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Motivo da Rejeição'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Informe o motivo...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rejeitar'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _loading = true);

      final result = await _apiService.rejectBooking(widget.booking['id'], reason);

      setState(() => _loading = false);

      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _startService() async {
    setState(() => _loading = true);

    final result = await _apiService.startService(widget.booking['id']);

    if (result['success']) {
      print('Serviço iniciado com sucesso!');
    }

    setState(() => _loading = false);

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço iniciado com sucesso!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  Future<void> _completeService() async {
    setState(() => _loading = true);

    final result = await _apiService.completeService(widget.booking['id']);

    if (result['success']) {
      print('Serviço finalizado com sucesso!');
    }

    setState(() => _loading = false);

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço concluído com sucesso!'),
          backgroundColor: AppColors.greenSuccessColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Detalhes do Agendamento',
          style: TextStyle(color: Color(0xFF252940), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF252940)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(status),
                ),
              ),
              child: Column(
                children: [
                  Icon(_getStatusIcon(status), color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Agendamento #${widget.booking['id']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info
                  _buildSection(
                    'Cliente',
                    [
                      _buildInfoRow(Icons.person, widget.booking['customer_name'] ?? 'Cliente'),
                      _buildInfoRow(Icons.phone, widget.booking['customer_phone'] ?? 'Telefone'),
                      _buildInfoRow(Icons.email, widget.booking['customer_email'] ?? 'Email'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Date & Time
                  _buildSection(
                    'Data e Horário',
                    [
                      _buildInfoRow(
                        Icons.calendar_today,
                        widget.booking['scheduled_date'] != null
                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.booking['scheduled_date']))
                            : 'Data não definida',
                      ),
                      _buildInfoRow(Icons.access_time, widget.booking['scheduled_time'] ?? '00:00'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Vehicle
                  _buildSection(
                    'Veículo',
                    [
                      _buildInfoRow(
                        Icons.directions_car,
                        '${widget.booking['vehicle_brand']} ${widget.booking['vehicle_model']}',
                      ),
                      _buildInfoRow(Icons.pin, widget.booking['vehicle_plate'] ?? 'ABC-1234'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Services
                  const Text(
                    'Serviços',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF252940),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...((widget.booking['services'] as List?) ?? []).map((service) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.bgLightGrayColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service['title'] ?? 'Serviço',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'R\$ ${(service['price'] ?? 0) / 100}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.primaryGreenDark],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${(widget.booking['total'] ?? 0) / 100}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(status),
    );
  }

  Widget? _buildActionButtons(String status) {
    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : _rejectBooking,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rejeitar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _acceptBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aceitar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'confirmed') {
      return Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _loading ? null : _startService,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blueInfoColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('Iniciar Serviço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (status == 'in_progress') {
      return Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _loading ? null : _completeService,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenSuccessColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('Concluir Serviço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );
    }
    
    return null;
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF252940)),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.bgLightGrayColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 15))),
        ],
      ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'confirmed':
        return [const Color(0xFF7896D8), const Color(0xFF5C7BC4)];
      case 'in_progress':
        return [AppColors.primaryColor, AppColors.primaryGreenDark];
      case 'completed':
        return [AppColors.greenSuccessColor, const Color(0xFF1FC04D)];
      default:
        return [AppColors.yellowWarningColor, const Color(0xFFC99800)];
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'in_progress':
        return 'Em Andamento';
      case 'completed':
        return 'Concluído';
      default:
        return 'Aguardando Aprovação';
    }
  }
}
