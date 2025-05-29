import 'dart:developer';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../../../data/data.dart';
import '../../../data/providers/edit_profile_provider.dart';

class EditProfileController extends GetxController {
  EditProfileController({
    required EditProfileProvider editProfileProvider,
    required FormAddressController formAddressController,
  })  : _editProfileProvider = editProfileProvider,
        _formAddressController = formAddressController;

  final EditProfileProvider _editProfileProvider;
  final FormAddressController _formAddressController;

  final _stepRegister = Rx<StepRegister>(StepRegister.establishment);
  final _fileLogo = Rx<File?>(null);
  final _fileMeiCard = Rx<File?>(null);
  final _isPickUpAndReturn = RxBool(false);
  final _isLoading = RxBool(false);

  StepRegister get stepRegister => _stepRegister.value;
  File? get fileLogo => _fileLogo.value;
  File? get fileMeiCard => _fileMeiCard.value;
  bool get isPickUpAndReturn => _isPickUpAndReturn.value;
  bool get isLoading => _isLoading.value;

  set stepRegister(StepRegister value) => _stepRegister.value = value;
  set fileLogo(File? value) => _fileLogo.value = value;
  set fileMeiCard(File? value) => _fileMeiCard.value = value;

  WorkshopModel workshop = WorkshopModel.fromCache();

  @override
  void onInit() {
    _populateAddress();
    if (!workshop.meiCard.isNullOrEmpty) {
      fileMeiCard = File('');
    }
    super.onInit();
  }

  void _populateAddress() {
    _formAddressController.setAddress(
      Address(
        streetAddress: workshop.streetAddress ?? '',
        number: workshop.number ?? '',
        complement: workshop.complement ?? '',
        neighborhood: workshop.neighborhood ?? '',
        cityName: workshop.cityName ?? '',
        stateName: workshop.stateName ?? '',
        zipCode: workshop.zipCode?.length == 8
            ? UtilBrasilFields.obterCep(workshop.zipCode!)
            : workshop.zipCode,
        cityId: workshop.cityId ?? '',
        stateId: workshop.stateId ?? '',
        stateUf: workshop.stateUf ?? '',
      ),
    );
  }

  void togglePickUpAndReturn() {
    _isPickUpAndReturn.toggle();
  }

  Future<(double lat, double long)> getLatLngFromAddress(String address) async {
    try {
      final List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final double latitude = locations.first.latitude;
        final double longitude = locations.first.longitude;

        return (latitude, longitude);
      }
      return (0.0, 0.0);
    } catch (e) {
      log('Error getLatLngFromAddress: $e');
      return (0.0, 0.0);
    }
  }

  Future<void> populateAddress() async {
    final address = _formAddressController.address;
    final location =
        await getLatLngFromAddress(address.formattedAddressWithState);

    final saveWorkshop = workshop.copyWith(
      zipCode: address.zipCode,
      streetAddress: address.streetAddress,
      number: address.number,
      complement: address.complement,
      neighborhood: address.neighborhood,
      stateId: address.stateId,
      stateName: address.stateName,
      cityId: address.cityId,
      cityName: address.cityName,
      stateUf: address.stateUf,
      latitude: location.$1,
      longitude: location.$2,
    );
    workshop = saveWorkshop;
    await onEditWorkshop(saveWorkshop);
  }

  Future<void> onEditWorkshop(WorkshopModel workshop) async {
    _isLoading.value = true;
    await MegaRequestUtils.load(
      action: () async {
        if (fileLogo?.path.isFile == true) {
          final logo = await onUploadFile(fileLogo!.path);
          workshop.photo = logo;
        }
        if (fileMeiCard?.path.isFile == true) {
          final meiCard = await onUploadFile(fileMeiCard!.path);
          workshop.meiCard = meiCard;
        }
        final response = await _editProfileProvider.onUpdateWorkshop(workshop);
        await response.save();
      },
      onFinally: () => _isLoading.value = false,
    );
  }

  Future<String?> onUploadFile(String path) async {
    final fileImage = File(path);
    final response = await _editProfileProvider.onUploadImage(fileImage);
    return response.fileName;
  }
}
