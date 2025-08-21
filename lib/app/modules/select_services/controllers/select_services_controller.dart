import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';
import '../../../data/providers/create_service_provider.dart';

class SelectServicesController extends GetxController {
  SelectServicesController({
    required CreateServiceProvider createServiceProvider,
  }) : _createServiceProvider = createServiceProvider;

  final CreateServiceProvider _createServiceProvider;

  final _isLoading = RxBool(false);
  final _isLoadingServices = RxBool(false);
  final _defaultServices = RxList<DefaultServiceModel>.empty();
  final _selectedServiceIds = RxSet<String>();
  final _selectAll = RxBool(false);

  bool get isLoading => _isLoading.value;
  bool get isLoadingServices => _isLoadingServices.value;
  List<DefaultServiceModel> get defaultServices => _defaultServices.toList();
  List<DefaultServiceModel> get selectedServices => _defaultServices
      .where((service) => _selectedServiceIds.contains(service.id))
      .toList();
  bool get selectAll => _selectAll.value;

  @override
  Future<void> onInit() async {
    await _fetchDefaultServices();
    super.onInit();
  }

  Future<void> _fetchDefaultServices() async {
    _isLoadingServices.value = true;
    await MegaRequestUtils.load(
      action: () async {
        final response = await _createServiceProvider.getDefaultServices();
        _defaultServices.assignAll(response);
      },
      onFinally: () => _isLoadingServices.value = false,
    );
  }

  void toggleServiceSelection(DefaultServiceModel service) {
    if (_selectedServiceIds.contains(service.id)) {
      _selectedServiceIds.remove(service.id);
    } else {
      _selectedServiceIds.add(service.id);
    }
    _updateSelectAllState();
  }

  void toggleSelectAll() {
    if (_selectAll.value) {
      _selectedServiceIds.clear();
      _selectAll.value = false;
    } else {
      _selectedServiceIds.addAll(_defaultServices.map((service) => service.id));
      _selectAll.value = true;
    }
  }

  void _updateSelectAllState() {
    _selectAll.value = _selectedServiceIds.length == _defaultServices.length;
  }

  bool isServiceSelected(DefaultServiceModel service) {
    return _selectedServiceIds.contains(service.id);
  }

  Future<bool> saveSelectedServices() async {
    if (_selectedServiceIds.isEmpty) {
      MegaSnackbar.showErroSnackBar(
        'Selecione pelo menos um serviço',
        title: 'Seleção de Serviços',
      );
      return false;
    }

    _isLoading.value = true;
    bool isSuccess = false;

    await MegaRequestUtils.load(
      action: () async {
        // Aqui você pode implementar a lógica para salvar os serviços selecionados
        // Por exemplo, criar WorkshopServices para cada serviço selecionado
        
        // Por enquanto, apenas simular sucesso
        await Future.delayed(const Duration(seconds: 1));
        
        final workshopCache = WorkshopModel.fromCache();
        workshopCache.workshopServicesValid = true;
        workshopCache.save();
        
        isSuccess = true;
        
        MegaSnackbar.showSuccessSnackBar(
          '${_selectedServiceIds.length} serviço(s) selecionado(s) com sucesso!',
          title: 'Seleção de Serviços',
        );
      },
      onFinally: () => _isLoading.value = false,
    );

    return isSuccess;
  }

  int get selectedCount => _selectedServiceIds.length;
  int get totalCount => _defaultServices.length;
}
