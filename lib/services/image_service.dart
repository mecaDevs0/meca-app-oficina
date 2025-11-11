import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'api_service.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final ApiService _apiService = ApiService();

  // Tipos de imagem suportados
  static const List<String> supportedTypes = ['logo', 'profile_photo', 'service_photo'];
  
  // Tamanhos máximos
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxLogoSize = 2 * 1024 * 1024; // 2MB para logos
  static const int maxProfileSize = 3 * 1024 * 1024; // 3MB para fotos de perfil
  static const int maxServiceSize = 4 * 1024 * 1024; // 4MB para fotos de serviços

  // Dimensões recomendadas
  static const Map<String, Map<String, int>> recommendedDimensions = {
    'logo': {'width': 512, 'height': 512},
    'profile_photo': {'width': 400, 'height': 400},
    'service_photo': {'width': 800, 'height': 600},
  };

  /// Selecionar imagem da galeria
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Erro ao selecionar imagem da galeria: $e');
      return null;
    }
  }

  /// Capturar imagem da câmera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Erro ao capturar imagem da câmera: $e');
      return null;
    }
  }

  /// Converter arquivo para base64
  static Future<String?> fileToBase64(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(file.path);
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Erro ao converter arquivo para base64: $e');
      return null;
    }
  }

  /// Validar tamanho da imagem
  static Future<bool> validateImageSize(XFile file, String imageType) async {
        final fileSize = await file.length();
    
    switch (imageType) {
      case 'logo':
        return fileSize <= maxLogoSize;
      case 'profile_photo':
        return fileSize <= maxProfileSize;
      case 'service_photo':
        return fileSize <= maxServiceSize;
      default:
        return fileSize <= maxFileSize;
    }
  }

  /// Validar tipo de arquivo
  static bool validateImageType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  /// Obter tipo MIME
  static String _getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Upload de imagem para o servidor
  static Future<Map<String, dynamic>> uploadImage({
    required String imageType,
    required XFile imageFile,
    String? serviceId,
  }) async {
    try {
      // Validar tipo de imagem
      if (!supportedTypes.contains(imageType)) {
        return {
          'success': false,
          'error': 'Tipo de imagem não suportado',
        };
      }

      // Validar tipo de arquivo
      if (!validateImageType(imageFile.path)) {
        return {
          'success': false,
          'error': 'Tipo de arquivo não suportado. Use JPG, PNG ou WebP',
        };
      }

      // Validar tamanho
      if (!(await validateImageSize(imageFile, imageType))) {
        return {
          'success': false,
          'error': 'Arquivo muito grande. Tamanho máximo: ${_getMaxSizeText(imageType)}',
        };
      }

      // Ler bytes da imagem
      final imageBytes = await imageFile.readAsBytes();
      
      // Comprimir imagem por tipo
      final compressedBytes = await compressImageByType(imageBytes, imageType);
      
      // Converter para base64
      final base64String = base64Encode(compressedBytes);
      final mimeType = _getMimeType(imageFile.path);
      final finalBase64String = 'data:$mimeType;base64,$base64String';

      // Upload via API
      final result = await _apiService.uploadImage(
        imageType: imageType,
        imageData: finalBase64String,
        serviceId: serviceId,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao fazer upload: $e',
      };
    }
  }

  /// Buscar imagens do servidor
  static Future<Map<String, dynamic>> getImages({
    String? imageType,
    String? serviceId,
  }) async {
    try {
      return await _apiService.getImages(
        imageType: imageType,
        serviceId: serviceId,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao buscar imagens: $e',
      };
    }
  }

  /// Deletar imagem
  static Future<Map<String, dynamic>> deleteImage({
    required String imageType,
    int? imageIndex,
    String? serviceId,
  }) async {
    try {
      return await _apiService.deleteImage(
        imageType: imageType,
        imageIndex: imageIndex,
        serviceId: serviceId,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao deletar imagem: $e',
      };
    }
  }

  /// Obter texto do tamanho máximo
  static String _getMaxSizeText(String imageType) {
    switch (imageType) {
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

  /// Obter dimensões recomendadas
  static Map<String, int> getRecommendedDimensions(String imageType) {
    return recommendedDimensions[imageType] ?? {'width': 400, 'height': 400};
  }

  /// Gerar URL de preview para base64
  static String getPreviewUrl(String base64String) {
    return base64String;
  }

  /// Validar se base64 é uma imagem válida
  static bool isValidBase64Image(String base64String) {
    try {
      if (!base64String.startsWith('data:image/')) {
        return false;
      }
      
      final base64Data = base64String.split(',')[1];
      final bytes = base64Decode(base64Data);
      
      // Verificar se é uma imagem válida pelos primeiros bytes
      if (bytes.length < 4) return false;
      
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
      
      // PNG
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
      
      // WebP
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Comprimir imagem com flutter_image_compress
  static Future<Uint8List> compressImage(Uint8List imageBytes, {int quality = 85}) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('Erro ao comprimir imagem: $e');
      return imageBytes;
    }
  }

  /// Redimensionar e comprimir imagem
  static Future<Uint8List> resizeAndCompressImage(
    Uint8List imageBytes, {
    int? width,
    int? height,
    int quality = 85,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: width ?? 800,
        minHeight: height ?? 600,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('Erro ao redimensionar e comprimir imagem: $e');
      return imageBytes;
    }
  }

  /// Comprimir imagem por tipo
  static Future<Uint8List> compressImageByType(
    Uint8List imageBytes,
    String imageType,
  ) async {
    final dimensions = recommendedDimensions[imageType] ?? {'width': 400, 'height': 400};
    final quality = _getQualityByType(imageType);
    
    return await resizeAndCompressImage(
      imageBytes,
      width: dimensions['width'],
      height: dimensions['height'],
      quality: quality,
    );
  }

  /// Obter qualidade por tipo de imagem
  static int _getQualityByType(String imageType) {
    switch (imageType) {
      case 'logo':
        return 90; // Alta qualidade para logos
      case 'profile_photo':
        return 85; // Qualidade média para fotos de perfil
      case 'service_photo':
        return 80; // Qualidade média para fotos de serviços
      default:
        return 85;
    }
  }
}
