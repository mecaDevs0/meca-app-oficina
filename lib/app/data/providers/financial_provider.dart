import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class FinancialProvider {
  FinancialProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<List<FinancialModel>> onListFinancial({
    required int page,
    required int limit,
    int? startDate,
    int? endDate,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'limit': limit,
    };
    if (startDate != null) {
      queryParameters['startDate'] = startDate;
    }
    if (endDate != null) {
      queryParameters['endDate'] = endDate;
    }
    final response = await _restClientDio.get(
      BaseUrls.financial,
      queryParameters: queryParameters,
    );
    final dataList = response.data as List;
    return dataList
        .map(
          (financial) =>
              FinancialModel.fromJson(financial as Map<String, dynamic>),
        )
        .toList();
  }
}
