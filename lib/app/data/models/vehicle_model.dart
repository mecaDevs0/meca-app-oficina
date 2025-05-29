import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model.g.dart';

@JsonSerializable()
class VehicleModel {
  VehicleModel({
    this.id,
    this.plate,
    required this.manufacturer,
    required this.model,
  });

  VehicleModel.empty()
      : id = '',
        plate = '',
        manufacturer = '',
        model = '';

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return _$VehicleModelFromJson(json);
  }
  String? id;
  String? plate;
  @JsonKey(defaultValue: '')
  String manufacturer;
  @JsonKey(defaultValue: '')
  String model;

  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);
}
