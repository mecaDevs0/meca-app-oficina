import 'package:flutter/material.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/edit_profile_controller.dart';
import 'address_form.dart';
import 'company_form.dart';
import 'responsible_form.dart';
import 'widgets/tab_container.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Editar perfil'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const TabContainer(),
            const SizedBox(height: 24),
            Obx(
              () => Expanded(
                child: SingleChildScrollView(
                  child: switch (controller.stepRegister) {
                    StepRegister.establishment => const CompanyForm(),
                    StepRegister.address => const AddressForm(),
                    StepRegister.responsible => const ResponsibleForm(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
