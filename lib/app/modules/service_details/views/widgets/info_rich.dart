import 'package:flutter/material.dart';

import '../../../../data/data.dart';

class InfoRich extends StatelessWidget {
  const InfoRich({super.key, required this.status});

  final AlertStatus status;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Aguardando confirmar chegada do veículo',
      style: TextStyle(
        color: status.color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
