import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../../services/evidence_service.dart';
import '../../widgets/animation_widgets.dart';

class EvidenceUploadScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> booking;

  const EvidenceUploadScreen({
    Key? key,
    required this.bookingId,
    required this.booking,
  }) : super(key: key);

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  List<File> _selectedFiles = [];
  List<Map<String, dynamic>> _uploadedEvidence = [];
  bool _uploading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadExistingEvidence();
  }

  Future<void> _loadExistingEvidence() async {
    try {
      final result = await _apiService.getBookingEvidence(widget.bookingId);
      if (result['success']) {
        setState(() {
          _uploadedEvidence = List<Map<String, dynamic>>.from(result['data']['evidence'] ?? []);
        });
      }
    } catch (e) {
      print('Erro ao carregar evidências existentes: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Erro ao capturar imagem: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: ${e.toString()}');
    }
  }

  Future<void> _uploadEvidence() async {
    if (_selectedFiles.isEmpty) {
      _showError('Selecione pelo menos um arquivo para upload');
      return;
    }

    setState(() {
      _uploading = true;
      _error = '';
    });

    try {
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        
        // Mostrar progresso
        _showUploadProgress(i + 1, _selectedFiles.length);
        
        final result = await _apiService.uploadBookingEvidence(
          widget.bookingId,
          file,
        );

        if (!result['success']) {
          throw Exception(result['error'] ?? 'Erro no upload');
        }
      }

      // Recarregar evidências
      await _loadExistingEvidence();
      
      setState(() {
        _selectedFiles.clear();
        _uploading = false;
      });

      _showSuccess('Evidências enviadas com sucesso!');
      
    } catch (e) {
      setState(() {
        _uploading = false;
        _error = e.toString();
      });
      _showError('Erro no upload: ${e.toString()}');
    }
  }

  void _showUploadProgress(int current, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimationWidgets.buildLoadingWidget(
              message: 'Enviando evidência $current de $total...',
              size: 80,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00C977),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Provas do Serviço',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00C977),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildBookingInfo(),
          Expanded(
            child: _buildContent(),
          ),
          if (_selectedFiles.isNotEmpty) _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00C977).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00C977).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações do Agendamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00C977),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliente: ${widget.booking['customer']?['name'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Serviço: ${widget.booking['service']?['name'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Data: ${_formatDate(widget.booking['scheduled_date'])}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUploadSection(),
          const SizedBox(height: 24),
          _buildExistingEvidence(),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
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
            'Anexar Evidências',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252940),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture fotos ou vídeos do serviço realizado para o cliente.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Botões de captura
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C977),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
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
          
          // Lista de arquivos selecionados
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Arquivos Selecionados:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildSelectedFileCard(file, index);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedFileCard(File file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Color(0xFF00C977)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.path.split('/').last,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: _uploading ? null : () {
              setState(() {
                _selectedFiles.removeAt(index);
              });
            },
            icon: const Icon(Icons.close, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExistingEvidence() {
    if (_uploadedEvidence.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Evidências Enviadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252940),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _uploadedEvidence.length,
            itemBuilder: (context, index) {
              final evidence = _uploadedEvidence[index];
              return _buildEvidenceCard(evidence);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> evidence) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Placeholder para imagem
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey.shade100,
              child: const Icon(
                Icons.image,
                size: 40,
                color: Colors.grey,
              ),
            ),
            // Overlay com nome do arquivo
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                ),
                child: Text(
                  evidence['fileName'] ?? 'Arquivo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _uploading ? null : _uploadEvidence,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C977),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Enviar Evidências',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
