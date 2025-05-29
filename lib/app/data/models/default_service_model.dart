import 'package:json_annotation/json_annotation.dart';

part 'default_service_model.g.dart';

@JsonSerializable()
class DefaultServiceModel {
  DefaultServiceModel({
    required this.id,
    required this.name,
  });

  factory DefaultServiceModel.fromJson(Map<String, dynamic> json) =>
      _$DefaultServiceModelFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _$DefaultServiceModelToJson(this);
}
