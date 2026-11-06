import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_scaffold.dart';
import 'add_clothing_screen.dart';

class ClothingDetailScreen extends StatefulWidget {
  final ClothingItem initialItem;

  const ClothingDetailScreen({
    super.key,
    required this.initialItem,
  });

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  late ClothingItem _currentItem;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.initialItem;
  }

  ClothingItem _resolveLiveItem() {
    final list = ClothingService.instance.items.value;
    for (final candidate in list) {
      if (candidate.id == _currentItem.id) {
        return candidate;
      }
    }
    return _currentItem;
  }

  String _storageLabel(ClothingItem item) {
    if (item.id.startsWith('mock-')) return 'Trang phục mẫu';
    if (item.id.startsWith('local-') || item.isLocalOnly) {
      return 'Lưu trên thiết bị';
    }
    return 'Đã lưu SQL Server';
  }

  bool _isServerSynced(ClothingItem item) {
    return !item.id.startsWith('mock-') &&
        !item.id.startsWith('local-') &&
        !item.isLocalOnly;
  }

  Future<void> _openEditScreen(ClothingItem item) async {
    final updated = await Navigator.push<ClothingItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddClothingScreen(editingItem: item),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _currentItem = updated;
      });
    }
  }

  Future<void> _confirmAndDelete(ClothingItem item) async {
    if (_isDeleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Xóa trang phục'),
        content: Text('Bạn có chắc muốn xóa "${item.name}" khỏi tủ đồ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isDeleting = true);
    try {
      await ClothingService.instance.deleteClothing(item.id);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Đã xóa "${item.name}" khỏi tủ đồ')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      messenger?.showSnackBar(
        SnackBar(content: Text('Không thể xóa trang phục: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ClothingService.instance.items,
        DailyFitStore.instance.preferences,
      ]),
      builder: (context, _) {
        final item = _resolveLiveItem();
        final swatch = AppColors.swatchForName(item.color);
        final styles = item.styles;
        final occasions = OutfitService.suitableOccasionsForItem(item);
        final synced = _isServerSynced(item);

        return GlassScaffold(
          appBar: AppBar(
            title: const Text('Chi tiết trang phục'),
            actions: [
              IconButton(
                tooltip: 'Chỉnh sửa trang phục',
                onPressed: () => _openEditScreen(item),
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                tooltip: 'Xóa trang phục',
                onPressed:
                    _isDeleting ? null : () => _confirmAndDelete(item),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Khung xem ảnh sản phẩm lớn, đầy đủ (hỗ trợ chụm 2 ngón phóng to)
                GlassCard(
                  padding: const EdgeInsets.all(10),
                  enableBlur: false,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 300,
                          width: double.infinity,
                          color: AppColors.isDark
                              ? const Color(0xFF111827)
                              : AppColors.iceSurface,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 3.5,
                                child: buildClothingImage(
                                  item.imagePath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    item.type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: (synced
                                              ? AppColors.success
                                              : AppColors.warning)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        synced
                                            ? Icons.cloud_done_rounded
                                            : Icons.smartphone_rounded,
                                        size: 13.5,
                                        color: synced
                                            ? AppColors.successText
                                            : AppColors.warningText,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _storageLabel(item),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: synced
                                              ? AppColors.successText
                                              : AppColors.warningText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chụm 2 ngón tay để phóng to xem kỹ chất liệu & kiểu dáng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Thẻ thông tin chi tiết trang phục
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hàng thuộc tính: Danh mục & Màu sắc chủ đạo
                      Row(
                        children: [
                          Expanded(
                            child: _attributeTile(
                              label: 'Danh mục',
                              value: item.type,
                              leading: Icon(
                                Icons.checkroom_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _attributeTile(
                              label: 'Màu sắc chủ đạo',
                              value: item.color,
                              leading: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: swatch,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.subtleBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Tất cả phong cách thời trang
                      Text(
                        'Phong cách thời trang (${styles.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: styles.map((st) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.26),
                              ),
                            ),
                            child: Text(
                              st,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (occasions.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Hoàn cảnh mặc phù hợp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: occasions.map((occ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.iceSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.subtleBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 13.5,
                                    color: AppColors.skyAccent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    occ,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Nút Chỉnh sửa đầy đủ giống hệt lúc Thêm đồ
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () => _openEditScreen(item),
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: const Text('Chỉnh sửa thông tin trang phục'),
                  ),
                ),

                const SizedBox(height: 12),

                // Nút Xóa trang phục khỏi tủ đồ
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  onPressed:
                      _isDeleting ? null : () => _confirmAndDelete(item),
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  label: const Text('Xóa khỏi tủ đồ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attributeTile({
    required String label,
    required String value,
    required Widget leading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.iceSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              leading,
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

