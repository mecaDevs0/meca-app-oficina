import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';
import 'widgets/contact_item.dart';
import 'widgets/menu_button.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  void _makeAction(UserMenuOption menu) {
    switch (menu) {
      case UserMenuOption.edit:
        Get.toNamed(Routes.editProfile);
        break;
      case UserMenuOption.changePassword:
        Get.toNamed(Routes.changePassword);
        break;
      case UserMenuOption.service:
        Get.toNamed(Routes.service);
        break;
      case UserMenuOption.dataBank:
        Get.toNamed(Routes.bankAccount);
        break;
      case UserMenuOption.helpCenter:
        Get.toNamed(Routes.helpCenter);
        break;
      case UserMenuOption.logout:
        _validateLogout();
        break;
    }
  }

  Future<void> _validateLogout() async {
    final result = await controller.onLogout();
    if (result) {
      Get.offAllNamed(Routes.login);
      await Future.delayed(const Duration(milliseconds: 500));
      await WorkshopModel.remove();
    }
  }

  String _formatCnpj(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return 'CNPJ não informado';
    }
    
    // Verificar se o CNPJ tem pelo menos 14 dígitos
    final cleanCnpj = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCnpj.length < 14) {
      return 'CNPJ inválido';
    }
    
    try {
      return UtilBrasilFields.obterCnpj(cnpj);
    } catch (e) {
      return 'CNPJ inválido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MegaContainerLoading(
        isLoading: controller.isLoading,
        child: Scaffold(
          backgroundColor: AppColors.surfaceColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header com gradiente
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Avatar com borda
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.backgroundColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: MegaCachedNetworkImage(
                              imageUrl: controller.workshop.photo,
                              height: 100,
                              width: 100,
                              radius: 50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Nome da empresa
                          Text(
                            controller.workshop.companyName ?? '',
                            style: const TextStyle(
                              color: AppColors.backgroundColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // CNPJ
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatCnpj(controller.workshop.cnpj),
                              style: const TextStyle(
                                color: AppColors.backgroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Informações de contato
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.backgroundColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ContactItem(
                                  icon: AppImages.icEmail,
                                  label: controller.workshop.email ?? '',
                                  iconColor: AppColors.backgroundColor,
                                  textColor: AppColors.backgroundColor,
                                ),
                                const SizedBox(height: 12),
                                ContactItem(
                                  icon: AppImages.icWhatsapp,
                                  label: controller.workshop.phone.formattedPhone,
                                  iconColor: AppColors.backgroundColor,
                                  textColor: AppColors.backgroundColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Menu de opções
                Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: UserMenuOption.values.map(
                      (menu) => Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.grayBorderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: MenuButton(
                          icon: menu.icon,
                          title: menu.title,
                          subtitle: menu.subtitle,
                          onTap: () => _makeAction(menu),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                // Botão de deletar conta
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      AppBottomSheet.showDeleteBottomSheet(
                        context,
                        icon: AppImages.icDelete,
                        description: 'Excluir sua conta fará com que todos os'
                            ' dados sejam perdidos permanentemente.',
                        onButtonPress: () async {
                          final result = await controller.onRemoveAccount();
                          if (result) {
                            Get.offAllNamed(Routes.login);
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.errorColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Deletar conta',
                            style: TextStyle(
                              color: AppColors.errorColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
