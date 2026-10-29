import 'dart:io';

import 'package:flutter/material.dart';

import '../config/config_url.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';

class ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onDelete;

  const ClothingCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = AppColors.swatchForName(item.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.95),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildClothingImage(item.imagePath),
                // Nhãn loại trang phục góc trên trái
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.type,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Nút xóa góc trên phải
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.color} · ${item.style}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildClothingImage(String imagePath) {
  final path = imagePath.trim();

  Widget placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.iceSurface,
            AppColors.softBlueTint,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 46,
          color: AppColors.primary,
        ),
      ),
    );
  }

  if (path.isEmpty) {
    return placeholder();
  }

  if (path.startsWith('https://') || path.startsWith('http://')) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.iceSurface,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => placeholder(),
    );
  }

  if (path.startsWith('/uploads/') || path.startsWith('uploads/')) {
    if (!ConfigUrl.hasBackendUrl) {
      return placeholder();
    }
    final imageUrl = Uri.parse(ConfigUrl.baseUrl)
        .resolve(path.startsWith('/') ? path : '/$path')
        .toString();

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder(),
    );
  }

  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => placeholder(),
  );
}
