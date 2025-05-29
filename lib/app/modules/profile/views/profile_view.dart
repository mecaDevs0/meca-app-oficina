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

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MegaContainerLoading(
        isLoading: controller.isLoading,
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 78,
                      width: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: MegaCachedNetworkImage(
                        imageUrl: controller.workshop.photo,
                        height: 78,
                        width: 78,
                        radius: 40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.workshop.companyName ?? '',
                      style: const TextStyle(
                        color: AppColors.abbey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UtilBrasilFields.obterCnpj(
                        controller.workshop.cnpj ?? '',
                      ),
                      style: const TextStyle(
                        color: AppColors.silver,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ContactItem(
                            icon: AppImages.icEmail,
                            label: controller.workshop.email ?? '',
                          ),
                          ContactItem(
                            icon: AppImages.icWhatsapp,
                            label: controller.workshop.phone.formattedPhone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...UserMenuOption.values.map(
                      (menu) => MenuButton(
                        icon: menu.icon,
                        title: menu.title,
                        subtitle: menu.subtitle,
                        onTap: () => _makeAction(menu),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
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
                      child: const Text(
                        'Deletar conta',
                        style: TextStyle(
                          color: AppColors.apricot,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
