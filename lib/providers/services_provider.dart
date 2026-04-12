import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ServicesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _masterServices = [];
  List<Map<String, dynamic>> _myServices = [];
  bool _isLoading = false;
  // Lock anti double-tap: IDs master de serviços que estão sendo mutados agora.
  final Set<String> _mutating = <String>{};

  List<Map<String, dynamic>> get masterServices => _masterServices;
  List<Map<String, dynamic>> get myServices => _myServices;
  bool get isLoading => _isLoading;
  bool isMutating(String serviceId) => _mutating.contains(serviceId);
  
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
    final serviceIdStr = serviceId.toString();
    if (serviceIdStr.isEmpty) return;

    // Lock anti double-tap: se já está mutando esse serviço, ignora.
    if (_mutating.contains(serviceIdStr)) {
      if (kDebugMode) print('⏭️  addService ignorado — já em andamento: $serviceIdStr');
      return;
    }
    _mutating.add(serviceIdStr);

    // Backup para rollback em caso de falha
    final previousList = List<Map<String, dynamic>>.from(_myServices);

    // Atualização otimista: adicionar na lista local e notificar.
    _myServices.removeWhere((s) => s['service_id']?.toString() == serviceIdStr);
    _myServices.add({
      'service_id': serviceIdStr,
      'price': price,
      'duration': duration,
    });
    notifyListeners();

    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        if (kDebugMode) print('❌ WorkshopId não encontrado');
        _myServices = previousList;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('➕ Adicionando serviço: serviceId=$serviceIdStr, price=$price, duration=$duration');
      }

      final result = await _apiService.addServiceToWorkshop(
        workshopId,
        serviceIdStr,
        price: price,
        duration: duration,
      );

      if (result['success']) {
        if (kDebugMode) print('✅ Serviço adicionado com sucesso, merge local');
        // Merge local com o row real retornado pelo POST, sem precisar fazer
        // GET /services de novo (que poderia sobrescrever outras mutações
        // pendentes ou trazer dados fora de ordem).
        final row = result['data'];
        if (row is Map) {
          _myServices.removeWhere((s) => s['service_id']?.toString() == serviceIdStr);
          _myServices.add(Map<String, dynamic>.from(row));
        }
        notifyListeners();
      } else {
        if (kDebugMode) print('❌ Erro ao adicionar serviço: ${result['error']}');
        _myServices = previousList;
        notifyListeners();
        throw Exception(result['error'] ?? 'Erro ao adicionar serviço');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exceção ao adicionar serviço: $e');
      _myServices = previousList;
      notifyListeners();
      rethrow;
    } finally {
      _mutating.remove(serviceIdStr);
      notifyListeners();
    }
  }

  Future<void> removeService(String serviceId) async {
    final serviceIdStr = serviceId.toString();
    if (serviceIdStr.isEmpty) return;

    if (_mutating.contains(serviceIdStr)) {
      if (kDebugMode) print('⏭️  removeService ignorado — já em andamento: $serviceIdStr');
      return;
    }
    _mutating.add(serviceIdStr);

    final previousList = List<Map<String, dynamic>>.from(_myServices);

    _myServices.removeWhere((ws) {
      final sid = ws['service_id']?.toString();
      final id = ws['id']?.toString();
      return sid == serviceIdStr || id == serviceIdStr;
    });
    notifyListeners();

    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        _myServices = previousList;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('➖ Removendo serviço: serviceId=$serviceIdStr');
      }

      final result = await _apiService.removeServiceFromWorkshop(workshopId, serviceIdStr);

      if (result['success']) {
        if (kDebugMode) print('✅ Serviço removido com sucesso');
        // Mantém estado otimista — não recarrega.
      } else {
        if (kDebugMode) print('❌ Erro ao remover serviço: ${result['error']}');
        _myServices = previousList;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exceção ao remover serviço: $e');
      _myServices = previousList;
      notifyListeners();
    } finally {
      _mutating.remove(serviceIdStr);
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
