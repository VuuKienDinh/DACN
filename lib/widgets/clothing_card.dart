
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Xóa quần áo',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: onDelete,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.color} · ${item.style}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
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

  // Widget mặc định khi chưa có ảnh hoặc ảnh bị lỗi
  Widget placeholder() {
    return Container(
      color: AppColors.sage,
      child: const Center(
        child: Icon(
          Icons.checkroom,
          size: 55,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Trường hợp chưa có ảnh
  if (path.isEmpty) {
    return placeholder();
  }

  // Trường hợp ảnh đã lưu trên Backend
  if (path.startsWith('/uploads/') ||
      path.startsWith('https://') ||
      path.startsWith('http://')) {
    final imageUrl = path.startsWith('http')
        ? path
        : Uri.parse(Config_URL.baseUrl)
        .resolve(path)
        .toString();

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return placeholder();
      },
    );
  }

  // Hỗ trợ đường dẫn ảnh cục bộ từ code Flutter cũ
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) {
      return placeholder();
    },
  );
}

