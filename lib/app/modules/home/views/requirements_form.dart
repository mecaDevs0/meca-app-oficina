import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/home_controller.dart';

class RequirementsForm extends StatefulWidget {
  const RequirementsForm({super.key});

  @override
  State<RequirementsForm> createState() => _RequirementsFormState();
}

class _RequirementsFormState
    extends MegaState<RequirementsForm, HomeController> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    controller.cardMeiFile = null;
    controller.userDocumentFile = null;
    super.dispose();
  }

  bool isContains(int code) {
    return controller.listIssues.contains(code);
  }

  bool get isMeiCard {
    final registerDoc = RequirementsStripe.businessRegistrationDocument.code;
    final verifyDoc = RequirementsStripe.businessVerificationDocument.code;
    return controller.listIssues.contains(registerDoc) ||
        controller.listIssues.contains(verifyDoc);
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() == false) {
      return;
    }

    if (isMeiCard && controller.cardMeiFile == null) {
      MegaSnackbar.showErroSnackBar('Documento da empresa é obrigatório');
      return;
    }

    if (isContains(RequirementsStripe.photoDocument.code) &&
        controller.userDocumentFile == null) {
      MegaSnackbar.showErroSnackBar('Documento com foto é obrigatório');
      return;
    }

    final workshop = WorkshopModel(
      email: _emailController.text.trim().emptyToNull,
      phone: _phoneController.text.trim().emptyToNull,
      birthDate: _birthDateController.text.trim().emptyToNull,
      cpf: _cpfController.text.trim().emptyToNull,
      cnpj: _cnpjController.text.trim().emptyToNull,
    );

    final isSuccess = await controller.onCompleteRequirements(workshop);
    if (isSuccess) {
      Get.back(result: true);
      MegaSnackbar.showSuccessSnackBar('Requisitos enviados com sucesso');
    } else {
      MegaSnackbar.showErroSnackBar('Erro ao enviar requisitos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => Form(
            key: _formKey,
            child: Column(
              children: [
                if (isContains(RequirementsStripe.email.code))
                  AppTextField(
                    label: 'E-mail',
                    hintText: 'Digite seu e-mail',
                    controller: _emailController,
                    validator: Validatorless.multiple([
                      Validatorless.required('E-mail obrigatório'),
                      Validatorless.email('E-mail inválido'),
                    ]),
                    isSpacer: true,
                  ),
                if (isContains(RequirementsStripe.phone.code) ||
                    isContains(RequirementsStripe.supportPhone.code))
                  AppTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    hintText: 'Digite seu telefone',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TelefoneInputFormatter(),
                    ],
                    validator: Validatorless.multiple([
                      Validatorless.required('Telefone obrigatório'),
                      Validatorless.phone('Telefone inválido'),
                    ]),
                    isSpacer: true,
                  ),
                if (isContains(RequirementsStripe.birthDate.code))
                  AppTextField(
                    controller: _birthDateController,
                    label: 'Data de Nascimento',
                    hintText: 'Digite sua data de nascimento',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      DataInputFormatter(),
                    ],
                    validator: Validatorless.multiple([
                      Validatorless.required(
                        'Data de nascimento obrigatória',
                      ),
                    ]),
                    isSpacer: true,
                  ),
                if (isContains(RequirementsStripe.cpf.code) || isContains(6))
                  AppTextField(
                    controller: _cpfController,
                    label: 'CPF',
                    hintText: 'Digite seu CPF',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CpfInputFormatter(),
                    ],
                    validator: Validatorless.multiple([
                      Validatorless.required('CPF obrigatório'),
                      Validatorless.cpf('CPF inválido'),
                    ]),
                    isSpacer: true,
                  ),
                if (isContains(RequirementsStripe.cnpj.code))
                  AppTextField(
                    controller: _cnpjController,
                    label: 'CNPJ',
                    hintText: 'Digite seu CNPJ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CnpjInputFormatter(),
                    ],
                    validator: Validatorless.multiple([
                      Validatorless.required('CNPJ obrigatório'),
                      Validatorless.cnpj('CNPJ inválido'),
                    ]),
                    isSpacer: true,
                  ),
                if (isMeiCard)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documento da empresa',
                        style: TextStyle(
                          color: AppColors.abbey,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            MegaFilePicker.showModalChooser(
                              context,
                              canSelectFile: true,
                              onFileSelected: (file) {
                                controller.cardMeiFile = file;
                              },
                              cameraColor: AppColors.primaryColor,
                              galleryColor: AppColors.primaryColor,
                              fileColor: AppColors.primaryColor,
                            );
                          },
                          child: controller.cardMeiFile != null
                              ? Text(
                                  controller.cardMeiFile?.path
                                          .split('/')
                                          .last ??
                                      '',
                                )
                              : Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: CustomPaint(
                                    painter: AppDashedBorderPainter(
                                      color: AppColors.abbey,
                                      borderRadius: 4,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      child: const Text(
                                        'Faça upload do documento da empresa',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (isContains(RequirementsStripe.photoDocument.code))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documento com foto',
                        style: TextStyle(
                          color: AppColors.abbey,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            MegaFilePicker.showModalChooser(
                              context,
                              canSelectFile: true,
                              onFileSelected: (file) {
                                controller.userDocumentFile = file;
                              },
                              cameraColor: AppColors.primaryColor,
                              galleryColor: AppColors.primaryColor,
                              fileColor: AppColors.primaryColor,
                            );
                          },
                          child: controller.userDocumentFile != null
                              ? Text(
                                  controller.userDocumentFile?.path
                                          .split('/')
                                          .last ??
                                      '',
                                )
                              : Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: CustomPaint(
                                    painter: AppDashedBorderPainter(
                                      color: AppColors.abbey,
                                      borderRadius: 4,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      child: const Text(
                                        'Faça upload do documento com foto',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                if (isContains(RequirementsStripe.fullAddress.code))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: MegaBaseButton(
                      'Preencher endereço',
                      onButtonPress: () {},
                      textColor: Colors.white,
                      buttonColor: AppColors.chetwodeBlue,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: MegaBaseButton(
                    'Enviar',
                    isLoading: controller.isLoading,
                    onButtonPress: _onSubmit,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
