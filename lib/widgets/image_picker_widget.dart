import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/image_service.dart';
import '../services/theme_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String imageType;
  final String? currentImageUrl;
  final Function(String) onImageSelected;
  final Function()? onImageRemoved;
  final String? serviceId;
  final double width;
  final double height;
  final String? placeholder;

  const ImagePickerWidget({
    Key? key,
    required this.imageType,
    this.currentImageUrl,
    required this.onImageSelected,
    this.onImageRemoved,
    this.serviceId,
    this.width = 120,
    this.height = 120,
    this.placeholder,
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  bool _isUploading = false;
  String? _previewImage;

  @override
  void initState() {
    super.initState();
    _previewImage = widget.currentImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploading = true);

      XFile? imageFile;
      if (source == ImageSource.gallery) {
        imageFile = await ImageService.pickImageFromGallery();
      } else {
        imageFile = await ImageService.pickImageFromCamera();
      }

      if (imageFile == null) return;

      // Validar imagem
      if (!ImageService.validateImageType(imageFile.path)) {
        _showError('Tipo de arquivo não suportado. Use JPG, PNG ou WebP');
        return;
      }

        if (!(await ImageService.validateImageSize(imageFile, widget.imageType))) {
        _showError('Arquivo muito grande. Tamanho máximo: ${_getMaxSizeText()}');
        return;
      }

      // Fazer upload
      final result = await ImageService.uploadImage(
        imageType: widget.imageType,
        imageFile: imageFile,
        serviceId: widget.serviceId,
      );

      if (result['success']) {
        setState(() {
          _previewImage = imageFile!.path;
        });
        widget.onImageSelected(imageFile.path);
        _showSuccess('Imagem salva com sucesso!');
      } else {
        _showError(result['error'] ?? 'Erro ao salvar imagem');
      }
    } catch (e) {
      _showError('Erro: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeImage() async {
    try {
      setState(() => _isUploading = true);

      final result = await ImageService.deleteImage(
        imageType: widget.imageType,
        serviceId: widget.serviceId,
      );

      if (result['success']) {
        setState(() {
          _previewImage = null;
        });
        widget.onImageRemoved?.call();
        _showSuccess('Imagem removida com sucesso!');
      } else {
        _showError(result['error'] ?? 'Erro ao remover imagem');
      }
    } catch (e) {
      _showError('Erro: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecionar Imagem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
            
            if (_previewImage != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Remover Imagem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF00C977),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _isUploading ? null : _showImageSourceDialog,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Preview da imagem
            if (_previewImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _previewImage!.startsWith('data:image/')
                    ? Image.memory(
                            Uri.dataFromString(_previewImage!).data?.contentAsBytes() ?? Uint8List(0),
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        _previewImage!,
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      ),
              )
            else
              _buildPlaceholder(),
            
            // Overlay de loading
            if (_isUploading)
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                  ),
                ),
              ),
            
            // Ícone de adicionar
            if (!_isUploading && _previewImage == null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPlaceholderIcon(),
            color: secondaryTextColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            widget.placeholder ?? _getPlaceholderText(),
            style: TextStyle(
              fontSize: 10,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getPlaceholderIcon() {
    switch (widget.imageType) {
      case 'logo':
        return Icons.business;
      case 'profile_photo':
        return Icons.person;
      case 'service_photo':
        return Icons.build;
      default:
        return Icons.image;
    }
  }

  String _getPlaceholderText() {
    switch (widget.imageType) {
      case 'logo':
        return 'Logo';
      case 'profile_photo':
        return 'Foto';
      case 'service_photo':
        return 'Serviço';
      default:
        return 'Imagem';
    }
  }

  String _getMaxSizeText() {
    switch (widget.imageType) {
      case 'logo':
        return '2MB';
      case 'profile_photo':
        return '3MB';
      case 'service_photo':
        return '4MB';
      default:
        return '5MB';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
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
}
