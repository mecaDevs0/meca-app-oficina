import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';

class SuccessContainer extends StatelessWidget {
  const SuccessContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            SizedBox(height: statusBarHeight + 20),
            SvgPicture.asset(AppImages.icEmailSuccess),
            const SizedBox(height: 16),
            const Text(
              'Verifique sua caixa de entrada para o link de recuperação enviado pela equipe Meca.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.abbey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            MegaBaseButton(
              'Voltar ao login',
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              borderRadius: 0,
              onButtonPress: Get.back,
            ),
          ],
        ),
      ),
    );
  }
}
