import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/evidence_service.dart';
import '../../widgets/beautiful_error_snackbar.dart';

class EvidenceUploadScreen extends StatefulWidget {
  const EvidenceUploadScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  final String bookingId;
  final Map<String, dynamic>? booking;

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  final EvidenceService _evidenceService = EvidenceService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  File? _selectedFile;
  List<dynamic> _evidences = const [];

  @override
  void initState() {
    super.initState();
    _loadEvidences();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadEvidences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _evidenceService.getBookingEvidence(widget.bookingId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _evidences = _extractEvidenceList(result['data']);
        _isLoading = false;
      });
    } else {
        setState(() {
        _errorMessage = result['error']?.toString() ?? 'Erro ao carregar evidências.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _extractEvidenceList(dynamic data) {
    if (data == null) return const [];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'] as List<dynamic>;
      if (data['evidences'] is List) return data['evidences'] as List<dynamic>;
      if (data['files'] is List) return data['files'] as List<dynamic>;
    }
    return const [];
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Reduzir tamanho para evitar erro 413 (Request Entity Too Large)
      // maxWidth/maxHeight + imageQuality garantem upload leve mesmo em iPhone (fotos grandes).
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      BeautifulErrorSnackbar.show(context, 'Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _uploadEvidence() async {
    if (_selectedFile == null) {
      BeautifulErrorSnackbar.showWarning(context, 'Selecione uma imagem antes de enviar.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    final result = await _evidenceService.uploadBookingEvidence(
      widget.bookingId,
      _selectedFile!,
      comment: _commentController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      BeautifulErrorSnackbar.showSuccess(context, 'Evidência enviada com sucesso!');
      setState(() {
        _selectedFile = null;
        _commentController.clear();
      });
      await _loadEvidences();
    } else {
      setState(() {
        _errorMessage = result['error']?.toString() ?? 'Falha ao enviar a evidência.';
      });
      BeautifulErrorSnackbar.show(context, _errorMessage ?? 'Falha ao enviar a evidência.');
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // iOS-like grouped background
    final backgroundColor = isDarkMode ? const Color(0xFF0B0B0F) : const Color(0xFFF2F2F7);
    final cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final cardBorder = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final primaryText = isDarkMode ? Colors.white : Colors.black87;
    final secondaryText = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Evidências do Serviço'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEvidences,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvidences,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(isDarkMode ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withOpacity(0.28)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildUploaderSection(
                    context,
                    cardColor: cardColor,
                    cardBorder: cardBorder,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Evidências enviadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_evidences.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        'Nenhuma evidência enviada para este agendamento.',
                        style: TextStyle(color: secondaryText, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _evidences.length,
                      itemBuilder: (context, index) {
                        final item = _evidences[index];
                        final url = _resolveEvidenceUrl(item);
                        final description = _resolveEvidenceDescription(item);

                        if (url == null) {
                          return Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Arquivo não suportado',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: secondaryText, fontWeight: FontWeight.w600),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () => _showImagePreview(url, description),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: cardColor,
                                        alignment: Alignment.center,
                                        child: Icon(Icons.broken_image, color: secondaryText),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    left: 10,
                                    top: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (description != null && description.isNotEmpty)
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.55),
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          description,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildUploaderSection(
    BuildContext context, {
    required Color cardColor,
    required Color cardBorder,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF00C977)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enviar nova evidência',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C977).withOpacity(0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF00C977), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Envie uma foto de cada vez para registrar o progresso.',
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Câmera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cardBorder),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  _selectedFile!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Comentário (opcional)',
              hintText: 'Descreva o que esta imagem mostra...',
              prefixIcon: const Icon(Icons.comment, color: Color(0xFF00C977)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadEvidence,
              icon: _isUploading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(_isUploading ? 'Enviando...' : 'Enviar foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                disabledBackgroundColor: const Color(0xFF00C977).withOpacity(0.55),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveEvidenceUrl(dynamic item) {
    if (item == null) return null;
    if (item is String) return item;
    if (item is Map) {
      final url = item['url'] ?? item['path'] ?? item['file_url'];
      if (url is String && url.isNotEmpty) {
        return url.startsWith('http') ? url : EvidenceService.baseUrl + url;
      }
    }
    return null;
  }

  String? _resolveEvidenceDescription(dynamic item) {
    if (item is Map) {
      return item['comment']?.toString() ?? item['description']?.toString();
    }
    return null;
  }

  void _showImagePreview(String imageUrl, String? description) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, color: Colors.white, size: 48),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}


