import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class HomeProvider {
  HomeProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<List<ScheduleServiceModel>> getScheduleService({
    required int page,
    required int limit,
    required List<int> status,
    int? startDate,
    int? endDate,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'limit': limit,
      'status': status,
    };
    if (startDate != null) {
      queryParameters['startDate'] = startDate;
    }
    if (endDate != null) {
      queryParameters['endDate'] = endDate;
    }
    final response = await _restClientDio.get(
      BaseUrls.scheduling,
      queryParameters: queryParameters,
    );
    return (response.data as List)
        .map((e) => ScheduleServiceModel.fromJson(e))
        .toList();
  }

  Future<WorkshopModel> onUpdateWorkshop(WorkshopModel workshop) async {
    final response = await _restClientDio.patch(
      '${BaseUrls.workshop}/${workshop.id}',
      data: workshop.toJson(),
    );
    return WorkshopModel.fromJson(response.data);
  }

  Future<MegaFile> onUploadImage(File fileImage) async {
    return _restClientDio.uploadFile(
      file: fileImage,
      returnWithUrl: true,
    );
  }
}
