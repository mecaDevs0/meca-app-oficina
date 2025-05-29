import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/app/modules/login/controllers/login_controller.dart';

import '../../../core/core.dart';
import '../../../routes/app_pages.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
          ),
          padding: const EdgeInsets.only(top: 100),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(80),
                topRight: Radius.circular(80),
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    controller.emailController.text = 'renankanu@gmail.com';
                    controller.passwordController.text = '123123';
                  },
                  onDoubleTap: () {
                    MegaModal.callEnvironmentModal(
                      context,
                      devUrl: BaseUrls.baseUrlDev,
                      hmlUrl: BaseUrls.baseUrlHml,
                      prodUrl: BaseUrls.baseUrlProd,
                    );
                  },
                  child: SvgPicture.asset(
                    AppImages.loginLogo,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  key: controller.formKey,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: controller.emailController,
                              label: 'E-mail',
                              hintText: 'Digite seu e-mail',
                              keyboardType: TextInputType.emailAddress,
                              isRequired: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Senha',
                              style: TextStyle(color: AppColors.black),
                            ),
                            const SizedBox(height: 2),
                            MegaTextFieldWidget(
                              controller.passwordController,
                              hintText: 'Digite sua senha',
                              isRequired: true,
                              keyboardType: TextInputType.visiblePassword,
                              suffixIcon: const Icon(FontAwesomeIcons.eye),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Obx(
                          () => MegaBaseButton(
                            'Entrar',
                            buttonColor: AppColors.primaryColor,
                            textColor: Colors.white,
                            onButtonPress: () {
                              controller.save();
                            },
                            borderRadius: 4.0,
                            isLoading: controller.isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Get.toNamed(Routes.forgotPassword);
                  },
                  child: Text(
                    'Esqueci minha senha',
                    style: context.textTheme.displayLarge!.copyWith(
                      color: AppColors.abbey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.grayBorderColor,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Ou',
                        style: TextStyle(
                          color: AppColors.grayBorderColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.grayBorderColor,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                RichText(
                  text: TextSpan(
                    text: 'Não tem uma conta? ',
                    style: context.textTheme.displayLarge!.copyWith(
                      color: AppColors.abbey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'Cadastre-se',
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.toNamed(Routes.register);
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const MegaVersionIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
