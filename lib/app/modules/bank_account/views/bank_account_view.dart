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
    print('🔍 [VIEW_DEBUG] Workshop ID: ${workshop.id}');
    print('🔍 [VIEW_DEBUG] Workshop data: ${workshop.toJson()}');
    
    await controller.initialize(
      userId: workshop.id,
      pathBank: BaseUrls.updateDataBank,
      pathBankGet: BaseUrls.dataBank,
      isSandBox: false, // Sempre false para não preencher dados de teste
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Dados bancários',
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
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
                actionButton: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MegaBaseButton(
                    'Salvar alterações',
                    borderRadius: 16,
                    buttonColor: Colors.transparent,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  isLoading: controller.isLoading,
                  onButtonPress: () async {
                    print('🔍 [VIEW_DEBUG] Button pressed - Workshop ID: ${workshop.id}');
                    print('🔍 [VIEW_DEBUG] Bank account ID: ${controller.bankAccount.id}');
                    
                    // Usar o ID do bankAccount se o workshop.id estiver vazio
                    final userId = workshop.id?.isNotEmpty == true 
                        ? workshop.id! 
                        : controller.bankAccount.id;
                    
                    print('🔍 [VIEW_DEBUG] Final User ID: $userId');
                    
                    if (userId != null && userId.isNotEmpty) {
                      await controller.updateRegister(
                        userId: userId,
                        pathBank: null, // Deixar null para usar a lógica do provider
                      );
                      
                      // Atualizar os dados do workshop do servidor
                      try {
                        final profileProvider = Get.find<ProfileProvider>();
                        final updatedWorkshop = await profileProvider.onGetProfileInfo();
                        await updatedWorkshop.save();
                        print('✅ Dados do workshop atualizados do servidor após salvar dados bancários');
                      } catch (e) {
                        print('⚠️ Erro ao atualizar dados do workshop do servidor: $e');
                        // Fallback: atualizar apenas o cache local
                        final workshopCache = WorkshopModel.fromCache();
                        workshopCache.dataBankValid = true;
                        await workshopCache.save();
                      }
                    } else {
                      print('🔍 [VIEW_DEBUG] User ID is null or empty!');
                      MegaSnackbar.showErroSnackBar('Erro: ID da oficina não encontrado');
                    }
                  },
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
