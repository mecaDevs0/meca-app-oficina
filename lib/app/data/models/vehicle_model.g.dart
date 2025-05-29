// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) => VehicleModel(
      id: json['id'] as String?,
      plate: json['plate'] as String?,
      manufacturer: json['manufacturer'] as String? ?? '',
      model: json['model'] as String? ?? '',
    );

Map<String, dynamic> _$VehicleModelToJson(VehicleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plate': instance.plate,
      'manufacturer': instance.manufacturer,
      'model': instance.model,
    };
