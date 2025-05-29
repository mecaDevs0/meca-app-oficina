// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) => ServiceModel(
      estimatedTime: (json['estimatedTime'] as num?)?.toDouble(),
      workshop: json['workshop'] == null
          ? null
          : WorkshopModel.fromJson(json['workshop'] as Map<String, dynamic>),
      service: json['service'] == null
          ? null
          : DefaultServiceModel.fromJson(
              json['service'] as Map<String, dynamic>),
      quickService: json['quickService'] as bool?,
      minTimeScheduling: (json['minTimeScheduling'] as num?)?.toDouble(),
      description: json['description'] as String?,
      photo: json['photo'] as String?,
      created: (json['created'] as num?)?.toInt(),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$ServiceModelToJson(ServiceModel instance) =>
    <String, dynamic>{
      if (instance.estimatedTime case final value?) 'estimatedTime': value,
      if (instance.workshop case final value?) 'workshop': value,
      if (instance.service case final value?) 'service': value,
      if (instance.quickService case final value?) 'quickService': value,
      if (instance.minTimeScheduling case final value?)
        'minTimeScheduling': value,
      if (instance.description case final value?) 'description': value,
      if (instance.photo case final value?) 'photo': value,
      if (instance.created case final value?) 'created': value,
      if (instance.id case final value?) 'id': value,
    };
