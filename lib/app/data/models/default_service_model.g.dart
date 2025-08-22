// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefaultServiceModel _$DefaultServiceModelFromJson(Map<String, dynamic> json) =>
    DefaultServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      quickService: json['quickService'] as bool?,
      minTimeScheduling: (json['minTimeScheduling'] as num?)?.toDouble(),
      description: json['description'] as String?,
      photo: json['photo'] as String?,
      dataBlocked: (json['dataBlocked'] as num?)?.toInt(),
      disabled: (json['disabled'] as num?)?.toInt(),
      created: (json['created'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DefaultServiceModelToJson(
        DefaultServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quickService': instance.quickService,
      'minTimeScheduling': instance.minTimeScheduling,
      'description': instance.description,
      'photo': instance.photo,
      'dataBlocked': instance.dataBlocked,
      'disabled': instance.disabled,
      'created': instance.created,
    };
