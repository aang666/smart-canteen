import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color _getBgColor() {
    switch (status) {
      case AppConstants.statusMenunggu:
        return AppColors.statusMenunggu.withValues(alpha: 0.15);
      case AppConstants.statusDiproses:
        return AppColors.statusDiproses.withValues(alpha: 0.15);
      case AppConstants.statusSiapDiambil:
        return AppColors.statusSiapDiambil.withValues(alpha: 0.15);
      case AppConstants.statusSelesai:
        return AppColors.statusSelesai.withValues(alpha: 0.15);
      case AppConstants.statusDibatalkan:
        return AppColors.statusDibatalkan.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case AppConstants.statusMenunggu:
        return const Color(0xFFB45309);
      case AppConstants.statusDiproses:
        return const Color(0xFF1D4ED8);
      case AppConstants.statusSiapDiambil:
        return const Color(0xFF047857);
      case AppConstants.statusSelesai:
        return const Color(0xFF374151);
      case AppConstants.statusDibatalkan:
        return const Color(0xFFB91C1C);
      default:
        return Colors.black87;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case AppConstants.statusMenunggu:
        return Icons.access_time_rounded;
      case AppConstants.statusDiproses:
        return Icons.restaurant_rounded;
      case AppConstants.statusSiapDiambil:
        return Icons.check_circle_outline_rounded;
      case AppConstants.statusSelesai:
        return Icons.done_all_rounded;
      case AppConstants.statusDibatalkan:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = AppConstants.statusLabels[status] ?? status;
    final color = _getTextColor();
    final bg = _getBgColor();
    final icon = _getIcon();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
