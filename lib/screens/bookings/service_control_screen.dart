import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/evidence_service.dart';
import '../../services/service_control_service.dart';
import 'evidence_upload_screen.dart';

class ServiceControlScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> booking;

  const ServiceControlScreen({
    Key? key,
    required this.bookingId,
    required this.booking,
  }) : super(key: key);

  @override
  State<ServiceControlScreen> createState() => _ServiceControlScreenState();
}

class _ServiceControlScreenState extends State<ServiceControlScreen> {
  final ServiceControlService _serviceControlService = ServiceControlService();
  final ApiService _apiService = ApiService();
  final EvidenceService _evidenceService = EvidenceService();
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  String _error = '';
  List<File> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'] ?? 'pending';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle do Serviço',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00C977),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botão para upload de evidências
          if (status == 'in_progress' || status == 'completed')
            IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: _uploadEvidence,
              tooltip: 'Enviar Provas',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildBookingInfo(),
          Expanded(
            child: _buildServiceControl(status),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C977), Color(0xFF00B369)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C977).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking['service']?['name'] ?? 'Serviço',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.booking['customer']?['name'] ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(widget.booking['status'] ?? 'pending'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoCard('Data', _formatDate(widget.booking['scheduled_date'])),
              const SizedBox(width: 12),
              _buildInfoCard('Hora', _formatTime(widget.booking['scheduled_date'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pendente';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'Confirmado';
        break;
      case 'in_progress':
        color = Colors.purple;
        text = 'Em Andamento';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Finalizado';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        text = 'Desconhecido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceControl(String status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de informações do serviço
          _buildServiceInfoCard(),
          const SizedBox(height: 16),
          
          // Controles baseados no status
          if (status == 'confirmed') _buildStartServiceCard(),
          if (status == 'in_progress') _buildFinishServiceCard(),
          if (status == 'completed') _buildCompletedServiceCard(),
          
          // Card de evidências (se aplicável)
          if (status == 'in_progress' || status == 'completed')
            _buildEvidenceCard(),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações do Serviço',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252940),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Cliente', widget.booking['customer']?['name'] ?? 'N/A'),
          _buildInfoRow('Telefone', widget.booking['customer']?['phone'] ?? 'N/A'),
          _buildInfoRow('Veículo', '${widget.booking['vehicle']?['brand'] ?? ''} ${widget.booking['vehicle']?['model'] ?? ''}'),
          _buildInfoRow('Placa', widget.booking['vehicle']?['plate'] ?? 'N/A'),
          if (widget.booking['notes'] != null && widget.booking['notes'].isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Observações do Cliente:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00C977),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.booking['notes'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF252940),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartServiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Color(0xFF00C977),
          ),
          const SizedBox(height: 16),
          const Text(
            'Serviço Confirmado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252940),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O cliente confirmou o agendamento. Você pode iniciar o serviço quando estiver pronto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _startService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Iniciar Serviço',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishServiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Color(0xFF00C977),
          ),
          const SizedBox(height: 16),
          const Text(
            'Serviço em Andamento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252940),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O serviço está sendo executado. Finalize quando estiver concluído.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _finishService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Finalizar Serviço',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedServiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Serviço Finalizado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O serviço foi concluído com sucesso. O cliente será redirecionado para o pagamento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_camera,
                color: Color(0xFF00C977),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Provas do Serviço',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF252940),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Envie fotos ou vídeos do serviço realizado para o cliente visualizar.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadEvidence,
              icon: const Icon(Icons.upload),
              label: const Text('Enviar Provas'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C977)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startService() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final result = await _serviceControlService.updateBookingStatus(widget.bookingId, 'in_progress');
      
      if (result['success']) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Serviço iniciado! O cliente receberá uma notificação.'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
      } else {
        setState(() {
          _error = result['error'] ?? 'Erro ao iniciar serviço';
        });
        _showError(_error);
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: ${e.toString()}';
      });
      _showError(_error);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _finishService() async {
    // Mostrar dialog para inserir preço, notas e imagens
    final result = await _showFinishServiceDialog();
    
    if (result == null || !result['confirmed']) {
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Primeiro, fazer upload das imagens se houver
      if (result['images'] != null && (result['images'] as List<File>).isNotEmpty) {
        for (final imageFile in result['images'] as List<File>) {
          try {
            await _evidenceService.uploadBookingEvidence(widget.bookingId, imageFile);
          } catch (e) {
            // Continuar mesmo se houver erro no upload de imagem
          }
        }
      }

      // Depois, finalizar o serviço com preço e notas
      final finishResult = await _apiService.finishService(
        widget.bookingId,
        finalPriceCents: result['priceCents'] as int,
        notes: result['notes'] as String?,
      );
      
      if (finishResult['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Serviço finalizado! O cliente receberá uma notificação para aprovar o orçamento.'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
        }
      } else {
        setState(() {
          _error = finishResult['error']?.toString() ?? 'Erro ao finalizar serviço';
        });
        _showError(_error);
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: ${e.toString()}';
      });
      _showError(_error);
    } finally {
      setState(() {
        _loading = false;
        _selectedImages = [];
      });
    }
  }

  Future<Map<String, dynamic>?> _showFinishServiceDialog() async {
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<File> selectedImages = [];

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Finalizar Serviço'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informe o valor final do serviço e, se desejar, adicione observações e imagens:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor Final (R\$) *',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                      helperText: 'Valor cobrado ao cliente',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o valor final';
                      }
                      final price = double.tryParse(value.replaceAll(',', '.'));
                      if (price == null || price <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      border: OutlineInputBorder(),
                      helperText: 'Observações sobre o serviço realizado',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Imagens do Serviço (opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final source = await showDialog<ImageSource>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Selecionar Imagem'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Câmera'),
                                      onTap: () => Navigator.pop(context, ImageSource.camera),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Galeria'),
                                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            
                            if (source != null) {
                              try {
                                final picked = await _picker.pickImage(
                                  source: source,
                                  imageQuality: 75,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedImages.add(File(picked.path));
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao selecionar imagem: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Adicionar Imagem'),
                        ),
                      ),
                    ],
                  ),
                  if (selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 16,
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
                  final priceCents = (price * 100).round();
                  final notes = notesController.text.trim().isEmpty 
                      ? null 
                      : notesController.text.trim();
                  
                  Navigator.of(context).pop({
                    'confirmed': true,
                    'priceCents': priceCents,
                    'notes': notes,
                    'images': selectedImages,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
              ),
              child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadEvidence() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenceUploadScreen(
          bookingId: widget.bookingId,
          booking: widget.booking,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}
