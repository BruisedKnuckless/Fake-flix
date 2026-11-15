import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF181818);
  static const surface2 = Color(0xFF2A2A2A);
  static const line = Color(0xFF404040);
  static const soft = Color(0xFFE5E5E5);
  static const muted = Color(0xFFB3B3B3);
  static const dim = Color(0xFF777777);
  static const red = Color(0xFFE0001E);
  static const green = Color(0xFF46D369);
}

/// Profile avatar colours. A profile stores the index into this list.
const avatarColors = <Color>[
  Color(0xFFE0001E),
  Color(0xFF1F6FEB),
  Color(0xFF2EA043),
  Color(0xFFD29922),
  Color(0xFF8957E5),
  Color(0xFFDB61A2),
  Color(0xFF12A5A5),
  Color(0xFF6E7681),
];

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: AppColors.red,
      surface: AppColors.surface,
    ),
    // No Material ink ripples: taps use the press-in effect in Pressable instead
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
  );
}
