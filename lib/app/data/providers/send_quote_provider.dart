import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../models/budget_service_model.dart';
import '../models/schedule_service_model.dart';

class SendQuoteProvider {
  SendQuoteProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<void> onSendQuote({
    required String schedulingId,
    required double diagnosticValue,
    required int estimatedTimeForCompletion,
    List<String>? budgetImages,
    required List<BudgetServiceModel> budgetServices,
  }) async {
    await _restClientDio.post(
      BaseUrls.sendBudget,
      data: {
        'schedulingId': schedulingId,
        'diagnosticValue': diagnosticValue,
        'estimatedTimeForCompletion': estimatedTimeForCompletion,
        'budgetImages': budgetImages,
        'budgetServices': budgetServices,
      },
    );
  }

  Future<ScheduleServiceModel> onScheduleDetail(String id) async {
    final response = await _restClientDio.get('${BaseUrls.scheduling}/$id');
    return ScheduleServiceModel.fromJson(response.data);
  }

  Future<List<String>> uploadFiles(List<File> selectedImages) async {
    final response = await _restClientDio.uploadFiles(
      files: selectedImages,
      returnWithUrl: true,
    );

    if (response.fileNames?.isEmpty ?? true) {
      return [];
    }

    return response.fileNames!;
  }
}
