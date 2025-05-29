import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/register_controller.dart';

class ResponsibleForm extends GetView<RegisterController> {
  const ResponsibleForm({
    super.key,
    required this.formKey,
    required this.responsibleNameController,
    required this.responsibleEmailController,
    required this.responsiblePhoneController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController responsibleNameController;
  final TextEditingController responsibleEmailController;
  final TextEditingController responsiblePhoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            controller: responsibleNameController,
            label: 'Nome do responsável',
            hintText: 'Digite o nome do responsável',
            isRequired: true,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: Validatorless.multiple([
              Validatorless.required('O nome é obrigatório'),
              (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }

                final regex = RegExp(
                  r'^(?:[A-Za-zÀ-ÖØ-öø-ÿ]{2,}\s){1,3}[A-Za-zÀ-ÖØ-öø-ÿ]{2,}$',
                );

                if (!regex.hasMatch(value.trim())) {
                  return 'Nome inválido. Informe de 2 a 4 palavras com ao menos 2 letras cada.';
                }

                return null;
              },
            ]),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: responsibleEmailController,
            label: 'E-mail do responsável',
            hintText: 'Digite o e-mail do responsável',
            validator: Validatorless.multiple([
              Validatorless.required('O e-mail é obrigatório'),
              Validatorless.email('E-mail inválido'),
            ]),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: responsiblePhoneController,
            label: 'Telefone do responsável',
            hintText: 'Digite o telefone do responsável',
            keyboardType: TextInputType.phone,
            validator: Validatorless.multiple([
              Validatorless.required('O telefone é obrigatório'),
              Validatorless.phone('Telefone inválido'),
            ]),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TelefoneInputFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: passwordController,
            label: 'Senha',
            hintText: 'Digite a senha',
            keyboardType: TextInputType.visiblePassword,
            validator: Validatorless.multiple(
              [
                Validatorless.required('Senha é obrigatório'),
                Validatorless.min(
                  6,
                  'A senha deve ter no mínimo 6 caracteres',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: confirmPasswordController,
            label: 'Confirme a senha',
            hintText: 'Digite a senha novamente',
            keyboardType: TextInputType.visiblePassword,
            validator: Validatorless.multiple([
              Validatorless.required('Confirmar Senha obrigatória'),
              Validatorless.min(
                6,
                'Confirmar Senha precisa ter pelo menos 6 caracteres',
              ),
              Validators.compare(
                passwordController,
                'As senhas precisam ser iguais',
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Obx(
            () => MegaPolicyTerm(
              onChanged: (value) => controller.isPolicyTermChecked = value,
              isSelected: controller.isPolicyTermChecked,
              policyTermsFileUrl:
                  'https://api.megaleios.com/content/TermosMeca.html',
            ),
          ),
        ],
      ),
    );
  }
}
