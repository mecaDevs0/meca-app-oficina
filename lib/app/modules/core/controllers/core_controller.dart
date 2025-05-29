import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/profile_provider.dart';

class CoreController extends GetxController {
  CoreController({required ProfileProvider profileProvider})
      : _profileProvider = profileProvider;

  final ProfileProvider _profileProvider;

  final _currentIndex = RxInt(0);
  final _isLoading = RxBool(false);
  final _loadingMessage = RxString('Carregando ...');
  final _isGettingLocation = RxBool(true);
  final _listIssues = RxList<int>.empty();
  final hasRequestPermission = RxBool(false);

  int get currentIndex => _currentIndex.value;
  bool get isLoading => _isLoading.value;
  String get loadingMessage => _loadingMessage.value;
  bool get isGettingLocation => _isGettingLocation.value;
  List<int> get listIssues => _listIssues.toList();

  set currentIndex(int value) => _currentIndex.value = value;
  set listIssues(List<int> value) => _listIssues.assignAll(value);

  Position? userPosition;

  @override
  Future<void> onInit() async {
    await getProfileInfo();
    await _checkPermission();
    super.onInit();
  }

  Future<void> getProfileInfo() async {
    _isLoading.value = true;
    _loadingMessage.value = 'Carregando informações ...';
    await MegaRequestUtils.load(
      action: () async {
        final profileInfoResponse = await _profileProvider.onGetProfileInfo();
        final String? deviceId = MegaOneSignalConfig.fromCache();
        if (deviceId != null) {
          await _profileProvider.onRegisterUnregister(
            deviceId: deviceId,
            isRegister: true,
          );
        }
        _listIssues.assignAll(profileInfoResponse.requirements);

        /// Aqui está sendo removido o 0 da lista de requisitos
        /// Pois a home já tem um banner para isso(Dados Bancários)
        if (_listIssues.contains(0)) {
          _listIssues.remove(0);
        }

        await profileInfoResponse.save();
      },
      onFinally: () => _isLoading.value = false,
    );
  }

  Future<void> _checkPermission() async {
    _isGettingLocation.value = true;
    final permission = await Permission.location.status;
    hasRequestPermission.value = permission.isGranted;

    await _getLocation();
    _isGettingLocation.value = false;
  }

  Future<void> requestPermission() async {
    _isGettingLocation.value = true;

    final status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final newStatus = await Permission.location.request();
      hasRequestPermission.value = newStatus.isGranted;
    } else {
      hasRequestPermission.value = status.isGranted;
    }

    if (hasRequestPermission.value) {
      await _getLocation();
    }

    _isGettingLocation.value = false;
  }

  Future<void> _getLocation() async {
    if (hasRequestPermission.value) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userPosition = position;
    }
  }

  Future<bool> onLogout() async {
    bool isSuccess = false;
    _isLoading.value = true;
    _loadingMessage.value = 'Saindo ...';
    await MegaRequestUtils.load(
      action: () async {
        final String? deviceId = MegaOneSignalConfig.fromCache();
        if (deviceId != null) {
          await _profileProvider.onRegisterUnregister(
            deviceId: deviceId,
            isRegister: false,
          );
        }
        await AuthToken.remove();
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }

  Future<bool> onRemoveAccount(String id) async {
    if (id == null) {
      MegaSnackbar.showErroSnackBar('Erro ao remover conta');
      return false;
    }

    bool isSuccess = false;
    _isLoading.value = true;
    _loadingMessage.value = 'Removendo conta ...';
    await MegaRequestUtils.load(
      action: () async {
        final String? deviceId = MegaOneSignalConfig.fromCache();
        if (deviceId != null) {
          await _profileProvider.onRegisterUnregister(
            deviceId: deviceId,
            isRegister: false,
          );
        }
        await _profileProvider.onRemoveAccount(id);
        await AuthToken.remove();
        isSuccess = true;
      },
      onFinally: () => _isLoading.value = false,
    );
    return isSuccess;
  }
}
