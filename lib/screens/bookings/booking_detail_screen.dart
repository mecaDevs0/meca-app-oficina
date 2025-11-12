import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/form_styles.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  
  const BookingDetailScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = false;
  bool _loadingUploads = false;
  String? _uploadsError;
  List<Map<String, dynamic>> _customerUploads = [];
  bool _isLoadingBooking = false;
  late Map<String, dynamic> _booking;

  @override
  void initState() {
    super.initState();
    _booking = Map<String, dynamic>.from(widget.booking);
    _loadBooking();
    _fetchCustomerUploads();
  }

  Future<void> _loadBooking() async {
    final bookingId = _booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) {
      return;
    }

    setState(() => _isLoadingBooking = true);
    final result = await _apiService.getBookingById(bookingId);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final uploads = _parseUploads(data['customer_uploads'] ?? data['customerUploads']);
      setState(() {
        _booking = data;
        if (uploads.isNotEmpty) {
          _customerUploads = uploads;
        }
      });
    }

    setState(() => _isLoadingBooking = false);
  }

  Future<void> _acceptBooking() async {
    final bookingId = _booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    setState(() => _loading = true);

    final result = await _apiService.confirmBooking(bookingId);

    if (result['success']) {
      await _loadBooking();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento aprovado com sucesso!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      Navigator.pop(context, true);
    }

    setState(() => _loading = false);
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
            maxLines: 3,
            style: FormStyles.inputTextStyle(context),
            cursorColor: AppColors.primaryColor,
            decoration: FormStyles.decorate(
              context,
              const InputDecoration(
              hintText: 'Informe o motivo...',
            ),
            ),
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
      final bookingId = _booking['id']?.toString() ?? '';
      if (bookingId.isEmpty) return;

      setState(() => _loading = true);

      final result = await _apiService.rejectBooking(bookingId, reason);

      setState(() => _loading = false);

      if (result['success']) {
        await _loadBooking();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento recusado com sucesso!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _suggestNewTime() async {
    final bookingId = _booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final reasonController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sugerir Novo Horário',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
                      title: Text(
                        selectedDate == null
                            ? 'Selecionar data'
                            : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.primaryColor,
                                  onPrimary: Colors.white,
                                  surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                  onSurface: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: AppColors.primaryColor),
                      title: Text(
                        selectedTime == null
                            ? 'Selecionar horário'
                            : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.primaryColor,
                                  onPrimary: Colors.white,
                                  surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                  onSurface: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      style: FormStyles.inputTextStyle(context),
                      cursorColor: AppColors.primaryColor,
                      decoration: FormStyles.decorate(
                        context,
                        const InputDecoration(
                          labelText: 'Motivo (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (selectedDate != null && selectedTime != null)
                                ? () {
                                    final combined = DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                      selectedTime!.hour,
                                      selectedTime!.minute,
                                    ).toIso8601String();
                                    Navigator.pop(context, {
                                      'date': combined,
                                      'reason': reasonController.text.trim(),
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                            ),
                            child: const Text('Sugerir'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (!mounted) return;

    if (result != null && result['date'] != null) {
      setState(() => _loading = true);
      final apiResult = await _apiService.suggestNewTime(
        bookingId,
        result['date'] as String,
        (result['reason'] as String?) ?? '',
      );
      setState(() => _loading = false);

      if (!mounted) return;

      if (apiResult['success']) {
        await _loadBooking();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo horário sugerido com sucesso!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${apiResult['error']}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _startService() async {
    if (_loading) return;
    final currentEstimated = _asNum(_booking['estimated_price']);
    final initialValue = currentEstimated != null && currentEstimated > 0
        ? (currentEstimated / 100).toStringAsFixed(2)
        : null;

    final sheetResult = await _showPriceSheet(
      title: 'Iniciar serviço',
      description: 'Informe um valor estimado (opcional).',
      confirmLabel: 'Iniciar serviço',
      priceRequired: false,
      initialPrice: initialValue,
    );

    if (sheetResult == null || !sheetResult.confirmed) {
      return;
    }

    setState(() => _loading = true);

    final result = await _apiService.startService(
      _booking['id'].toString(),
      estimatedPriceCents: sheetResult.cents,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        final parsed = Map<String, dynamic>.from(data);
        final uploads = _parseUploads(parsed['customer_uploads'] ?? parsed['customerUploads']);
        setState(() {
          _booking = parsed;
          if (uploads.isNotEmpty) {
            _customerUploads = uploads;
          }
        });
      } else {
        await _loadBooking();
      }
      await _fetchCustomerUploads();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço iniciado com sucesso!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      final errorMessage = result['error']?.toString() ?? 'Não foi possível iniciar o serviço.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _finishService() async {
    if (_loading) return;

    final sheetResult = await _showPriceSheet(
      title: 'Concluir serviço',
      description: 'Informe o valor final cobrado ao cliente e, se desejar, adicione observações internas.',
      confirmLabel: 'Concluir serviço',
      priceRequired: true,
      includeNotes: true,
    );

    if (sheetResult == null || !sheetResult.confirmed || sheetResult.cents == null) {
      return;
    }

    setState(() => _loading = true);

    final result = await _apiService.finishService(
      _booking['id'].toString(),
      finalPriceCents: sheetResult.cents!,
      notes: sheetResult.notes,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        final parsed = Map<String, dynamic>.from(data);
        final uploads = _parseUploads(parsed['customer_uploads'] ?? parsed['customerUploads']);
        setState(() {
          _booking = parsed;
          if (uploads.isNotEmpty) {
            _customerUploads = uploads;
          }
        });
      } else {
        await _loadBooking();
      }
      await _fetchCustomerUploads();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço concluído com sucesso!'),
          backgroundColor: AppColors.greenSuccessColor,
        ),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      final errorMessage = result['error']?.toString() ?? 'Não foi possível concluir o serviço.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _fetchCustomerUploads() async {
    final bookingId = _booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) {
      return;
    }

    setState(() {
      _loadingUploads = true;
      _uploadsError = null;
    });

    final result = await _apiService.getCustomerUploads(bookingId);

    if (!mounted) return;

    if (result['success'] == true) {
      final raw = result['data'];
      final uploads = _parseUploads(raw);
      setState(() {
        _customerUploads = uploads;
        _loadingUploads = false;
      });
    } else {
      setState(() {
        _uploadsError = result['error']?.toString() ?? 'Não foi possível carregar as fotos do cliente.';
        _customerUploads = _parseUploads(_booking['customer_uploads'] ?? _booking['customerUploads']);
        _loadingUploads = false;
      });
    }
  }

  void _openUploadPreview(Map<String, dynamic> upload) {
    final url = _resolveUploadUrl(upload);
    if (url == null) return;

    final fileName = upload['file_name']?.toString() ??
        upload['name']?.toString() ??
        'Foto do cliente';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fileName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF6F7FB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final status = (_booking['status'] ?? 'pending').toString();
    final customerNotes = (_booking['customer_notes'] ?? _booking['notes'] ?? '').toString().trim();
    final appointment = _parseDateTime(_booking['appointment_date'] ?? _booking['scheduled_date']);
    final dateLabel = appointment != null ? DateFormat('dd/MM/yyyy').format(appointment) : 'Data não definida';
    final timeLabel = appointment != null ? DateFormat('HH:mm').format(appointment) : '--:--';
    final customerName = (_booking['customer_name'] ?? 'Cliente MECA').toString();
    final vehicleLabel = (_booking['vehicle_display'] ??
            '${_booking['vehicle_brand'] ?? ''} ${_booking['vehicle_model'] ?? ''}')
        .toString()
        .trim();
    final servicesList = _booking['services'] is List
        ? List<Map<String, dynamic>>.from(
            (_booking['services'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];
    final num? finalPriceRaw = _asNum(_booking['final_price']);
    final num? totalRaw = _asNum(_booking['total']);
    final num? estimatedRaw = _asNum(_booking['estimated_price']);
    final num selectedPriceRaw = finalPriceRaw ?? totalRaw ?? estimatedRaw ?? 0;
    final bool hasTotalValue = selectedPriceRaw > 0;
    final double totalValueReais = selectedPriceRaw / 100.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Detalhes do Agendamento',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBooking();
          await _fetchCustomerUploads();
        },
        child: _isLoadingBooking
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(
                      status: status,
                      appointment: appointment,
                      customerName: customerName,
                      vehicleLabel: vehicleLabel,
                      bookingId: (_booking['id'] ?? '').toString(),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      isDark: isDark,
                      icon: Icons.person_outline,
                      title: 'Cliente',
                      children: [
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.badge_outlined,
                          label: 'Nome',
                          value: customerName,
                        ),
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.phone_outlined,
                          label: 'Telefone',
                          value: (_booking['customer_phone'] ?? 'Telefone não informado').toString(),
                        ),
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: (_booking['customer_email'] ?? 'Email não informado').toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      isDark: isDark,
                      icon: Icons.calendar_today_outlined,
                      title: 'Data e horário',
                      children: [
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.event_outlined,
                          label: 'Data',
                          value: dateLabel,
                        ),
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.schedule_outlined,
                          label: 'Horário',
                          value: '$timeLabel h',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      isDark: isDark,
                      icon: Icons.directions_car_outlined,
                      title: 'Veículo',
                      children: [
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.directions_car_filled_outlined,
                          label: 'Modelo',
                          value: vehicleLabel.isNotEmpty ? vehicleLabel : 'Não informado',
                        ),
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.pin_outlined,
                          label: 'Placa',
                          value: (_booking['vehicle_plate'] ?? '--- ---').toString().toUpperCase(),
                        ),
                      ],
                    ),
                    if (customerNotes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        isDark: isDark,
                        icon: Icons.sticky_note_2_outlined,
                        title: 'Observações do cliente',
                        children: [
                          Text(
                            customerNotes,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_loadingUploads) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ] else if (_uploadsError != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        isDark: isDark,
                        icon: Icons.photo_library_outlined,
                        title: 'Fotos do cliente',
                        children: [
                          Text(
                            _uploadsError!,
                            style: TextStyle(
                              color: Colors.redAccent.shade200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _fetchCustomerUploads,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_customerUploads.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        isDark: isDark,
                        icon: Icons.photo_library_outlined,
                        title: 'Fotos enviadas pelo cliente',
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _customerUploads.map((upload) {
                              final url = _resolveUploadUrl(upload);
                              if (url == null) {
                                return const SizedBox.shrink();
                              }
                              return GestureDetector(
                                onTap: () => _openUploadPreview(upload),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    color: isDark
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFFE5E7EB),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade300,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      isDark: isDark,
                      icon: Icons.build_outlined,
                      title: 'Serviço',
                      children: [
                        _buildDetailRow(
                          isDark: isDark,
                          icon: Icons.design_services_outlined,
                          label: 'Descrição',
                          value: (_booking['service_name'] ??
                                  (servicesList.isNotEmpty
                                      ? (servicesList.first['name'] ??
                                          servicesList.first['title'] ??
                                          'Serviço')
                                      : 'Serviço'))
                              .toString(),
                        ),
                        if (servicesList.isNotEmpty)
                          ...servicesList.map(
                            (service) => _buildDetailRow(
                              isDark: isDark,
                              icon: Icons.task_alt_outlined,
                              label: service['name']?.toString() ?? 'Serviço',
                              value: () {
                                final price = _asNum(service['price']);
                                if (price != null && price > 0) {
                                  return 'R\$ ${(price / 100).toStringAsFixed(2)}';
                                }
                                return 'Valor não informado';
                              }(),
                            ),
                          ),
                      ],
                    ),
                    if (hasTotalValue) ...[
                      const SizedBox(height: 20),
                      _buildTotalCard(
                        isDark: isDark,
                        value: totalValueReais,
                      ),
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildActionButtons(status),
    );
  }

  Widget _buildStatusHeader({
    required String status,
    required DateTime? appointment,
    required String customerName,
    required String vehicleLabel,
    required String bookingId,
  }) {
    final subtitle = appointment != null
        ? '${DateFormat('dd MMM yyyy').format(appointment)} • ${DateFormat('HH:mm').format(appointment)}'
        : 'Data não definida';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusGradient(status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Agendamento #$bookingId',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (vehicleLabel.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                vehicleLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children
              .expand((widget) => [widget, const SizedBox(height: 14)])
              .toList()
            ..removeLast(),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final titleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final valueColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard({required bool isDark, required double value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Total do serviço',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Valor a receber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: false);
      } catch (_) {
        return null;
      }
    }
    if (raw is String) {
      final trimmed = raw.trim();
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

  List<Map<String, dynamic>> _parseUploads(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .where((item) => item != null)
          .map<Map<String, dynamic>>((item) {
            if (item is Map<String, dynamic>) {
              return Map<String, dynamic>.from(item);
            }
            if (item is Map) {
              return Map<String, dynamic>.from(item.cast<String, dynamic>());
            }
            return <String, dynamic>{};
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return _parseUploads(decoded);
      } catch (_) {
        return [];
      }
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw.cast<String, dynamic>())];
    }
    return [];
  }

  String? _resolveUploadUrl(Map<String, dynamic> upload) {
    final signed = upload['signed_url']?.toString();
    if (signed != null && signed.isNotEmpty) {
      return signed;
    }
    final url = upload['url']?.toString();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    final location = upload['location']?.toString();
    if (location != null && location.isNotEmpty) {
      return location;
    }
    return null;
  }

  num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final sanitized = value.replaceAll(',', '.');
      return num.tryParse(sanitized);
    }
    return null;
  }

  Future<_PriceSheetResult?> _showPriceSheet({
    required String title,
    String? description,
    required String confirmLabel,
    bool priceRequired = false,
    bool includeNotes = false,
    String? initialPrice,
  }) async {
    return showModalBottomSheet<_PriceSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final priceController = TextEditingController(text: initialPrice);
        final notesController = TextEditingController();
        final theme = Theme.of(context);
        final cardColor = theme.cardColor;

        String? priceValidator(String? value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) {
            if (priceRequired) {
              return 'Informe o valor.';
            }
            return null;
          }
          final sanitized = text.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
          final parsed = double.tryParse(sanitized);
          if (parsed == null || parsed <= 0) {
            return 'Valor inválido.';
          }
          return null;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
          ),
          child: Material(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: FormStyles.inputTextStyle(context),
                        cursorColor: AppColors.primaryColor,
                        decoration: FormStyles.decorate(
                          context,
                          const InputDecoration(
                          labelText: 'Valor (R\$)',
                          prefixText: 'R\$ ',
                          ),
                        ),
                        validator: priceValidator,
                      ),
                      if (includeNotes) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          style: FormStyles.inputTextStyle(context),
                          cursorColor: AppColors.primaryColor,
                          decoration: FormStyles.decorate(
                            context,
                            const InputDecoration(
                            labelText: 'Observações da oficina (opcional)',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(
                                context,
                                const _PriceSheetResult(confirmed: false),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                int? cents;
                                final trimmed = priceController.text.trim();
                                if (trimmed.isNotEmpty) {
                                  final sanitized =
                                      trimmed.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
                                  final parsed = double.tryParse(sanitized);
                                  if (parsed != null && parsed > 0) {
                                    cents = (parsed * 100).round();
                                  }
                                }

                                final notesText =
                                    includeNotes ? notesController.text.trim() : null;

                                Navigator.pop(
                                  context,
                                  _PriceSheetResult(
                                    confirmed: true,
                                    cents: cents,
                                    notes: notesText?.isNotEmpty == true ? notesText : null,
                                  ),
                                );
                              },
                              child: Text(confirmLabel),
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
        );
      },
    );
  }

  Widget? _buildActionButtons(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'pending' ||
        normalized == 'pendente_oficina' ||
        normalized == 'pendente' ||
        normalized == 'pendente_cliente') {
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
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _rejectBooking,
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                label: const Text('Recusar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _suggestNewTime,
                icon: const Icon(Icons.schedule, size: 18, color: Color(0xFFF59E0B)),
                label: const Text('Sugerir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _acceptBooking,
                icon: const Icon(Icons.check, size: 18, color: Colors.white),
                label: const Text('Aprovar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (normalized == 'confirmed') {
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
    } else if (normalized == 'in_progress' || normalized == 'started') {
      return Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _loading ? null : _finishService,
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

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'confirmed':
        return [const Color(0xFF7896D8), const Color(0xFF5C7BC4)];
      case 'started':
      case 'in_progress':
        return [AppColors.primaryColor, AppColors.primaryGreenDark];
      case 'pago':
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
      case 'started':
      case 'in_progress':
        return Icons.build_circle;
      case 'pago':
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
      case 'started':
      case 'in_progress':
        return 'Em Andamento';
      case 'pago':
      case 'completed':
        return 'Concluído';
      default:
        return 'Aguardando Aprovação';
    }
  }
}

class _PriceSheetResult {
  final bool confirmed;
  final int? cents;
  final String? notes;

  const _PriceSheetResult({
    required this.confirmed,
    this.cents,
    this.notes,
  });
}
