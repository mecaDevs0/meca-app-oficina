import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';

class TabItem extends StatefulWidget {
  const TabItem({
    super.key,
    required this.onTap,
    required this.homeTab,
    required this.selectedTab,
  });

  final void Function() onTap;
  final HomeSection homeTab;
  final HomeSection selectedTab;

  @override
  State<TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<TabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get isSelected => widget.homeTab == widget.selectedTab;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      widget.homeTab.icon,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isSelected ? AppColors.primaryColor : AppColors.grayMedium,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.homeTab.description,
                      style: GoogleFonts.inter(
                        color: isSelected 
                            ? AppColors.primaryColor 
                            : AppColors.grayMedium,
                        fontSize: 16,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
