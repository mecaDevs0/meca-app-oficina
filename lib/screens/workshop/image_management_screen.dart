import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class ImageManagementScreen extends StatefulWidget {
  const ImageManagementScreen({Key? key}) : super(key: key);

  @override
  State<ImageManagementScreen> createState() => _ImageManagementScreenState();
}

class _ImageManagementScreenState extends State<ImageManagementScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  static const int _maxPhotos = 10;
  static const String _presetFachada = 'Fachada da Oficina';
  static const String _presetInterior = 'Interior da Oficina';

  List<dynamic> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _workshopId;

  bool get _hasFachada => _photos.any((p) => (p['caption'] ?? '') == _presetFachada);
  bool get _hasInterior => _photos.any((p) => (p['caption'] ?? '') == _presetInterior);
  bool get _presetsComplete => _hasFachada && _hasInterior;

  bool _isPresetPhoto(Map<String, dynamic> photo) {
    final caption = (photo['caption'] ?? '').toString();
    return caption == _presetFachada || caption == _presetInterior;
  }

  List<dynamic> get _missingPresets {
    final missing = <Map<String, dynamic>>[];
    if (!_hasFachada) missing.add({'_preset': _presetFachada, '_icon': Icons.storefront});
    if (!_hasInterior) missing.add({'_preset': _presetInterior, '_icon': Icons.garage});
    return missing;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final workshopIdStr = await _apiService.getWorkshopId();
      if (workshopIdStr == null || workshopIdStr.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sessao expirada. Faca login novamente.'), backgroundColor: Color(0xFFEF4444)),
          );
        }
        return;
      }
      _workshopId = workshopIdStr;
      final photos = await _apiService.getWorkshopGallery(_workshopId!);
      if (mounted) setState(() => _photos = photos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar galeria: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourceSheet({String? presetCaption}) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de 10 fotos atingido.'), backgroundColor: Color(0xFFF59E0B)),
      );
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF00C977).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_photo_alternate, color: Color(0xFF00C977), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        presetCaption ?? 'Adicionar Foto',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt, color: Colors.blue, size: 24),
                ),
                title: Text('Camera', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('Tire uma foto agora', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera, presetCaption: presetCaption); },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF00C977).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library, color: Color(0xFF00C977), size: 24),
                ),
                title: Text('Galeria', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('Escolha uma foto do dispositivo', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery, presetCaption: presetCaption); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, {String? presetCaption}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (image == null) return;
      await _uploadPhoto(File(image.path), caption: presetCaption);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _uploadPhoto(File file, {String? caption}) async {
    if (_workshopId == null) return;
    setState(() => _isUploading = true);
    try {
      final result = await _apiService.uploadGalleryPhoto(_workshopId!, file, caption: caption);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Foto adicionada!')]),
              backgroundColor: const Color(0xFF00C977), behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        await _loadData();
      } else {
        throw Exception(result['error'] ?? 'Erro ao enviar foto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _confirmDeletePhoto(Map<String, dynamic> photo, {bool isPreset = false}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoId = photo['id']?.toString();
    if (photoId == null || _workshopId == null) return;

    final message = isPreset
        ? 'Esta e uma foto obrigatoria (${photo['caption']}). Voce precisara enviar uma nova. Deseja remover?'
        : 'Tem certeza que deseja remover esta foto?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remover foto', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
        content: Text(message, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.deleteGalleryPhoto(_workshopId!, photoId);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Foto removida!')]),
              backgroundColor: const Color(0xFF00C977), behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        await _loadData();
      } else {
        throw Exception(result['error'] ?? 'Erro ao remover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  void _showPhotoViewer(int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final photo = _photos[currentIndex] is Map
                ? Map<String, dynamic>.from(_photos[currentIndex] as Map)
                : <String, dynamic>{};
            final imageUrl = (photo['url'] ?? photo['image_url'] ?? '').toString();
            final caption = (photo['caption'] ?? '').toString();
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -100 && currentIndex < _photos.length - 1) {
                        setDialogState(() => currentIndex++);
                      } else if (details.primaryVelocity! > 100 && currentIndex > 0) {
                        setDialogState(() => currentIndex--);
                      }
                    },
                    child: Container(color: Colors.black),
                  ),
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5, maxScale: 4.0,
                      child: Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64)),
                    ),
                  ),
                  if (caption.isNotEmpty)
                    Positioned(
                      left: 20, right: 20, bottom: 80,
                      child: Text(caption, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
                    ),
                  Positioned(
                    top: MediaQuery.of(ctx).padding.top + 8, right: 12,
                    child: IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white, size: 28)),
                  ),
                  Positioned(
                    bottom: 40, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_photos.length, (i) => Container(
                        width: 7, height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i == currentIndex ? const Color(0xFF00C977) : Colors.white30),
                      )),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = ThemeService.getBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryText = ThemeService.getSecondaryTextColor(isDark);
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

        final missing = _missingPresets;
        final totalItems = missing.length + _photos.length;
        final canAddMore = _presetsComplete && _photos.length < _maxPhotos;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fotos da Oficina', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: textColor)),
                if (!_isLoading)
                  Text('${_photos.length}/$_maxPhotos fotos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryText)),
              ],
            ),
          ),
          floatingActionButton: canAddMore
              ? FloatingActionButton(
                  onPressed: _isUploading ? null : () => _showImageSourceSheet(),
                  backgroundColor: const Color(0xFF00C977),
                  child: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.add_a_photo, color: Colors.white, size: 24),
                )
              : null,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF00C977),
                  child: totalItems == 0
                      ? _buildEmptyState(isDark, textColor, secondaryText)
                      : _buildUnifiedGrid(isDark, textColor, secondaryText, cardColor, missing),
                ),
        );
      },
    );
  }

  // ── EMPTY STATE (0 fotos, 0 presets) ──

  Widget _buildEmptyState(bool isDark, Color textColor, Color secondaryText) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_camera_outlined, size: 48, color: const Color(0xFF00C977).withOpacity(0.6)),
                ),
                const SizedBox(height: 24),
                Text('Nenhuma foto ainda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Comece adicionando a foto da fachada\nda sua oficina.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: secondaryText, height: 1.5),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : () => _showImageSourceSheet(presetCaption: _presetFachada),
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Adicionar Fachada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C977), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── UNIFIED GRID ──

  Widget _buildUnifiedGrid(bool isDark, Color textColor, Color secondaryText, Color cardColor, List<dynamic> missing) {
    final totalItems = missing.length + _photos.length;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < missing.length) {
          final preset = missing[index] as Map<String, dynamic>;
          return _buildPresetPlaceholder(preset['_preset'] as String, preset['_icon'] as IconData, isDark, textColor, secondaryText, cardColor);
        }
        final photoIndex = index - missing.length;
        final photo = _photos[photoIndex] is Map ? Map<String, dynamic>.from(_photos[photoIndex] as Map) : <String, dynamic>{};
        return _buildPhotoCard(photo, photoIndex, isDark, textColor, secondaryText, cardColor);
      },
    );
  }

  // ── PRESET PLACEHOLDER (inline no grid) ──

  Widget _buildPresetPlaceholder(String presetName, IconData icon, bool isDark, Color textColor, Color secondaryText, Color cardColor) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _showImageSourceSheet(presetCaption: presetName),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00C977).withOpacity(0.25),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF00C977).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: const Color(0xFF00C977).withOpacity(0.5), size: 26),
                  Positioned(
                    bottom: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFF00C977), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              presetName,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Toque para adicionar',
              style: TextStyle(fontSize: 11, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  // ── PHOTO CARD ──

  Widget _buildPhotoCard(Map<String, dynamic> photo, int photoIndex, bool isDark, Color textColor, Color secondaryText, Color cardColor) {
    final imageUrl = (photo['url'] ?? photo['image_url'] ?? photo['photo_url'] ?? '').toString();
    final caption = (photo['caption'] ?? '').toString();
    final isPreset = _isPresetPhoto(photo);

    return GestureDetector(
      onTap: () => _showPhotoViewer(photoIndex),
      onLongPress: () {
        if (isPreset) {
          _confirmDeletePhoto(photo, isPreset: true);
        } else {
          _showDeleteSheet(photo);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 10, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl, fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                            value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.broken_image_outlined, size: 32, color: secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 4),
                          Text('Erro ao carregar', style: TextStyle(fontSize: 10, color: secondaryText.withOpacity(0.4))),
                        ]),
                      ),
                    )
                  : Container(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                      child: Icon(Icons.image_outlined, size: 40, color: secondaryText.withOpacity(0.3))),

              // Delete button top-right
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => _confirmDeletePhoto(photo, isPreset: isPreset),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  ),
                ),
              ),

              // Gradient overlay at bottom for caption
              if (caption.isNotEmpty)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isPreset) ...[
                          Icon(caption == _presetFachada ? Icons.storefront : Icons.garage, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteSheet(Map<String, dynamic> photo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                ),
                title: Text('Remover foto', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                onTap: () { Navigator.pop(ctx); _confirmDeletePhoto(photo); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
