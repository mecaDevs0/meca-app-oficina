import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../core.dart';

/// Um widget que exibe um chip de status com base em um enum ou um rótulo.
///
/// O [AppStatusChip] pode ser configurado com um [status] ou um [label].
/// Se ambos forem fornecidos, o [status] terá prioridade.
///
/// O [status] define a cor de fundo, a cor da borda e o texto exibido.
/// O [label] define apenas o texto exibido e usa cores padrão.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, this.status, this.label})
      : assert(
          status != null || label != null,
          'Status ou label devem ser fornecidos',
        );

  final ScheduleStatus? status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final displayText = label ?? status!.name;
    final displayColor = label != null ? AppColors.primaryColor : status!.color;
    final borderColor = label != null ? AppColors.grayLineColor : status!.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: ShapeDecoration(
        color: label != null ? Colors.white : displayColor.withAlpha(36),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: borderColor),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: displayColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
