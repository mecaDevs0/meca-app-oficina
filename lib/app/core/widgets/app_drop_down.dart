import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../core.dart';

class AppDropDown<T> extends StatelessWidget {
  const AppDropDown({
    super.key,
    required this.controller,
    this.label = '',
    this.title = '',
    this.onChanged,
    required this.listDropDownItem,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final String title;
  final List<MegaItemWidget<T>> listDropDownItem;
  final Function(T)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        MegaDropDownWidget<T>(
          controller: controller,
          typeModal: MegaDropTypeModal.bottom,
          prefixIcon: prefixIcon,
          hintText: hintText,
          listDropDownItem: listDropDownItem,
          onChanged: onChanged,
          overlayOffset: 120,
          title: title,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }
}
