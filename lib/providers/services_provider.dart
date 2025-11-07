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
      print('Erro ao carregar serviços: $e');
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
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar meus serviços: $e');
    }
  }
  
  bool isServiceSelected(String serviceId) {
    return _myServices.any((service) => service['id'] == serviceId || service['service_id'] == serviceId);
  }
  
  Future<void> addService(String serviceId, {double? price, int? duration}) async {
    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) return;
      
      // Adicionar serviço ao workshop
      final result = await _apiService.addServiceToWorkshop(
        workshopId,
        serviceId,
        price: price,
        duration: duration,
      );
      
      if (result['success']) {
        await loadMyServices();
      }
    } catch (e) {
      print('Erro ao adicionar serviço: $e');
    }
  }
  
  Future<void> removeService(String serviceId) async {
    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) return;
      
      // Remover serviço do workshop
      final result = await _apiService.removeServiceFromWorkshop(workshopId, serviceId);
      
      if (result['success']) {
        await loadMyServices();
      }
    } catch (e) {
      print('Erro ao remover serviço: $e');
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



