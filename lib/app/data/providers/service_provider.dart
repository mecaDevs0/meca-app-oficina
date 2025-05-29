import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class ServiceProvider {
  ServiceProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<List<ServiceModel>> onListServices({
    required int page,
    required int limit,
    required String workshopId,
  }) async {
    final response = await _restClientDio.get(
      BaseUrls.service,
      queryParameters: {
        'page': page,
        'limit': limit,
        'dataBlocked': 0,
        'workshopId': workshopId,
      },
    );
    return (response.data as List)
        .map(
          (service) => ServiceModel.fromJson(service as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ServiceModel> onGetService(String id) async {
    final response = await _restClientDio.get('${BaseUrls.service}/$id');
    return ServiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String?> onRemoveService(String? id) async {
    final response = await _restClientDio.delete('${BaseUrls.service}/$id');
    return response.message;
  }
}
