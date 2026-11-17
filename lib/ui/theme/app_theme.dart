import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kiểu chữ: Plus Jakarta Sans cho tiêu đề / số, Inter cho nội dung.
class AppText {
  AppText._();

  static TextStyle _jakarta(double size, FontWeight w, {double? height, double spacing = 0, Color color = AppColor.text}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, height: height, letterSpacing: spacing, color: color);

  static TextStyle _inter(double size, FontWeight w, {double? height, double spacing = 0, Color color = AppColor.text}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, height: height, letterSpacing: spacing, color: color);

  static TextStyle display({Color color = AppColor.forest}) => _jakarta(30, FontWeight.w800, height: 38 / 30, spacing: -0.6, color: color);
  static TextStyle headlineLg({Color color = AppColor.forest}) => _jakarta(22, FontWeight.w700, height: 28 / 22, spacing: -0.2, color: color);
  static TextStyle headlineMd({Color color = AppColor.text}) => _jakarta(20, FontWeight.w700, height: 26 / 20, spacing: -0.2, color: color);
  static TextStyle headlineSm({Color color = AppColor.text}) => _jakarta(16, FontWeight.w700, height: 22 / 16, color: color);
  static TextStyle stat({Color color = AppColor.forest, double size = 24}) => _jakarta(size, FontWeight.w800, height: 1.15, spacing: -0.5, color: color);

  static TextStyle bodyLg({Color color = AppColor.text}) => _inter(16, FontWeight.w400, height: 1.5, color: color);
  static TextStyle body({Color color = AppColor.text}) => _inter(14, FontWeight.w400, height: 20 / 14, color: color);
  static TextStyle bodySm({Color color = AppColor.textMuted}) => _inter(12, FontWeight.w400, height: 16 / 12, color: color);
  static TextStyle labelLg({Color color = AppColor.text}) => _inter(14, FontWeight.w600, height: 20 / 14, color: color);
  static TextStyle label({Color color = AppColor.text}) => _inter(12, FontWeight.w600, height: 16 / 12, color: color);
  static TextStyle labelSm({Color color = AppColor.textMuted}) => _inter(10, FontWeight.w700, height: 14 / 10, spacing: 0.4, color: color);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: AppColor.primary, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColor.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColor.primary,
        onPrimary: Colors.white,
        secondary: AppColor.forest,
        tertiary: AppColor.accent,
        surface: AppColor.card,
        onSurface: AppColor.text,
        error: AppColor.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: AppColor.text, displayColor: AppColor.text),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColor.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.headlineSm(),
      ),
      dividerTheme: const DividerThemeData(color: AppColor.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColor.text,
        contentTextStyle: AppText.labelLg(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Color(0x730D2E18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        barrierColor: const Color(0x730D2E18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColor.primary : Colors.white),
        side: const BorderSide(color: AppColor.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColor.primary),
    );
  }
}
