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
          // Seção de Logo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Logo do estabelecimento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                          borderRadius: BorderRadius.circular(80),
                          child: Image.file(
                            controller.logoFile!,
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(80),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Adicionar logo',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Requisitos',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Seção de Informações da Empresa
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Informações da empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: companyNameController,
                  label: 'Nome da empresa',
                  hintText: 'Digite o nome da empresa',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Seção do Cartão MEI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cartão MEI',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.file_present,
                                  color: AppColors.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.cardMeiFile?.path.split('/').last ?? '',
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 40,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Faça upload do cartão MEI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Clique para selecionar o arquivo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.black.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
