import 'package:flutter/material.dart';

class ContainerButtons extends StatelessWidget {
  const ContainerButtons({
    super.key,
    required this.buttons,
  });

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final double bottomPadding = bottom == 0 ? 8 : 22;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset.zero,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
    );
  }
}
