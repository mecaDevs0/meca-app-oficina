import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ServicesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _masterServices = [];
  List<Map<String, dynamic>> _myServices = [];
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get masterServices => _masterServices;
  List<Map<String, dynamic>> get myServices => _myServices;
  bool get isLoading => _isLoading;
  
  Future<void> loadMasterServices() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getMasterServices();
      if (response['success']) {
        final data = response['data'];
        _masterServices = _normalizeServices(data);
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar serviços master: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMyServices() async {
    try {
      final response = await _apiService.getMyServices();
      if (response['success']) {
        final data = response['data'];
        _myServices = _normalizeServices(data);
        if (kDebugMode) {
          print('✅ Serviços carregados: ${_myServices.length}');
          for (var s in _myServices) {
            print('  - service_id: ${s['service_id']}, id: ${s['id']}');
          }
        }
        notifyListeners();
      } else {
        if (kDebugMode) print('❌ Erro ao carregar serviços: ${response['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao carregar serviços: $e');
    }
  }
  
  /// Verifica se um serviço master está selecionado (está na lista de serviços da oficina)
  /// serviceIdMaster: ID do serviço master (vem do campo 'id' dos serviços master)
  bool isServiceSelected(String serviceIdMaster) {
    if (serviceIdMaster.isEmpty) return false;
    
    final serviceIdStr = serviceIdMaster.toString();
    
    // Os serviços da oficina vêm da tabela workshop_service e têm o campo 'service_id'
    // que referencia o ID do serviço master
    final isSelected = _myServices.any((workshopService) {
      // Priorizar service_id (campo correto)
      final serviceId = workshopService['service_id']?.toString();
      if (serviceId == serviceIdStr) {
        return true;
      }
      
      // Fallback: também verificar 'id' caso a API mude a estrutura
      final id = workshopService['id']?.toString();
      if (id == serviceIdStr) {
        return true;
      }
      
      return false;
    });
    
    if (kDebugMode) {
      print('🔍 isServiceSelected($serviceIdStr) = $isSelected');
    }
    
    return isSelected;
  }
  
  /// Encontra os dados de um serviço da oficina pelo ID do serviço master
  Map<String, dynamic>? findMyServiceByMasterId(String serviceIdMaster) {
    if (serviceIdMaster.isEmpty) return null;
    
    final serviceIdStr = serviceIdMaster.toString();
    
    try {
      return _myServices.firstWhere((workshopService) {
        final serviceId = workshopService['service_id']?.toString();
        final id = workshopService['id']?.toString();
        return serviceId == serviceIdStr || id == serviceIdStr;
      });
    } catch (_) {
      return null;
    }
  }
  
  Future<void> addService(String serviceId, {double? price, int? duration}) async {
    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        if (kDebugMode) print('❌ WorkshopId não encontrado');
        return;
      }
      
      if (kDebugMode) {
        print('➕ Adicionando serviço: serviceId=$serviceId, price=$price, duration=$duration');
      }
      
      // Adicionar serviço ao workshop
      final result = await _apiService.addServiceToWorkshop(
        workshopId,
        serviceId,
        price: price,
        duration: duration,
      );
      
      if (result['success']) {
        if (kDebugMode) print('✅ Serviço adicionado com sucesso, recarregando lista...');
        // Recarregar serviços da API para garantir que temos os dados atualizados
        await loadMyServices();
      } else {
        if (kDebugMode) print('❌ Erro ao adicionar serviço: ${result['error']}');
        notifyListeners();
        throw Exception(result['error'] ?? 'Erro ao adicionar serviço');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exceção ao adicionar serviço: $e');
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> removeService(String serviceId) async {
    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) return;
      
      if (kDebugMode) {
        print('➖ Removendo serviço: serviceId=$serviceId');
      }
      
      // Remover serviço do workshop
      final result = await _apiService.removeServiceFromWorkshop(workshopId, serviceId);
      
      if (result['success']) {
        if (kDebugMode) print('✅ Serviço removido com sucesso, recarregando lista...');
        await loadMyServices();
      } else {
        if (kDebugMode) print('❌ Erro ao remover serviço: ${result['error']}');
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exceção ao remover serviço: $e');
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _normalizeServices(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (raw is Map) {
      if (raw.containsKey('services')) {
        return _normalizeServices(raw['services']);
      }
      // Alguns endpoints podem retornar mapa indexado pelo ID
      final values = raw.values
          .where((value) => value is Map)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();
      if (values.isNotEmpty) {
        return values;
      }
    }

    return [];
  }
}
