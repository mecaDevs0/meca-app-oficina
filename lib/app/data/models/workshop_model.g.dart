// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkshopModelAdapter extends TypeAdapter<WorkshopModel> {
  @override
  final int typeId = 0;

  @override
  WorkshopModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkshopModel(
      id: fields[0] as String?,
      fullName: fields[1] as String?,
      companyName: fields[2] as String?,
      phone: fields[3] as String?,
      cnpj: fields[4] as String?,
      zipCode: fields[5] as String?,
      streetAddress: fields[6] as String?,
      number: fields[7] as String?,
      cityName: fields[8] as String?,
      cityId: fields[9] as String?,
      stateName: fields[10] as String?,
      stateUf: fields[11] as String?,
      stateId: fields[12] as String?,
      neighborhood: fields[13] as String?,
      complement: fields[14] as String?,
      latitude: fields[15] as double?,
      longitude: fields[16] as double?,
      openingHours: fields[17] as String?,
      photo: fields[18] as String?,
      meiCard: fields[19] as String?,
      email: fields[20] as String?,
      requirements: (fields[21] as List).cast<int>(),
      fileDocument: fields[22] as String?,
      birthDate: fields[23] as String?,
      cpf: fields[24] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkshopModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.companyName)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.cnpj)
      ..writeByte(5)
      ..write(obj.zipCode)
      ..writeByte(6)
      ..write(obj.streetAddress)
      ..writeByte(7)
      ..write(obj.number)
      ..writeByte(8)
      ..write(obj.cityName)
      ..writeByte(9)
      ..write(obj.cityId)
      ..writeByte(10)
      ..write(obj.stateName)
      ..writeByte(11)
      ..write(obj.stateUf)
      ..writeByte(12)
      ..write(obj.stateId)
      ..writeByte(13)
      ..write(obj.neighborhood)
      ..writeByte(14)
      ..write(obj.complement)
      ..writeByte(15)
      ..write(obj.latitude)
      ..writeByte(16)
      ..write(obj.longitude)
      ..writeByte(17)
      ..write(obj.openingHours)
      ..writeByte(18)
      ..write(obj.photo)
      ..writeByte(19)
      ..write(obj.meiCard)
      ..writeByte(20)
      ..write(obj.email)
      ..writeByte(21)
      ..write(obj.requirements)
      ..writeByte(22)
      ..write(obj.fileDocument)
      ..writeByte(23)
      ..write(obj.birthDate)
      ..writeByte(24)
      ..write(obj.cpf);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkshopModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkshopModel _$WorkshopModelFromJson(Map<String, dynamic> json) =>
    WorkshopModel(
      id: json['id'] as String?,
      fullName: json['fullName'] as String?,
      companyName: json['companyName'] as String?,
      phone: json['phone'] as String?,
      cnpj: json['cnpj'] as String?,
      zipCode: json['zipCode'] as String?,
      streetAddress: json['streetAddress'] as String?,
      number: json['number'] as String?,
      cityName: json['cityName'] as String?,
      cityId: json['cityId'] as String?,
      stateName: json['stateName'] as String?,
      stateUf: json['stateUf'] as String?,
      stateId: json['stateId'] as String?,
      neighborhood: json['neighborhood'] as String?,
      complement: json['complement'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      openingHours: json['openingHours'] as String?,
      photo: json['photo'] as String?,
      meiCard: json['meiCard'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      dataBankValid: json['dataBankValid'] as bool?,
      workshopAgendaValid: json['workshopAgendaValid'] as bool?,
      workshopServicesValid: json['workshopServicesValid'] as bool?,
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      fileDocument: json['fileDocument'] as String?,
      birthDate: json['birthDate'] as String?,
      cpf: json['cpf'] as String?,
    );

Map<String, dynamic> _$WorkshopModelToJson(WorkshopModel instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.fullName case final value?) 'fullName': value,
      if (instance.companyName case final value?) 'companyName': value,
      if (instance.phone case final value?) 'phone': value,
      if (instance.cnpj case final value?) 'cnpj': value,
      if (instance.zipCode case final value?) 'zipCode': value,
      if (instance.streetAddress case final value?) 'streetAddress': value,
      if (instance.number case final value?) 'number': value,
      if (instance.cityName case final value?) 'cityName': value,
      if (instance.cityId case final value?) 'cityId': value,
      if (instance.stateName case final value?) 'stateName': value,
      if (instance.stateUf case final value?) 'stateUf': value,
      if (instance.stateId case final value?) 'stateId': value,
      if (instance.neighborhood case final value?) 'neighborhood': value,
      if (instance.complement case final value?) 'complement': value,
      if (instance.latitude case final value?) 'latitude': value,
      if (instance.longitude case final value?) 'longitude': value,
      if (instance.openingHours case final value?) 'openingHours': value,
      if (instance.photo case final value?) 'photo': value,
      if (instance.meiCard case final value?) 'meiCard': value,
      if (instance.email case final value?) 'email': value,
      if (instance.password case final value?) 'password': value,
      if (instance.dataBankValid case final value?) 'dataBankValid': value,
      if (instance.workshopAgendaValid case final value?)
        'workshopAgendaValid': value,
      if (instance.workshopServicesValid case final value?)
        'workshopServicesValid': value,
      if (instance.fileDocument case final value?) 'fileDocument': value,
      if (instance.birthDate case final value?) 'birthDate': value,
      if (instance.cpf case final value?) 'cpf': value,
    };
