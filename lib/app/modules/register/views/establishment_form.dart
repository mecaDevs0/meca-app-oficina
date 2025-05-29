import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/register_controller.dart';

class EstablishmentForm extends GetView<RegisterController> {
  const EstablishmentForm({
    super.key,
    required this.formKey,
    required this.companyNameController,
    required this.openingHoursController,
    required this.cnpjController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyNameController;
  final TextEditingController openingHoursController;
  final TextEditingController cnpjController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Logo do estabelecimento'),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              MegaFilePicker.showModalChooser(
                context,
                onFileSelected: (file) {
                  controller.logoFile = file;
                },
                cameraColor: AppColors.primaryColor,
                galleryColor: AppColors.primaryColor,
              );
            },
            child: Obx(() {
              if (controller.logoFile != null) {
                return Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(70),
                    child: Image.file(
                      controller.logoFile!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }
              return Center(
                child: SvgPicture.asset(AppImages.dottedImage),
              );
            }),
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
          const AppRequirementItem(
            title: 'Formato',
            subtitle: '.jpg, .jpeg, .png',
          ),
          const AppRequirementItem(
            title: 'Tamanho máximo do arquivo',
            subtitle: 'de 1mb',
          ),
          const AppRequirementItem(
            title: 'Tamanho da imagem',
            subtitle: '1000px x 1000px',
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
            onTap: kDebugMode
                ? () {
                    if (kDebugMode) {
                      cnpjController.text = UtilBrasilFields.gerarCNPJ();
                    }
                  }
                : null,
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
          const Text(
            'Cartão MEI',
            style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w400,
              height: 0.5,
            ),
          ),
          const SizedBox(height: 12),
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
                  ? Text(controller.cardMeiFile?.path.split('/').last ?? '')
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: CustomPaint(
                        painter: AppDashedBorderPainter(
                          color: AppColors.abbey,
                          borderRadius: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: const Text(
                            'Faça upload do cartão MEI',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
