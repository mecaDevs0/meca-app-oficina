import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';
import '../../core/controllers/core_controller.dart';

class ProfileController extends GetxController {
  ProfileController({
    required CoreController coreController,
  }) : _coreController = coreController;

  final CoreController _coreController;

  final _workshop = Rx<WorkshopModel>(WorkshopModel());
  final _isLoading = RxBool(false);

  WorkshopModel get workshop => _workshop.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    _workshop.value = WorkshopModel.fromCache();
    WorkshopModel.cacheBox.listenable().addListener(() {
      _workshop.value = WorkshopModel.fromCache();
    });
    super.onInit();
  }

  Future<bool> onRemoveAccount() async {
    if (workshop.id == null) {
      MegaSnackbar.showErroSnackBar('Erro ao remover conta');
      return false;
    }
    return _coreController.onRemoveAccount(workshop.id!);
  }

  Future<bool> onLogout() async {
    _isLoading.value = true;
    final isSuccess = _coreController.onLogout();
    _isLoading.value = false;
    return isSuccess;
  }
}
