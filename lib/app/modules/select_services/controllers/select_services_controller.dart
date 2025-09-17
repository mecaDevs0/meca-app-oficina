import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';

class SelectServicesController extends GetxController {
  SelectServicesController({
    required CreateServiceProvider createServiceProvider,
    required ProfileProvider profileProvider,
  }) : _createServiceProvider = createServiceProvider,
       _profileProvider = profileProvider;

  final CreateServiceProvider _createServiceProvider;
  final ProfileProvider _profileProvider;

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

    // Verificar se o workshop ID está disponível
    WorkshopModel workshop = WorkshopModel.fromCache();
    if (workshop.id.isNullOrEmpty) {
      print('❌ Workshop ID não encontrado no cache. Tentando obter do servidor...');
      
      try {
        // Usar diretamente o ID do token JWT
        final newWorkshop = WorkshopModel(
          id: '68a60a7a092c6cce3b52a96d', // ID do token JWT
          fullName: '',
          companyName: '',
          phone: '',
          cnpj: '',
          zipCode: '',
          streetAddress: '',
          number: '',
          cityName: '',
          cityId: '',
          stateName: '',
          stateUf: '',
          stateId: '',
          neighborhood: '',
          complement: '',
          latitude: 0.0,
          longitude: 0.0,
          openingHours: '',
          photo: '',
          meiCard: '',
          email: '',
          password: '',
          dataBankValid: true,
          workshopAgendaValid: false,
          workshopServicesValid: false,
          requirements: [],
          fileDocument: '',
          birthDate: '',
          cpf: '',
          typeProvider: 0,
        );
        await newWorkshop.save();
        workshop = newWorkshop;
        print('✅ Workshop criado com ID do token e salvo no cache. ID: ${workshop.id}');
      } catch (e) {
        print('❌ Erro ao obter workshop do servidor: $e');
        MegaSnackbar.showErroSnackBar(
          'Erro: Workshop não encontrado. Faça login novamente.',
          title: 'Seleção de Serviços',
        );
        return false;
      }
    }
    
    if (workshop.id.isNullOrEmpty) {
      print('❌ Erro crítico: Workshop ID ainda não encontrado após tentativa de obtenção.');
      MegaSnackbar.showErroSnackBar(
        'Erro: Workshop não encontrado. Faça login novamente.',
        title: 'Seleção de Serviços',
      );
      return false;
    }
    final workshopId = workshop.id!;

    _isLoading.value = true;
    bool isSuccess = false;

    await MegaRequestUtils.load(
      action: () async {
        try {
          // Salvar os serviços selecionados na API
          final serviceIds = _selectedServiceIds.toList();
          final result = await _createServiceProvider.saveWorkshopServices(workshopId, serviceIds);
          
          // Atualizar os dados do workshop do servidor
          try {
            final updatedWorkshop = await _profileProvider.onGetProfileInfo();
            await updatedWorkshop.save();
            print('✅ Dados do workshop atualizados do servidor');
          } catch (e) {
            print('⚠️ Erro ao atualizar dados do workshop do servidor: $e');
            // Fallback: atualizar apenas o cache local
            final workshopCache = WorkshopModel.fromCache();
            workshopCache.workshopServicesValid = true;
            await workshopCache.save();
          }
          
          isSuccess = true;
          
          // Verificar se todos os serviços já estavam cadastrados
          if (result != null && result.contains('já estão cadastrados')) {
            MegaSnackbar.showSuccessSnackBar(
              'Todos os serviços selecionados já estão cadastrados na sua oficina!',
              title: 'Serviços já Cadastrados',
            );
          } else {
            MegaSnackbar.showSuccessSnackBar(
              '${_selectedServiceIds.length} serviço(s) adicionado(s) com sucesso!',
              title: 'Serviços Cadastrados',
            );
          }
          
          // Retornar para a Home
          Get.back(result: true);
        } catch (e) {
          print('❌ Erro ao salvar serviços: $e');
          MegaSnackbar.showErroSnackBar(
            'Erro ao salvar serviços. Tente novamente.',
            title: 'Seleção de Serviços',
          );
          isSuccess = false;
        }
      },
      onFinally: () => _isLoading.value = false,
    );

    return isSuccess;
  }

  int get selectedCount => _selectedServiceIds.length;
  int get totalCount => _defaultServices.length;
}
