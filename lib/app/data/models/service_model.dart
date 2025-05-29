import 'package:json_annotation/json_annotation.dart';

import '../data.dart';

part 'service_model.g.dart';

@JsonSerializable(includeIfNull: false)
class ServiceModel {
  ServiceModel({
    this.estimatedTime,
    this.workshop,
    this.service,
    this.quickService,
    this.minTimeScheduling,
    this.description,
    this.photo,
    this.created,
    this.id,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return _$ServiceModelFromJson(json);
  }

  double? estimatedTime;
  WorkshopModel? workshop;
  DefaultServiceModel? service;
  bool? quickService;
  double? minTimeScheduling;
  String? description;
  String? photo;
  int? created;
  String? id;

  Map<String, dynamic> toJson() => _$ServiceModelToJson(this);

  ServiceModel copyWith({
    double? estimatedTime,
    WorkshopModel? workshop,
    DefaultServiceModel? service,
    bool? quickService,
    double? minTimeScheduling,
    String? description,
    String? photo,
    int? created,
    String? id,
  }) {
    return ServiceModel(
      estimatedTime: estimatedTime ?? this.estimatedTime,
      workshop: workshop ?? this.workshop,
      service: service ?? this.service,
      quickService: quickService ?? this.quickService,
      minTimeScheduling: minTimeScheduling ?? this.minTimeScheduling,
      description: description ?? this.description,
      photo: photo ?? this.photo,
      created: created ?? this.created,
      id: id ?? this.id,
    );
  }
}
