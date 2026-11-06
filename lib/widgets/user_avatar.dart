import 'dart:io';

import 'package:flutter/material.dart';

import '../config/config_url.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String avatarPath;
  final String displayName;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool showCameraBadge;
  final bool showOnlineDot;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    required this.displayName,
    this.size = 44,
    this.onTap,
    this.tooltip,
    this.showCameraBadge = false,
    this.showOnlineDot = false,
  });

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'DF';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildInitialsFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(displayName),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    final trimmed = avatarPath.trim();
    if (trimmed.isEmpty) {
      return _buildInitialsFallback();
    }

    if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) {
      return Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitialsFallback(),
      );
    }

    if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) {
      if (!ConfigUrl.hasBackendUrl) {
        return _buildInitialsFallback();
      }
      final imageUrl = Uri.parse(ConfigUrl.baseUrl)
          .resolve(trimmed.startsWith('/') ? trimmed : '/$trimmed')
          .toString();
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitialsFallback(),
      );
    }

    return Image.file(
      File(trimmed),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildInitialsFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.55)
                  : AppColors.white,
              width: size >= 72 ? 2.6 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.32 : 0.22),
                blurRadius: size >= 72 ? 18 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _buildAvatarImage(),
          ),
        ),
        if (showCameraBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: (size * 0.32).clamp(22.0, 32.0),
              height: (size * 0.32).clamp(22.0, 32.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF0B1120) : AppColors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: (size * 0.16).clamp(11.0, 16.0),
                color: AppColors.white,
              ),
            ),
          )
        else if (showOnlineDot)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: (size * 0.27).clamp(10.0, 14.0),
              height: (size * 0.27).clamp(10.0, 14.0),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF000000) : AppColors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      content = Tooltip(
        message: tooltip!,
        child: content,
      );
    }

    return content;
  }
}

