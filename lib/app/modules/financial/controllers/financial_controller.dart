import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/data.dart';
import '../../../data/providers/financial_provider.dart';

class FinancialController extends GetxController {
  FinancialController({required FinancialProvider financialProvider})
      : _financialProvider = financialProvider;

  final FinancialProvider _financialProvider;

  final _isLoading = RxBool(false);
  final _filterStartDate = Rx<DateTime?>(null);
  final _filterEndDate = Rx<DateTime?>(null);

  bool get isLoading => _isLoading.value;
  DateTime? get filterStartDate => _filterStartDate.value;
  DateTime? get filterEndDate => _filterEndDate.value;

  set startDate(DateTime? value) => _filterStartDate.value = value;
  set endDate(DateTime? value) => _filterEndDate.value = value;

  final PagingController<int, FinancialModel> pagingController =
      PagingController(firstPageKey: 1);
  final _limit = 30;

  @override
  Future<void> onInit() async {
    pagingController.addPageRequestListener(listServices);
    super.onInit();
  }

  Future<void> listServices(int pageKey) async {
    await MegaRequestUtils.load(
      action: () async {
        final response = await _financialProvider.onListFinancial(
          page: pageKey,
          limit: _limit,
          startDate: filterStartDate?.formatFirstHour(),
          endDate: filterEndDate?.formatLastHour(),
        );
        final isLastPage = response.length < _limit;
        if (isLastPage) {
          pagingController.appendLastPage(response);
        } else {
          final nextPageKey = pageKey + 1;
          pagingController.appendPage(response, nextPageKey);
        }
      },
    );
  }
}
