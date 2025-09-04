import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../data/providers/bank_account_provider.dart';

class LocalBankAccountController extends GetxController {
  LocalBankAccountController({
    required BankAccountProvider bankProvider,
  }) : _bankProvider = bankProvider;

  final BankAccountProvider _bankProvider;

  final _isLoading = RxBool(false);
  final _bankData = Rx<Map<String, dynamic>>({});

  bool get isLoading => _isLoading.value;
  Map<String, dynamic> get bankData => _bankData.value;

  @override
  void onInit() {
    super.onInit();
    loadBankData();
  }

  Future<void> loadBankData() async {
    try {
      _isLoading.value = true;
      final data = await _bankProvider.getBankData();
      _bankData.value = data;
    } catch (e) {
      print('Erro ao carregar dados bancários: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateBankData(Map<String, dynamic> data) async {
    try {
      _isLoading.value = true;
      await _bankProvider.updateBankData(bankData: data);
      _bankData.value = data;
    } catch (e) {
      print('Erro ao atualizar dados bancários: $e');
    } finally {
      _isLoading.value = false;
    }
  }
}
