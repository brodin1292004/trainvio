import 'package:flutter/material.dart';

/// Colours taken from the railway itself: coach blue, the yellow of a
/// station name board, platform grey and the three signal colours.
class AppColors {
  AppColors._();

  static const Color railBlue = Color(0xFF1B4F9C);
  static const Color deepBlue = Color(0xFF0F2F5F);
  static const Color boardYellow = Color(0xFFFFC400);
  static const Color ink = Color(0xFF101828);
  static const Color muted = Color(0xFF5B6472);
  static const Color platform = Color(0xFFF2F4F7);
  static const Color line = Color(0xFFD9DEE5);
  static const Color onTime = Color(0xFF1E8E4E);
  static const Color late = Color(0xFFB86E00);
  static const Color veryLate = Color(0xFFC62F2F);
}

ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.railBlue,
    primary: AppColors.railBlue,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.platform,
  );
}

/// Shared look for every text field in the app.
InputDecoration fieldDecoration({
  required String hint,
  IconData? icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AppColors.line, 1),
    enabledBorder: border(AppColors.line, 1),
    focusedBorder: border(AppColors.railBlue, 2),
  );
}

/// White panel used to group related content.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}
