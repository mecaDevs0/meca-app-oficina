import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  ProfileModel({this.id, this.fullName, this.email, this.phone});

  ProfileModel.empty()
      : id = '',
        fullName = '',
        email = '',
        phone = '';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return _$ProfileModelFromJson(json);
  }

  dynamic id;
  String? fullName;
  String? email;
  String? phone;

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
