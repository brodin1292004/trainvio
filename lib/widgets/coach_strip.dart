import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The train drawn coach by coach from the engine end, so a passenger knows
/// where on the platform to stand. [highlight] marks the passenger's coach.
class CoachStrip extends StatelessWidget {
  const CoachStrip({super.key, required this.coaches, this.highlight});

  final List<String> coaches;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < coaches.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _Coach(
                label: coaches[i],
                position: i,
                highlighted: coaches[i] == highlight,
              ),
            ),
        ],
      ),
    );
  }
}

class _Coach extends StatelessWidget {
  const _Coach({
    required this.label,
    required this.position,
    required this.highlighted,
  });

  final String label;
  final int position;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bool engine = label == 'ENG';
    Color fill = Colors.white;
    Color text = AppColors.ink;
    Color border = AppColors.line;
    if (engine) {
      fill = AppColors.deepBlue;
      text = Colors.white;
      border = AppColors.deepBlue;
    }
    if (highlighted) {
      fill = AppColors.boardYellow;
      text = AppColors.ink;
      border = AppColors.ink;
    }
    return Semantics(
      label: engine
          ? 'Engine'
          : 'Coach $label, position $position from the engine'
              '${highlighted ? ', your coach' : ''}',
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            Container(
              width: 46,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(engine ? 10 : 5),
                border: Border.all(color: border, width: highlighted ? 2 : 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              engine ? '' : '$position',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
