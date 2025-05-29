// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkshopServiceModel _$WorkshopServiceModelFromJson(
        Map<String, dynamic> json) =>
    WorkshopServiceModel(
      id: json['id'] as String?,
      service: json['service'] == null
          ? null
          : WorkshopServiceAuxModel.fromJson(
              json['service'] as Map<String, dynamic>),
      minTimeScheduling: (json['minTimeScheduling'] as num?)?.toDouble(),
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WorkshopServiceModelToJson(
        WorkshopServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service': instance.service,
      'minTimeScheduling': instance.minTimeScheduling,
      'value': instance.value,
    };
