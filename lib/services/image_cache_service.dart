import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static const String _cacheKey = 'image_cache';
  static const int _maxCacheSize = 100; // Máximo de 100 imagens em cache
  static const int _maxCacheAge = 7; // 7 dias

  /// Salvar imagem em cache local
  static Future<void> cacheImage(String key, String base64Data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey) ?? '{}';
      final Map<String, dynamic> cache = jsonDecode(cacheData);
      
      // Adicionar timestamp
      cache[key] = {
        'data': base64Data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Limitar tamanho do cache
      if (cache.length > _maxCacheSize) {
        _cleanOldCache(cache);
      }
      
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      print('Erro ao salvar imagem em cache: $e');
    }
  }

  /// Recuperar imagem do cache
  static Future<String?> getCachedImage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey) ?? '{}';
      final Map<String, dynamic> cache = jsonDecode(cacheData);
      
      if (cache.containsKey(key)) {
        final imageData = cache[key];
        final timestamp = imageData['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Verificar se não expirou
        if (now - timestamp < _maxCacheAge * 24 * 60 * 60 * 1000) {
          return imageData['data'] as String;
        } else {
          // Remover se expirou
          cache.remove(key);
          await prefs.setString(_cacheKey, jsonEncode(cache));
        }
      }
      
      return null;
    } catch (e) {
      print('Erro ao recuperar imagem do cache: $e');
      return null;
    }
  }

  /// Limpar cache antigo
  static void _cleanOldCache(Map<String, dynamic> cache) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];
    
    cache.forEach((key, value) {
      final timestamp = value['timestamp'] as int;
      if (now - timestamp > _maxCacheAge * 24 * 60 * 60 * 1000) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      cache.remove(key);
    }
    
    // Se ainda estiver muito grande, remover os mais antigos
    if (cache.length > _maxCacheSize) {
      final sortedEntries = cache.entries.toList()
        ..sort((a, b) => (a.value['timestamp'] as int).compareTo(b.value['timestamp'] as int));
      
      final toRemove = sortedEntries.take(cache.length - _maxCacheSize);
      for (final entry in toRemove) {
        cache.remove(entry.key);
      }
    }
  }

  /// Limpar todo o cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }

  /// Obter estatísticas do cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey) ?? '{}';
      final Map<String, dynamic> cache = jsonDecode(cacheData);
      
      int totalSize = 0;
      int expiredCount = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      cache.forEach((key, value) {
        final data = value['data'] as String;
        totalSize += data.length;
        
        final timestamp = value['timestamp'] as int;
        if (now - timestamp > _maxCacheAge * 24 * 60 * 60 * 1000) {
          expiredCount++;
        }
      });
      
      return {
        'totalImages': cache.length,
        'totalSize': totalSize,
        'expiredImages': expiredCount,
        'maxSize': _maxCacheSize,
        'maxAge': _maxCacheAge,
      };
    } catch (e) {
      print('Erro ao obter estatísticas do cache: $e');
      return {};
    }
  }

  /// Widget para exibir imagem com cache
  static Widget cachedImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    // Se for base64, usar Image.memory
    if (imageUrl.startsWith('data:image/')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          Uri.dataFromString(imageUrl).data.contentAsBytes(),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildDefaultErrorWidget(width, height);
          },
        ),
      );
    }
    
    // Se for URL, usar CachedNetworkImage
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(width, height),
        errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(width, height),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 600,
      ),
    );
  }

  /// Widget de placeholder padrão
  static Widget _buildDefaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Widget de erro padrão
  static Widget _buildDefaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Color(0xFF8B8B8B),
          size: 32,
        ),
      ),
    );
  }

  /// Otimizar cache (remover imagens expiradas)
  static Future<void> optimizeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey) ?? '{}';
      final Map<String, dynamic> cache = jsonDecode(cacheData);
      
      _cleanOldCache(cache);
      
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      print('Erro ao otimizar cache: $e');
    }
  }

  /// Verificar se imagem está em cache
  static Future<bool> isImageCached(String key) async {
    final cachedImage = await getCachedImage(key);
    return cachedImage != null;
  }

  /// Obter tamanho do cache em MB
  static Future<double> getCacheSizeInMB() async {
    try {
      final stats = await getCacheStats();
      final totalSize = stats['totalSize'] as int? ?? 0;
      return totalSize / (1024 * 1024); // Converter para MB
    } catch (e) {
      return 0.0;
    }
  }
}








