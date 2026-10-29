import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Bảng màu chủ đạo DailyFit: Blue & White Premium Glassmorphism
  static const Color background = Color(0xFFF4F8FF);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color skyAccent = Color(0xFF0EA5E9);
  static const Color iceSurface = Color(0xFFEFF6FF);
  static const Color softBlueTint = Color(0xFFDBEAFE);

  // Độ tương phản chữ chuẩn WCAG AA
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color white = Colors.white;

  // Trạng thái ngữ nghĩa
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

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
  static ThemeData get lightTheme {
    final interFamily = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      fontFamily: interFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.skyAccent,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white.withValues(alpha: 0.82),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
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
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.28),
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
        backgroundColor: AppColors.white.withValues(alpha: 0.8),
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
