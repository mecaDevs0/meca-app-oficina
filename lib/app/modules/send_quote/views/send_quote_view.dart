import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/models/budget_service_model.dart';
import '../controllers/send_quote_controller.dart';
import 'widgets/app_table_price_budget.dart';

class SendQuoteView extends StatefulWidget {
  const SendQuoteView({super.key});

  @override
  State<SendQuoteView> createState() => _SendQuoteViewState();
}

class _SendQuoteViewState
    extends MegaState<SendQuoteView, SendQuoteController> {
  final formKey = GlobalKey<FormState>();
  final diagnosticValueController = TextEditingController(text: r'R$ 0,00');
  final completionDateController = TextEditingController();
  final totalValueController = TextEditingController();

  void _showModal(BuildContext context, {BudgetServiceModel? serviceToEdit}) {
    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final nameController =
            TextEditingController(text: serviceToEdit?.title ?? '');
        final descriptionController =
            TextEditingController(text: serviceToEdit?.description ?? '');
        final priceController = TextEditingController(
          text: serviceToEdit?.value != null
              ? serviceToEdit?.value!.moneyFormat()
              : '',
        );

        return Center(
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Nome do serviço',
                      hintText: 'Digite o nome do serviço',
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Descrição do serviço',
                      hintText: 'Descreva o serviço que será prestado',
                      controller: descriptionController,
                      keyboardType: TextInputType.text,
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Valor do serviço',
                      hintText: 'Digite o valor do serviço',
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CentavosInputFormatter(
                          moeda: true,
                        ),
                      ],
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    MegaBaseButton(
                      'Incluir no orçamento',
                      textStyle: AppTextStyle.buttonTextStyle,
                      borderRadius: 4,
                      onButtonPress: () async {
                        if (formKey.currentState?.validate() == false) {
                          return;
                        }

                        final newService = BudgetServiceModel(
                          title: nameController.text,
                          description: descriptionController.text,
                          value: UtilBrasilFields.converterMoedaParaDouble(
                            priceController.text,
                          ),
                        );

                        if (serviceToEdit != null) {
                          controller.editBudgetService(
                            serviceToEdit,
                            newService,
                          );
                        } else {
                          controller.incrementBudgetService(newService);
                        }

                        if (diagnosticValueController.text.isNullOrEmpty) {
                          controller.calculateTotals(0.0);
                        } else {
                          controller.calculateTotals(
                            UtilBrasilFields.converterMoedaParaDouble(
                              diagnosticValueController.text,
                            ),
                          );
                        }
                        FocusScope.of(context).unfocus();
                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Enviar orçamento'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Obx(
          () {
            if (controller.isLoadingServiceDetail) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              );
            }
            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nome do cliente',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.scheduleService.profile.fullName ?? '',
                    style: const TextStyle(
                      color: AppColors.abbey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Placa do carro',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.scheduleService.vehicle.plate ?? '',
                    style: const TextStyle(
                      color: AppColors.abbey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Serviços selecionados pelo cliente',
                    style: TextStyle(
                      color: AppColors.fontDarkGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.scheduleService.workshopServices
                          .map(
                            (service) => AppStatusChip(
                              label: service.service?.name,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      AppTablePriceBudget(
                        onEditService: (service) =>
                            _showModal(context, serviceToEdit: service),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Valor total do serviços orçados:',
                          style: TextStyle(
                            color: AppColors.abbey,
                          ),
                        ),
                        Text(
                          controller.totalServicesValue.moneyFormat(),
                          style: const TextStyle(
                            color: AppColors.abbey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppImages.icPlus,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _showModal(context);
                        },
                        child: const Text(
                          'Adicionar novo item ao orçamento',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    onChanged: controller.onDiagnosticValueChanged,
                    controller: diagnosticValueController,
                    label: 'Valor do diagnóstico',
                    hintText: 'Digite o valor do diagnóstico',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CentavosInputFormatter(moeda: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          'Fotos',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          '(opcional)',
                          style: TextStyle(
                            color: AppColors.hintTextColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      MegaFilePicker.showModalChooser(
                        context,
                        onFilesSelected: controller.addImages,
                        cameraColor: AppColors.primaryColor,
                        galleryColor: AppColors.primaryColor,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: CustomPaint(
                        painter: AppDashedBorderPainter(
                          color: AppColors.abbey,
                          borderRadius: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(AppImages.icCamera),
                              const SizedBox(width: 8),
                              const Text(
                                'Incluir fotos',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (controller.selectedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Imagens ${controller.selectedImages.length}/${controller.maxImages}',
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 16,
                            ),
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.selectedImages.length,
                            itemBuilder: (context, index) {
                              final file = controller.selectedImages[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        image: DecorationImage(
                                          image: FileImage(file),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        file.path.split('/').last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => controller.removeImage(file),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.apricot,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: completionDateController,
                    label: 'Data estimada para conclusão',
                    hintText: 'Selecione a data',
                    keyboardType: TextInputType.datetime,
                    onTap: () {
                      showMegaDatePicker(
                        context,
                        minimumDate: DateTime.now(),
                        maximumDate:
                            DateTime.now().add(const Duration(days: 365)),
                        onSelectDate: (date) {
                          completionDateController.text = date.toddMMyyyy();
                        },
                        onCancelClick: () {
                          completionDateController.clear();
                        },
                        dotDates: controller.dots,
                      );
                    },
                    isRequired: true,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Valor total:',
                          style: TextStyle(
                            color: AppColors.abbey,
                          ),
                        ),
                        Text(
                          controller.totalWithDiagnostic.moneyFormat(),
                          style: const TextStyle(
                            color: AppColors.abbey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  MegaBaseButton(
                    'Enviar orçamento',
                    isLoading: controller.isLoadingSendQuote,
                    onButtonPress: () async {
                      if (formKey.currentState?.validate() == false) {
                        return;
                      }
                      if (controller.budgetServices.isEmpty) {
                        MegaSnackbar.showErroSnackBar(
                          'Adicione ao menos um item ao orçamento',
                        );
                        return;
                      }

                      final diagnosticDouble =
                          UtilBrasilFields.converterMoedaParaDouble(
                        diagnosticValueController.text,
                      );
                      final estimatedTime =
                          completionDateController.text.toTimeStamp ?? 0;

                      final isSuccess = await controller.sendQuote(
                        diagnosticValue: diagnosticDouble,
                        estimatedTimeForCompletion: estimatedTime,
                      );

                      if (isSuccess && context.mounted) {
                        return AppBottomSheet.showCompleteModal(
                          context,
                          icon: AppImages.icBudgetSent,
                          title: 'Orçamento enviado',
                          message:
                              'Você enviou o orçamento agora é só aguardar a'
                              ' visualização e aprovação do cliente.',
                          buttonText: 'Detalhes do serviço',
                          onButtonPress: () {
                            Get.back();
                            Get.back();
                          },
                        );
                      }
                    },
                    borderRadius: 4,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
