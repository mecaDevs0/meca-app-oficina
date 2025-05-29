import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../../../core/core.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Alterar Senha',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              AppTextField(
                controller: controller.currentPassword,
                label: 'Senha atual',
                hintText: 'Digite sua senha atual',
                isRequired: true,
                keyboardType: TextInputType.visiblePassword,
                suffixIcon: const Icon(FontAwesomeIcons.eye),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller.newPassword,
                label: 'Nova Senha',
                isRequired: true,
                hintText: 'Digite sua senha atual',
                keyboardType: TextInputType.visiblePassword,
                suffixIcon: const Icon(FontAwesomeIcons.eye),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller.confirmPassword,
                label: 'Confirmar nova senha',
                isRequired: true,
                keyboardType: TextInputType.visiblePassword,
                suffixIcon: const Icon(FontAwesomeIcons.eye),
                validator: Validatorless.multiple([
                  Validatorless.required('Confirmar Senha obrigatória'),
                  Validatorless.min(
                    6,
                    'Confirmar Senha precisa ter pelo menos 6 caracteres',
                  ),
                  Validators.compare(
                    controller.newPassword,
                    'Senha diferente de Nova Senha',
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              Obx(
                () => MegaBaseButton(
                  'Salvar alterações',
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  onButtonPress: () async {
                    await controller.onSubmit();
                  },
                  isLoading: controller.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
