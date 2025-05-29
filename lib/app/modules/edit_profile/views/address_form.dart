import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../controllers/edit_profile_controller.dart';

class AddressForm extends StatefulWidget {
  const AddressForm({super.key});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends MegaState<AddressForm, EditProfileController> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FormAddressView(
          isWithTitle: true,
          isAddressRequired: true,
        ),
        const SizedBox(height: 24),
        Obx(
          () => MegaBaseButton(
            'Salvar alterações',
            isLoading: controller.isLoading,
            onButtonPress: () {
              if (_formKey.currentState?.validate() == false) {
                return;
              }
              controller.populateAddress();
            },
            textStyle: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            borderRadius: 4,
          ),
        ),
      ],
    );
  }
}
