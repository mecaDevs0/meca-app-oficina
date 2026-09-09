import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/evidence_service.dart';
import '../../widgets/beautiful_error_snackbar.dart';

class CheckinPhotoScreen extends StatefulWidget {
  const CheckinPhotoScreen({
    super.key,
    required this.bookingId,
    this.booking,
    this.alreadyCheckedIn = false,
  });

  final String bookingId;
  final Map<String, dynamic>? booking;
  final bool alreadyCheckedIn;

  @override
  State<CheckinPhotoScreen> createState() => _CheckinPhotoScreenState();
}

class _PhotoEntry {
  File file;
  String type; // 'painel' or 'generic'
  String caption;
  bool uploaded;
  bool uploading;

  _PhotoEntry({
    required this.file,
    required this.type,
    this.caption = '',
    this.uploaded = false,
    this.uploading = false,
  });
}

class _CheckinPhotoScreenState extends State<CheckinPhotoScreen> {
  final ApiService _apiService = ApiService();
  final EvidenceService _evidenceService = EvidenceService();
  final ImagePicker _picker = ImagePicker();

  bool _checkingIn = false;
  bool _checkedIn = false;
  bool _isUploading = false;
  bool _isLoading = true;
  int _uploadProgress = 0;
  int _uploadTotal = 0;

  _PhotoEntry? _painelPhoto;
  final List<_PhotoEntry> _genericPhotos = [];
  List<dynamic> _existingPhotos = [];
  Map<String, dynamic>? _checklistStatus;

  final Map<String, TextEditingController> _captionControllers = {};
  final TextEditingController _mileageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkedIn = widget.alreadyCheckedIn;
    if (_checkedIn) {
      _loadExistingPhotos();
    } else {
      _performCheckin();
    }
  }

  @override
  void dispose() {
    for (final c in _captionControllers.values) {
      c.dispose();
    }
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _performCheckin() async {
    setState(() => _checkingIn = true);

    final result = await _apiService.checkInVehicle(widget.bookingId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _checkingIn = false;
        _checkedIn = true;
        _isLoading = false;
      });
      BeautifulErrorSnackbar.showSuccess(context, 'Check-in registrado!');
    } else {
      setState(() => _checkingIn = false);
      BeautifulErrorSnackbar.show(
        context,
        result['error']?.toString() ?? 'Erro no check-in.',
      );
      if (mounted) Navigator.pop(context, 'error');
    }
  }

  Future<void> _loadExistingPhotos() async {
    setState(() => _isLoading = true);

    final result = await _evidenceService.getCheckinPhotos(widget.bookingId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _existingPhotos = data?['data'] ?? [];
        _checklistStatus = data?['checklist_status'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPainelPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        setState(() {
          _painelPhoto = _PhotoEntry(
            file: File(picked.path),
            type: 'painel',
            caption: 'Painel / Odômetro',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      BeautifulErrorSnackbar.show(context, 'Erro ao capturar imagem: $e');
    }
  }

  Future<void> _pickGenericPhoto(ImageSource source) async {
    if (_totalPhotoCount >= 20) {
      BeautifulErrorSnackbar.showWarning(context, 'Máximo de 20 fotos atingido.');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        final key = 'generic_${DateTime.now().millisecondsSinceEpoch}';
        _captionControllers[key] = TextEditingController();
        setState(() {
          _genericPhotos.add(_PhotoEntry(
            file: File(picked.path),
            type: 'generic',
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      BeautifulErrorSnackbar.show(context, 'Erro ao selecionar imagem: $e');
    }
  }

  int get _totalPhotoCount =>
      _existingPhotos.length +
      (_painelPhoto != null ? 1 : 0) +
      _genericPhotos.length;

  bool get _allCaptionsValid {
    for (final p in _genericPhotos) {
      if (p.caption.trim().length < 3) return false;
    }
    if (_painelPhoto != null && _painelPhoto!.caption.trim().length < 3) return false;
    return true;
  }

  List<_PhotoEntry> get _pendingPhotos {
    final list = <_PhotoEntry>[];
    if (_painelPhoto != null && !_painelPhoto!.uploaded) list.add(_painelPhoto!);
    list.addAll(_genericPhotos.where((p) => !p.uploaded));
    return list;
  }

  Future<void> _uploadAllPhotos() async {
    final photos = _pendingPhotos;
    if (photos.isEmpty) {
      BeautifulErrorSnackbar.showWarning(context, 'Nenhuma foto para enviar.');
      return;
    }

    if (!_allCaptionsValid) {
      BeautifulErrorSnackbar.showWarning(context, 'Todas as fotos precisam de legenda (mínimo 3 caracteres).');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTotal = photos.length;
    });

    bool anyError = false;

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      setState(() {
        photo.uploading = true;
        _uploadProgress = i;
      });

      final result = await _evidenceService.uploadCheckinPhoto(
        widget.bookingId,
        photo.file,
        type: photo.type,
        caption: photo.caption.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          photo.uploaded = true;
          photo.uploading = false;
        });
      } else {
        anyError = true;
        setState(() => photo.uploading = false);
        BeautifulErrorSnackbar.show(
          context,
          result['error']?.toString() ?? 'Erro ao enviar foto ${i + 1}',
        );
        break;
      }
    }

    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
      _uploadTotal = 0;
    });

    if (!anyError) {
      final kmDigits = _mileageController.text.replaceAll(RegExp(r'\D'), '');
      if (kmDigits.isNotEmpty) {
        await _apiService.checkInVehicle(widget.bookingId, mileageKm: int.tryParse(kmDigits));
      }
      if (!mounted) return;
      BeautifulErrorSnackbar.showSuccess(context, 'Fotos de check-in enviadas!');
      _genericPhotos.removeWhere((p) => p.uploaded);
      if (_painelPhoto?.uploaded == true) _painelPhoto = null;
      await _loadExistingPhotos();
    }
  }

  void _removeGenericPhoto(int index) {
    setState(() {
      _genericPhotos.removeAt(index);
    });
  }

  void _removePainelPhoto() {
    setState(() {
      _painelPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
        title: const Text('Check-in do Veículo'),
        actions: [
          if (_checkedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadExistingPhotos,
            ),
        ],
      ),
      body: _checkingIn
          ? _buildCheckingInState(primaryText, secondaryText)
          : !_checkedIn
              ? const Center(child: CircularProgressIndicator())
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadExistingPhotos,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          _buildStatusBanner(isDarkMode, primaryText),
                          const SizedBox(height: 16),
                          _buildPainelSection(cardColor, cardBorder, primaryText, secondaryText, isDarkMode),
                          const SizedBox(height: 16),
                          _buildGenericSection(cardColor, cardBorder, primaryText, secondaryText, isDarkMode),
                          if (_existingPhotos.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildExistingPhotosSection(cardColor, cardBorder, primaryText, secondaryText, isDarkMode),
                          ],
                        ],
                      ),
                    ),
      bottomNavigationBar: _checkedIn && !_isLoading
          ? _buildBottomBar(isDarkMode, primaryText)
          : null,
    );
  }

  Widget _buildCheckingInState(Color primaryText, Color secondaryText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Registrando check-in...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirmando chegada do veículo',
            style: TextStyle(fontSize: 13, color: secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isDarkMode, Color primaryText) {
    final hasPainel = _checklistStatus?['painel'] == true || _painelPhoto != null;
    final existingTotal = _checklistStatus?['total'] ?? 0;
    final pendingCount = (_painelPhoto != null && !(_painelPhoto?.uploaded ?? false) ? 1 : 0) +
        _genericPhotos.where((p) => !p.uploaded).length;
    final total = existingTotal + pendingCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasPainel
            ? const Color(0xFF00C977).withOpacity(isDarkMode ? 0.14 : 0.10)
            : Colors.orange.withOpacity(isDarkMode ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPainel
              ? const Color(0xFF00C977).withOpacity(0.30)
              : Colors.orange.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPainel ? Icons.check_circle : Icons.info_outline,
            color: hasPainel ? const Color(0xFF00C977) : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPainel ? 'Foto do painel adicionada' : 'Foto do painel recomendada',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total foto${total != 1 ? 's' : ''} no check-in',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryText.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelSection(Color cardColor, Color cardBorder, Color primaryText, Color secondaryText, bool isDarkMode) {
    final hasPainelExisting = _checklistStatus?['painel'] == true;

    return Container(
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto do Painel / Odômetro',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPainelExisting ? 'Já enviada — nova foto substituirá a atual' : 'Registre a quilometragem na chegada',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ],
                ),
              ),
              if (hasPainelExisting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF00C977), size: 14),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _mileageController,
            keyboardType: TextInputType.number,
            inputFormatters: [_KmFormatter()],
            decoration: InputDecoration(
              labelText: 'Quilometragem (km)',
              hintText: 'Ex: 45.363',
              prefixIcon: const Icon(Icons.speed, color: Color(0xFF3B82F6), size: 18),
              suffixText: 'km',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(fontSize: 14, color: primaryText),
          ),
          const SizedBox(height: 14),
          if (_painelPhoto != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _painelPhoto!.file,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _removePainelPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Painel', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.label_outline, color: secondaryText, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Painel / Odômetro',
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),
                ],
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickPainelPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: const Text('Câmera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.35)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickPainelPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galeria'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.35)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGenericSection(Color cardColor, Color cardBorder, Color primaryText, Color secondaryText, bool isDarkMode) {
    return Container(
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF00C977), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fotos Gerais do Veículo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cada foto precisa de uma legenda',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_genericPhotos.isNotEmpty) ...[
            ..._genericPhotos.asMap().entries.map((entry) {
              final i = entry.key;
              final photo = entry.value;
              final controllerKey = 'generic_$i';

              if (!_captionControllers.containsKey(controllerKey)) {
                _captionControllers[controllerKey] = TextEditingController(text: photo.caption);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: i < _genericPhotos.length - 1 ? 12 : 0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            photo.file,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeGenericPhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        if (photo.uploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        if (photo.uploaded)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C977).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(Icons.check_circle, color: Color(0xFF00C977), size: 36),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionControllers[controllerKey],
                      maxLength: 500,
                      onChanged: (v) => setState(() => photo.caption = v),
                      decoration: InputDecoration(
                        labelText: 'Legenda *',
                        hintText: 'Descreva o que esta foto mostra...',
                        prefixIcon: const Icon(Icons.edit, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        counterText: '',
                        errorText: photo.caption.isNotEmpty && photo.caption.trim().length < 3
                            ? 'Mínimo 3 caracteres'
                            : null,
                      ),
                      style: TextStyle(fontSize: 13, color: primaryText),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          if (_totalPhotoCount < 20)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickGenericPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera, size: 16),
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
                    onPressed: _isUploading ? null : () => _pickGenericPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 16),
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
        ],
      ),
    );
  }

  Widget _buildExistingPhotosSection(Color cardColor, Color cardBorder, Color primaryText, Color secondaryText, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos já enviadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryText),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: _existingPhotos.length,
          itemBuilder: (context, index) {
            final photo = _existingPhotos[index];
            final url = photo['url']?.toString();
            final type = photo['type']?.toString() ?? 'generic';
            final caption = photo['caption']?.toString() ?? '';
            final isPainel = type == 'painel';

            return GestureDetector(
              onTap: () => url != null ? _showImagePreview(url, caption, isPainel) : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url != null)
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cardColor,
                            child: Icon(Icons.broken_image, color: secondaryText),
                          ),
                        )
                      else
                        Container(
                          color: cardColor,
                          child: Icon(Icons.image_not_supported, color: secondaryText),
                        ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPainel
                                ? const Color(0xFF3B82F6).withOpacity(0.85)
                                : Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isPainel ? 'Painel' : '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      if (caption.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                              ),
                            ),
                            child: Text(
                              caption,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildBottomBar(bool isDarkMode, Color primaryText) {
    final pendingCount = _pendingPhotos.length;
    final hasPhotos = pendingCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUploading
                  ? null
                  : () => Navigator.pop(context, _existingPhotos.isNotEmpty ? 'uploaded' : 'skipped'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(hasPhotos ? 'Pular fotos' : 'Fechar'),
            ),
          ),
          if (hasPhotos) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (_isUploading || !_allCaptionsValid) ? null : _uploadAllPhotos,
                icon: _isUploading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDarkMode ? Colors.black : Colors.white,
                          value: _uploadTotal > 0 ? _uploadProgress / _uploadTotal : null,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(
                  _isUploading
                      ? 'Enviando ${_uploadProgress + 1}/$_uploadTotal...'
                      : 'Enviar $pendingCount foto${pendingCount != 1 ? 's' : ''}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  disabledBackgroundColor: const Color(0xFF00C977).withOpacity(0.55),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImagePreview(String imageUrl, String caption, bool isPainel) {
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
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.white, size: 48),
                        ),
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
                  if (isPainel)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Painel', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    caption,
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

class _KmFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final capped = digits.length > 7 ? digits.substring(0, 7) : digits;
    final number = int.parse(capped);
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
