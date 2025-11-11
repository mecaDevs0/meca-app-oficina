import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';
import '../providers/notification_provider.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDark = themeService.isDarkMode;
    final navBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
    final showAgendaBadge = notificationProvider.showAgendaBadge;
    final showProfileBadge = notificationProvider.showProfileBadge;
    
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: navBgColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Início'),
            _buildNavItem(context, 1, Icons.schedule_outlined, Icons.schedule, 'Agenda', showBadge: showAgendaBadge),
            _buildNavItem(context, 2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Financeiro'),
            _buildNavItem(context, 3, Icons.person_outline, Icons.person, 'Perfil', showBadge: showProfileBadge),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label, {bool showBadge = false}) {
    final isSelected = currentIndex == index;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF00C977).withOpacity(isDark ? 0.1 : 0.15) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
                ? Border.all(
                    color: const Color(0xFF00C977).withOpacity(isDark ? 0.3 : 0.4), 
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C977).withOpacity(isDark ? 0.2 : 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected 
                          ? const Color(0xFF00C977) 
                          : (isDark ? const Color(0xFF8B8B8B) : const Color(0xFF666666)),
                      size: 24,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected 
                      ? const Color(0xFF00C977) 
                      : (isDark ? const Color(0xFF8B8B8B) : const Color(0xFF666666)),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}