import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (status) {
      case 'Available':
        bg = AppColors.statusAvailableBg;
        textColor = AppColors.statusAvailableText;
        borderColor = AppColors.statusAvailableBorder;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'In Use':
        bg = AppColors.statusInUseBg;
        textColor = AppColors.statusInUseText;
        borderColor = AppColors.statusInUseBorder;
        icon = Icons.accessibility_new_rounded;
        break;
      case 'In Laundry':
        bg = AppColors.statusInLaundryBg;
        textColor = AppColors.statusInLaundryText;
        borderColor = AppColors.statusInLaundryBorder;
        icon = Icons.local_laundry_service_outlined;
        break;
      case 'Ready to Store':
        bg = AppColors.statusReadyToStoreBg;
        textColor = AppColors.statusReadyToStoreText;
        borderColor = AppColors.statusReadyToStoreBorder;
        icon = Icons.iron_outlined;
        break;
      case 'Unavailable':
      default:
        bg = AppColors.statusUnavailableBg;
        textColor = AppColors.statusUnavailableText;
        borderColor = AppColors.statusUnavailableBorder;
        icon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
