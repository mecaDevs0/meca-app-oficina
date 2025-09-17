import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/shared/extensions/extensions.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../../../routes/app_pages.dart';

class ItemService extends StatefulWidget {
  const ItemService({
    super.key,
    required this.schedule,
  });

  final ScheduleServiceModel schedule;

  @override
  State<ItemService> createState() => _ItemServiceState();
}

class _ItemServiceState extends State<ItemService>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 0,
      end: 8,
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

  String get _formatPhone {
    if (widget.schedule.profile.phone.isNullOrEmpty) {
      return '';
    }
    final phone = widget.schedule.profile.phone;
    return UtilBrasilFields.obterTelefone(phone!);
  }

  String get newMethod {
    if (widget.schedule.workshopServices.isEmpty) {
      return 'Nenhum serviço';
    }
    if (widget.schedule.workshopServices.length == 1) {
      return '1 serviço';
    }
    return '${widget.schedule.workshopServices.length} serviços';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: () => Get.toNamed(
              Routes.serviceDetails,
              arguments: ServiceArgs(widget.schedule.id),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.grayBorderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with date and status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.schedule.date.toddMMyyyyasHHmm(),
                            style: GoogleFonts.inter(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AppStatusChip(
                          status: ScheduleStatus.values[widget.schedule.status],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Company name and phone
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.schedule.workshop.companyName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.fontDarkGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_formatPhone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grayBorderColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatPhone,
                              style: GoogleFonts.inter(
                                color: AppColors.grayMedium,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Vehicle info
                    AppCarDesc(vehicle: widget.schedule.vehicle),
                    const SizedBox(height: 16),
                    
                    // Services info and action
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.chetwodeBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            AppImages.icTools,
                            width: 16,
                            height: 16,
                            color: AppColors.chetwodeBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          newMethod,
                          style: GoogleFonts.inter(
                            color: AppColors.grayMedium,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ver detalhes',
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
