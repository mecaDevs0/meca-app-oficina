import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/edit_profile_controller.dart';

class CompanyForm extends StatefulWidget {
  const CompanyForm({super.key});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends MegaState<CompanyForm, EditProfileController> {
  final _formKey = GlobalKey<FormState>();
  final companyNameController = TextEditingController();
  final openingHoursController = TextEditingController();
  final cnpjController = TextEditingController();

  String _formatCnpj(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return '';
    }
    
    // Verificar se o CNPJ tem pelo menos 14 dígitos
    final cleanCnpj = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCnpj.length < 14) {
      return cnpj; // Retornar o valor original se for inválido
    }
    
    try {
      return UtilBrasilFields.obterCnpj(cnpj);
    } catch (e) {
      return cnpj; // Retornar o valor original se der erro
    }
  }

  @override
  void initState() {
    companyNameController.text = controller.workshop.companyName ?? '';
    openingHoursController.text = controller.workshop.openingHours ?? '';
    cnpjController.text = _formatCnpj(controller.workshop.cnpj);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Logo do estabelecimento',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '(opcional)',
                style: TextStyle(
                  color: AppColors.hintTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Obx(
              () => MegaPhotoContainer(
                profilePhoto: controller.workshop.photo,
                photo: controller.fileLogo,
                onPhotoChanged: (file) {
                  controller.fileLogo = File(file.path);
                },
                typeModal: TypeModal.bottomSheet,
                buttonColor: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Requisitos',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Formato: .jpg, .jpeg, .png',
            style: TextStyle(
              color: AppColors.hintTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tamanho máximo do arquivo: 1mb',
            style: TextStyle(
              color: AppColors.hintTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tamanho da imagem: 1000px x 1000px',
            style: TextStyle(
              color: AppColors.hintTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: companyNameController,
            label: 'Nome da empresa',
            hintText: 'Digite o nome da empresa',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: openingHoursController,
            label: 'Horário de funcionamento',
            hintText: 'Selecione o horário que a empresa abre',
            isRequired: true,
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return AppBodyTimerModal(
                    onConfirm: (value) {
                      openingHoursController.text = value;
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: cnpjController,
            label: 'CNPJ',
            hintText: 'Digite o CNPJ da empresa',
            keyboardType: TextInputType.number,
            validator: Validatorless.multiple(
              [
                Validatorless.required('CNPJ é obrigatório'),
                Validatorless.cnpj('CNPJ inválido'),
              ],
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CnpjInputFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => MegaBaseButton(
              'Salvar alterações',
              buttonColor: AppColors.primaryColor,
              isLoading: controller.isLoading,
              onButtonPress: () {
                if (_formKey.currentState?.validate() == false) {
                  return;
                }
                final workshop = controller.workshop.copyWith(
                  companyName: companyNameController.text,
                  openingHours: openingHoursController.text,
                  cnpj: _formatCnpj(cnpjController.text),
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
