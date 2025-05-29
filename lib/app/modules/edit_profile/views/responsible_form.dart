import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/edit_profile_controller.dart';

class ResponsibleForm extends StatefulWidget {
  const ResponsibleForm({super.key});

  @override
  State<ResponsibleForm> createState() => _ResponsibleFormState();
}

class _ResponsibleFormState
    extends MegaState<ResponsibleForm, EditProfileController> {
  final _formKey = GlobalKey<FormState>();
  final responsibleNameController = TextEditingController();
  final responsibleEmailController = TextEditingController();
  final responsiblePhoneController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    final workshop = controller.workshop;
    responsibleNameController.text = workshop.fullName ?? '';
    responsibleEmailController.text = workshop.email ?? '';
    responsiblePhoneController.text = workshop.phone.formattedPhone;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: responsibleNameController,
            label: 'Nome do responsável',
            hintText: 'Digite o nome do responsável',
            isRequired: true,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
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
          Obx(
            () => MegaBaseButton(
              'Salvar alterações',
              isLoading: controller.isLoading,
              onButtonPress: () {
                if (_formKey.currentState?.validate() == false) {
                  return;
                }
                final workshop = controller.workshop.copyWith(
                  fullName: responsibleNameController.text,
                  email: responsibleEmailController.text,
                  phone: UtilBrasilFields.removeCaracteres(
                    responsiblePhoneController.text,
                  ),
                );
                controller.onEditWorkshop(workshop);
              },
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              borderRadius: 4,
            ),
          ),
        ],
      ),
    );
  }
}
