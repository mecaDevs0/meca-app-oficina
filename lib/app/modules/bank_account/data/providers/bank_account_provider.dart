import 'package:mega_commons/mega_commons.dart';

import '../../../../core/core.dart';

class BankAccountProvider {
  BankAccountProvider({
    required RestClientDio restClientDio,
    required RestClientDio megaApi,
  }) : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<Map<String, dynamic>> getBankData() async {
    final response = await _restClientDio.get(BaseUrls.dataBank);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateBankData({
    required Map<String, dynamic> bankData,
  }) async {
    await _restClientDio.patch(
      BaseUrls.updateDataBank,
      data: bankData,
    );
  }
}
