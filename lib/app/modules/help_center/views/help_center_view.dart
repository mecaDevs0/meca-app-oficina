import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../../core/core.dart';
import '../controllers/help_center_controller.dart';

class HelpCenterView extends StatefulWidget {
  const HelpCenterView({super.key});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState
    extends MegaState<HelpCenterView, HelpCenterController> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Central de ajuda',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Título',
                hintText: 'Digite o título',
                controller: titleController,
                isRequired: true,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: descriptionController,
                label: 'Descrição',
                hintText: 'Digite a descrição',
                isMultiLine: true,
                isRequired: true,
              ),
              const SizedBox(height: 32),
              MegaBaseButton(
                'Enviar dúvida',
                onButtonPress: () {
                  if (_formKey.currentState?.validate() == false) {
                    return;
                  }
                  controller.sendQuestion(
                    title: titleController.text,
                    description: descriptionController.text,
                  );
                },
                borderRadius: 4,
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
