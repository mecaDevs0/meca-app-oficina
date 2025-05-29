import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons/shared/models/abbreviation.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

class BankAccountView extends StatefulWidget {
  const BankAccountView({super.key});

  @override
  State<BankAccountView> createState() => _BankAccountViewState();
}

class _BankAccountViewState
    extends MegaState<BankAccountView, BankAccountController> {
  final workshop = WorkshopModel.fromCache();
  @override
  void initState() {
    _checkTypeProfile();
    super.initState();
  }

  Future<void> _checkTypeProfile() async {
    await controller.initialize(
      userId: workshop.id,
      pathBank: BaseUrls.updateDataBank,
      pathBankGet: BaseUrls.dataBank,
      isSandBox: Env.abbreviation != Abbreviation.production,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Dados bancários',
      ),
      body: Center(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (Env.abbreviation != Abbreviation.production)
                GestureDetector(
                  onTap: () {
                    controller.setSandboxMode();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.apricot.withValues(alpha: 0.2),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Text(
                            'Teste Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.apricot,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Você está no ambiente de teste. Toque aqui para preencher os dados de teste.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.apricot,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              FormBankAccountView(
                isWithTitle: true,
                actionButton: MegaBaseButton(
                  'Salvar alterações',
                  borderRadius: 4,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  isLoading: controller.isLoading,
                  onButtonPress: () async {
                    if (workshop.id != null) {
                      await controller.updateRegister(
                        userId: workshop.id!,
                        pathBank: BaseUrls.updateDataBank,
                      );
                      final workshopCache = WorkshopModel.fromCache();
                      workshopCache.dataBankValid = true;
                      workshopCache.save();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
