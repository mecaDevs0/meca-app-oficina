import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../core.dart';

class AppBottomSheet {
  AppBottomSheet._();

  static void showModalInfoSend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: Get.back,
                ),
              ),
              const SizedBox(height: 12),
              SvgPicture.asset(
                AppImages.icInfoSend,
                height: 142,
              ),
              const SizedBox(height: 32),
              const Text(
                'Informações enviadas!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.abbey,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agradecemos pelas informações, nossa equipe efetuará uma'
                ' análise e em breve você receberá um e-mail com a liberação'
                ' de acesso à plataforma',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.abbey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showLocationBottomSheet(
    BuildContext context, {
    required void Function() onRequestPermission,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ),
                SvgPicture.asset(
                  AppImages.icPermissionLocation,
                  height: 140,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bem-vindo ao Meca!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vamos ativar sua localização melhorar a'
                  ' experiência no aplicativo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                MegaBaseButton(
                  'Ativar Localização',
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  onButtonPress: () {
                    Get.back();
                    onRequestPermission();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showCompleteModal(
    BuildContext context, {
    required String icon,
    required String title,
    required String message,
    required String buttonText,
    required void Function() onButtonPress,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: Get.back,
                ),
              ),
              const SizedBox(height: 12),
              SvgPicture.asset(
                icon,
                height: 142,
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.abbey,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.abbey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              MegaBaseButton(
                buttonText,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                borderRadius: 4,
                onButtonPress: onButtonPress,
              ),
            ],
          ),
        );
      },
    );
  }

  static void showDeleteBottomSheet(
    BuildContext context, {
    required void Function() onButtonPress,
    String? icon,
    String? description,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(icon ?? AppImages.icTrash),
              const SizedBox(height: 24),
              const Text(
                'Tem certeza?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.abbey,
                ),
              ),
              Text(
                description ??
                    'Excluir o serviço fará com que todos os dados sejam perdidos permanentemente.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.abbey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              MegaBaseButton(
                'Tenho certeza',
                buttonColor: AppColors.apricot,
                borderRadius: 4,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onButtonPress: () {
                  Navigator.of(context).pop();
                  onButtonPress();
                },
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 46,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: AppColors.grayLineColor,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 2,
                        offset: Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Cancelar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.abbey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
