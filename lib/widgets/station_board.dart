import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The app's signature element: the train's position shown the way a
/// platform name board shows it, black lettering on yellow.
class StationBoard extends StatelessWidget {
  const StationBoard({
    super.key,
    required this.caption,
    required this.name,
    required this.code,
  });

  final String caption;
  final String name;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$caption $name',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.boardYellow,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.ink, width: 3),
          ),
          child: Column(
            children: <Widget>[
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
