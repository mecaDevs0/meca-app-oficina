// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleHistoryModel _$ScheduleHistoryModelFromJson(
        Map<String, dynamic> json) =>
    ScheduleHistoryModel(
      statusTitle: (json['statusTitle'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      description: json['description'] as String?,
      schedulingId: json['schedulingId'] as String?,
      created: (json['created'] as num?)?.toInt(),
      id: json['id'] as String,
    );

Map<String, dynamic> _$ScheduleHistoryModelToJson(
        ScheduleHistoryModel instance) =>
    <String, dynamic>{
      'statusTitle': instance.statusTitle,
      'status': instance.status,
      'description': instance.description,
      'schedulingId': instance.schedulingId,
      'created': instance.created,
      'id': instance.id,
    };
