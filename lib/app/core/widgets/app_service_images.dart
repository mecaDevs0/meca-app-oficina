import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../core.dart';

class AppServiceImages extends StatelessWidget {
  const AppServiceImages({super.key, required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos',
          style: TextStyle(
            color: AppColors.abbey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (images.isEmpty)
          const Text(
            'Nenhuma foto disponível',
            style: TextStyle(
              color: AppColors.boulder,
              fontWeight: FontWeight.w300,
            ),
          ),
        Row(
          mainAxisAlignment: images.length >= 3
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: List.generate(
            images.length > 3 ? 3 : images.length,
            (index) {
              if (index == 2 && images.length > 3) {
                return Stack(
                  children: [
                    MegaCachedNetworkImage(
                      imageUrl: '${images[index]}?w=100&h=100',
                      width: 100,
                      height: 100,
                      radius: 8,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      child: Center(
                        child: Text(
                          '+${images.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: MegaCachedNetworkImage(
                  imageUrl: images[index],
                  width: 100,
                  height: 100,
                  radius: 8,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
