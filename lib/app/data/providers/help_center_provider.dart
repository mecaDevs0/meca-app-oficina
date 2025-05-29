import 'package:mega_commons/mega_commons.dart';

import '../../core/app_urls.dart';

class HelpCenterProvider {
  HelpCenterProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<MegaResponse> onSendHelp({
    required String title,
    required String description,
  }) async {
    final response = await _restClientDio.post(
      BaseUrls.helpCenter,
      data: {
        'question': title,
        'response': description,
      },
    );
    return response;
  }
}
