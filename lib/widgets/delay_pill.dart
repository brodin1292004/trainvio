import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';

Color delayColor(int delayMinutes) {
  if (delayMinutes <= 0) return AppColors.onTime;
  if (delayMinutes < 30) return AppColors.late;
  return AppColors.veryLate;
}

/// "On time" / "18 min late", coloured like a signal.
class DelayPill extends StatelessWidget {
  const DelayPill({super.key, required this.delayMinutes});

  final int delayMinutes;

  @override
  Widget build(BuildContext context) {
    final Color color = delayColor(delayMinutes);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            delayLabel(delayMinutes),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
