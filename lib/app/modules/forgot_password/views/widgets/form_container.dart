import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../../../../core/core.dart';

class FormContainer extends GetView<ForgotPasswordController> {
  const FormContainer({
    super.key,
    required this.onButtonPress,
  });

  final void Function() onButtonPress;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Form(
      key: controller.formKey,
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 22 + statusBarHeight, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.height * 0.092),
            const AppBackButton(),
            const SizedBox(height: 32),
            const Text(
              'Não lembra da senha?',
              style: TextStyle(
                color: AppColors.abbey,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Digite seu e-mail no campo abaixo',
              style: TextStyle(
                color: AppColors.abbey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: controller.emailController,
              label: 'E-mail',
              hintText: 'Digite seu e-mail',
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            Obx(
              () => MegaBaseButton(
                'Recuperar senha',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                borderRadius: 0,
                onButtonPress: onButtonPress,
                isLoading: controller.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
