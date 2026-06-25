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

  List<dynamic> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  int? _workshopId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final workshopIdStr = await _apiService.getWorkshopId();
      if (workshopIdStr == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sessao expirada. Faca login novamente.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
      _workshopId = int.tryParse(workshopIdStr);
      if (_workshopId == null) return;

      final photos = await _apiService.getWorkshopGallery(_workshopId!);
      if (mounted) {
        setState(() {
          _photos = photos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar portfolio: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite de 10 fotos atingido. Remova uma foto para adicionar outra.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate, color: Color(0xFF00C977), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Adicionar Foto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue, size: 24),
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Tire uma foto agora',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF00C977), size: 24),
                ),
                title: Text(
                  'Galeria',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Escolha uma foto do dispositivo',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      // Ask for optional caption
      if (!mounted) return;
      final caption = await _showCaptionDialog();

      await _uploadPhoto(File(image.path), caption: caption);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<String?> _showCaptionDialog() async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Legenda (opcional)',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLength: 100,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Ex: Troca de oleo em andamento',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Pular',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isEmpty ? null : text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C977),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(File file, {String? caption}) async {
    if (_workshopId == null) return;

    setState(() => _isUploading = true);
    try {
      final result = await _apiService.uploadGalleryPhoto(
        _workshopId!,
        file,
        caption: caption,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Foto adicionada com sucesso!'),
                ],
              ),
              backgroundColor: const Color(0xFF00C977),
              behavior: SnackBarBehavior.floating,
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
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _confirmDeletePhoto(Map<String, dynamic> photo) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoId = photo['id'];
    if (photoId == null || _workshopId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remover foto',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Tem certeza que deseja remover esta foto do seu portfolio?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.deleteGalleryPhoto(
        _workshopId!,
        photoId is int ? photoId : int.parse(photoId.toString()),
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Foto removida com sucesso!'),
                ],
              ),
              backgroundColor: const Color(0xFF00C977),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        await _loadData();
      } else {
        throw Exception(result['error'] ?? 'Erro ao remover foto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = ThemeService.getBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryText = ThemeService.getSecondaryTextColor(isDark);
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final atLimit = _photos.length >= _maxPhotos;

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
                Text(
                  'Meu Portfolio',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                if (!_isLoading)
                  Text(
                    '${_photos.length}/$_maxPhotos fotos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                  ),
              ],
            ),
            iconTheme: IconThemeData(color: textColor),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _isUploading ? null : _showImageSourceSheet,
            backgroundColor: atLimit
                ? (isDark ? Colors.grey[700] : Colors.grey[400])
                : const Color(0xFF00C977),
            child: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF00C977),
                  child: _photos.isEmpty
                      ? _buildEmptyState(isDark, textColor, secondaryText)
                      : _buildPhotoGrid(isDark, textColor, secondaryText, cardColor),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color secondaryText) {
    return ListView(
      // ListView so pull-to-refresh works on empty state
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
                    color: const Color(0xFF00C977).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 56,
                    color: const Color(0xFF00C977).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Seu portfolio esta vazio.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Adicione fotos dos seus servicos!\nMostre seu trabalho para atrair mais clientes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  label: const Text('Adicionar primeira foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C977),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(bool isDark, Color textColor, Color secondaryText, Color cardColor) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index] is Map
            ? Map<String, dynamic>.from(_photos[index] as Map)
            : <String, dynamic>{};
        return _buildPhotoCard(photo, isDark, textColor, secondaryText, cardColor);
      },
    );
  }

  Widget _buildPhotoCard(
    Map<String, dynamic> photo,
    bool isDark,
    Color textColor,
    Color secondaryText,
    Color cardColor,
  ) {
    final imageUrl = (photo['url'] ?? photo['image_url'] ?? photo['photo_url'] ?? '').toString();
    final caption = (photo['caption'] ?? '').toString();
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: secondaryText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Erro ao carregar',
                              style: TextStyle(
                                fontSize: 11,
                                color: secondaryText.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Container(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: secondaryText.withOpacity(0.3),
                    ),
                  ),

            // Delete button (top-right)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _confirmDeletePhoto(photo),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Caption overlay (bottom)
            if (caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
