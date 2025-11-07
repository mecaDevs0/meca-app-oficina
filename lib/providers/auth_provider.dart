import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _oficinaData;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? get oficinaData => _oficinaData;
  bool get isLoading => _isLoading;
  
  void setOficinaData(Map<String, dynamic>? data) {
    _oficinaData = data;
    notifyListeners();
  }
  
  Future<bool> updateWorkshop(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final result = await _apiService.updateWorkshop(workshopId, data);
      
      if (result['success']) {
        // Atualizar dados locais
        if (result['data'] != null) {
          _oficinaData = result['data'];
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void clear() {
    _oficinaData = null;
    notifyListeners();
  }
}



