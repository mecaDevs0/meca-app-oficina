import 'package:json_annotation/json_annotation.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

part 'workshop_model.g.dart';

@JsonSerializable(includeIfNull: false)
@HiveType(typeId: 0)
class WorkshopModel {
  WorkshopModel({
    this.id,
    this.fullName,
    this.companyName,
    this.phone,
    this.cnpj,
    this.zipCode,
    this.streetAddress,
    this.number,
    this.cityName,
    this.cityId,
    this.stateName,
    this.stateUf,
    this.stateId,
    this.neighborhood,
    this.complement,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.photo,
    this.meiCard,
    this.email,
    this.password,
    this.dataBankValid,
    this.workshopAgendaValid,
    this.workshopServicesValid,
    this.requirements = const [],
    this.fileDocument,
    this.birthDate,
    this.cpf,
  });

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    return _$WorkshopModelFromJson(json);
  }

  WorkshopModel.empty()
      : id = '',
        fullName = '',
        companyName = '',
        phone = '',
        cnpj = '',
        zipCode = '',
        streetAddress = '',
        number = '',
        cityName = '',
        cityId = '',
        stateName = '',
        stateUf = '',
        stateId = '',
        neighborhood = '',
        complement = '',
        latitude = 0,
        longitude = 0,
        openingHours = '',
        photo = null,
        meiCard = null,
        email = null,
        password = null,
        dataBankValid = false,
        workshopAgendaValid = false,
        workshopServicesValid = false,
        requirements = [];

  WorkshopModel copyWith({
    String? id,
    String? fullName,
    String? companyName,
    String? phone,
    String? cnpj,
    String? zipCode,
    String? streetAddress,
    String? number,
    String? cityName,
    String? cityId,
    String? stateName,
    String? stateUf,
    String? stateId,
    String? neighborhood,
    String? complement,
    double? latitude,
    double? longitude,
    String? openingHours,
    String? photo,
    String? meiCard,
    String? email,
    String? password,
  }) {
    return WorkshopModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      cnpj: cnpj ?? this.cnpj,
      zipCode: zipCode ?? this.zipCode,
      streetAddress: streetAddress ?? this.streetAddress,
      number: number ?? this.number,
      cityName: cityName ?? this.cityName,
      cityId: cityId ?? this.cityId,
      stateName: stateName ?? this.stateName,
      stateUf: stateUf ?? this.stateUf,
      stateId: stateId ?? this.stateId,
      neighborhood: neighborhood ?? this.neighborhood,
      complement: complement ?? this.complement,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingHours: openingHours ?? this.openingHours,
      photo: photo ?? this.photo,
      meiCard: meiCard ?? this.meiCard,
      email: email ?? this.email,
      password: password ?? this.password,
      dataBankValid: dataBankValid ?? dataBankValid,
      workshopAgendaValid: workshopAgendaValid ?? workshopAgendaValid,
      workshopServicesValid: workshopServicesValid ?? workshopServicesValid,
      requirements: requirements,
      fileDocument: fileDocument ?? fileDocument,
      birthDate: birthDate ?? birthDate,
      cpf: cpf ?? cpf,
    );
  }

  @HiveField(0)
  String? id;
  @HiveField(1)
  String? fullName;
  @HiveField(2)
  String? companyName;
  @HiveField(3)
  String? phone;
  @HiveField(4)
  String? cnpj;
  @HiveField(5)
  String? zipCode;
  @HiveField(6)
  String? streetAddress;
  @HiveField(7)
  String? number;
  @HiveField(8)
  String? cityName;
  @HiveField(9)
  String? cityId;
  @HiveField(10)
  String? stateName;
  @HiveField(11)
  String? stateUf;
  @HiveField(12)
  String? stateId;
  @HiveField(13)
  String? neighborhood;
  @HiveField(14)
  String? complement;
  @HiveField(15)
  double? latitude;
  @HiveField(16)
  double? longitude;
  @HiveField(17)
  String? openingHours;
  @HiveField(18)
  String? photo;
  @HiveField(19)
  String? meiCard;
  @HiveField(20)
  String? email;
  String? password;
  bool? dataBankValid;
  bool? workshopAgendaValid;
  bool? workshopServicesValid;
  @HiveField(21)
  @JsonKey(includeToJson: false)
  List<int> requirements;
  @HiveField(22)
  String? fileDocument;
  @HiveField(23)
  String? birthDate;
  @HiveField(24)
  String? cpf;

  Map<String, dynamic> toJson() => _$WorkshopModelToJson(this);

  static const String _key = 'workshop';
  static Box<WorkshopModel> get cacheBox => MegaDataCache.box<WorkshopModel>();

  Future<void> save() async {
    await cacheBox.put(_key, this);
  }

  static Future<void> remove() async {
    await cacheBox.delete(_key);
  }

  static WorkshopModel fromCache() {
    return cacheBox.get(_key) ?? WorkshopModel.empty();
  }
}
