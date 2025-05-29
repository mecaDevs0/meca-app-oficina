import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/app_urls.dart';
import '../models/schedule_service_model.dart';

class ServiceFailedProvider {
  ServiceFailedProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<ScheduleServiceModel> onScheduleDetail(String id) async {
    final response = await _restClientDio.get('${BaseUrls.scheduling}/$id');
    return ScheduleServiceModel.fromJson(response.data);
  }

  Future<void> onSuggestFreeRepair(String schedulingId) async {
    await _restClientDio.post(
      BaseUrls.suggestFreeRepair,
      queryParameters: {'schedulingId': schedulingId},
    );
  }

  Future<void> onDisputeFailedService({
    required String schedulingId,
    required String dispute,
    required List<String> imagesDispute,
  }) async {
    await _restClientDio.post(
      BaseUrls.disputeDisapprovedService,
      data: {
        'schedulingId': schedulingId,
        'dispute': dispute,
        if (imagesDispute.isNotEmpty) 'imagesDispute': imagesDispute,
      },
    );
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
