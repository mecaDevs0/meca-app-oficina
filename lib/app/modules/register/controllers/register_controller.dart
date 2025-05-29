import 'dart:developer';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../../../data/data.dart';
import '../../../data/providers/register_provider.dart';

class RegisterController extends GetxController {
  RegisterController({
    required RegisterProvider registerProvider,
    required FormAddressController formAddressController,
  })  : _registerProvider = registerProvider,
        _formAddressController = formAddressController;

  final RegisterProvider _registerProvider;
  final FormAddressController _formAddressController;

  final _stepRegister = Rx<StepRegister>(StepRegister.establishment);
  final _logoFile = Rx<File?>(null);
  final _cardMeiFile = Rx<File?>(null);
  final _isLoading = RxBool(false);
  final _isPolicyTermChecked = RxBool(false);

  StepRegister get stepRegister => _stepRegister.value;
  File? get logoFile => _logoFile.value;
  File? get cardMeiFile => _cardMeiFile.value;
  bool get isLoading => _isLoading.value;
  bool get isPolicyTermChecked => _isPolicyTermChecked.value;

  set logoFile(File? value) => _logoFile.value = value;
  set cardMeiFile(File? value) => _cardMeiFile.value = value;
  set isPolicyTermChecked(bool value) => _isPolicyTermChecked.value = value;

  final List<StepRegister> _steps = [
    StepRegister.establishment,
    StepRegister.address,
    StepRegister.responsible,
  ];
  WorkshopModel workshop = WorkshopModel();

  void nextStep() {
    final currentIndex = _steps.indexOf(stepRegister);
    if (currentIndex < _steps.length - 1) {
      _stepRegister.value = _steps[currentIndex + 1];
    }
  }

  void previousStep() {
    final currentIndex = _steps.indexOf(stepRegister);
    if (currentIndex > 0) {
      _stepRegister.value = _steps[currentIndex - 1];
    }
  }

  Future<bool> onRegisterWorkshop(WorkshopModel workshop) async {
    _isLoading.value = true;
    bool isSuccess = false;
    log('onRegisterWorkshop: ${workshop.toJson()}');
    await MegaRequestUtils.load(
      action: () async {
        if (logoFile != null) {
          final logoPath = await onUploadImage(logoFile!);
          workshop = workshop.copyWith(photo: logoPath);
        }
        if (cardMeiFile != null) {
          final cardMeiPath = await onUploadImage(cardMeiFile!);
          workshop = workshop.copyWith(meiCard: cardMeiPath);
        }
        log('onRegisterWorkshop ||: ${workshop.toJson()}');
        await _registerProvider.onRegisterWorkshop(workshop);
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }

  Future<String?> onUploadImage(File file) async {
    final response = await _registerProvider.onUploadImage(file);
    return response.fileName;
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
  }
}
