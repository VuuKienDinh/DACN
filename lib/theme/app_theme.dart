import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  /// Trạng thái chế độ Tối AMOLED hiện hành (đồng bộ tức thì cùng DailyFitStore)
  static bool isDark = false;

  // Bảng màu chủ đạo DailyFit: Blue & White Glassmorphism (Sáng) / True AMOLED Black (Tối)
  static Color get background =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF4F8FF);

  static Color get surface =>
      isDark ? const Color(0xFF0B1120) : Colors.white;

  static Color get primary =>
      isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

  static const Color primaryDark = Color(0xFF1D4ED8);

  static Color get skyAccent =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);

  static Color get iceSurface =>
      isDark ? const Color(0xFF131D33) : const Color(0xFFEFF6FF);

  static Color get softBlueTint =>
      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);

  // Độ tương phản chữ chuẩn WCAG AA trên cả nền Sáng và nền Đen sâu AMOLED
  static Color get text =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

  static Color get textSecondary =>
      isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

  static Color get textMuted =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static const Color white = Colors.white;

  // Viền thẻ kính và viền chấm màu thích ứng Sáng / Tối
  static Color get cardBorder => isDark
      ? const Color(0xFF38BDF8).withValues(alpha: 0.18)
      : Colors.white.withValues(alpha: 0.92);

  static Color get subtleBorder => isDark
      ? Colors.white.withValues(alpha: 0.22)
      : Colors.black.withValues(alpha: 0.14);

  // Trạng thái ngữ nghĩa
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static Color get successText =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF047857);

  static Color get warningText =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  // Giữ tương thích ngược với các tham chiếu màu cũ nếu có
  static const Color sage = Color(0xFFDBEAFE);
  static const Color beige = Color(0xFFE0F2FE);

  // Gradient chủ đạo cho nút CTA & điểm nhấn
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF0284C7),
    ],
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E40AF),
      Color(0xFF2563EB),
      Color(0xFF0EA5E9),
    ],
  );

  // Ánh xạ tên màu tiếng Việt sang mã màu hiển thị trực quan
  static Color swatchForName(String colorName) {
    switch (colorName.trim()) {
      case 'Trắng':
        return const Color(0xFFF8FAFC);
      case 'Đen':
        return const Color(0xFF1E293B);
      case 'Xám':
        return const Color(0xFF94A3B8);
      case 'Xanh dương':
        return const Color(0xFF2563EB);
      case 'Xanh lá':
        return const Color(0xFF10B981);
      case 'Đỏ':
        return const Color(0xFFEF4444);
      case 'Hồng':
        return const Color(0xFFF472B6);
      case 'Vàng':
        return const Color(0xFFFBBF24);
      case 'Cam':
        return const Color(0xFFFB923C);
      case 'Tím':
        return const Color(0xFF8B5CF6);
      case 'Nâu':
        return const Color(0xFF92400E);
      case 'Be':
        return const Color(0xFFD6C7B2);
      case 'Kem':
        return const Color(0xFFF5EFE6);
      default:
        return const Color(0xFF60A5FA);
    }
  }
}

class AppTheme {
  static void applySystemOverlay({required bool isDark}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? const Color(0xFF000000) : const Color(0xFFF4F8FF),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  static ThemeData get lightTheme {
    final interFamily = GoogleFonts.inter().fontFamily;
    const primary = Color(0xFF2563EB);
    const text = Color(0xFF0F172A);
    const textSecondary = Color(0xFF475569);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: interFamily,
      scaffoldBackgroundColor: const Color(0xFFF4F8FF),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.white,
        secondary: const Color(0xFF0EA5E9),
        surface: Colors.white,
        onSurface: text,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 22,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(
            color: primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 18,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        selectedColor: primary,
        secondarySelectedColor: primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: primary.withValues(alpha: 0.14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : textSecondary,
          ),
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final interFamily = GoogleFonts.inter().fontFamily;
    const primary = Color(0xFF3B82F6);
    const ctaBlue = Color(0xFF2563EB);
    const surface = Color(0xFF0B1120);
    const chipBg = Color(0xFF131D33);
    const text = Color(0xFFF1F5F9);
    const textSecondary = Color(0xFFCBD5E1);
    const textMuted = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: interFamily,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: Color(0xFF38BDF8),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
          ),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.inter(color: textMuted, fontSize: 13.5),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ctaBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 22,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(
            color: primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 18,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: ctaBlue,
        secondarySelectedColor: ctaBlue,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : textSecondary,
          ),
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ctaBlue
              : chipBg,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.22),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.24),
          ),
        ),
      ),
    );
  }
}
