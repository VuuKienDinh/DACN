import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../theme/app_theme.dart';
import 'clothing_card.dart';
import 'glass_card.dart';

class OutfitShowcaseCard extends StatelessWidget {
  final OutfitSuggestion outfit;
  final bool isFavorite;
  final bool showHeroBanner;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onSchedule;
  final String? primaryCtaLabel;
  final VoidCallback? onPrimaryCta;

  const OutfitShowcaseCard({
    super.key,
    required this.outfit,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.showHeroBanner = false,
    this.onSchedule,
    this.primaryCtaLabel,
    this.onPrimaryCta,
  });

  Widget _buildItemThumb(ClothingItem item) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
              child: buildClothingImage(item.imagePath),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          Text(
            item.type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      enableBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeroBanner && outfit.heroImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 215,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    buildClothingImage(outfit.heroImageUrl!),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${outfit.score.round()}% Phù hợp',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: AppColors.white.withValues(alpha: 0.90),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: isFavorite
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              outfit.occasion,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            outfit.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            // Tiêu đề gọn cho danh sách gợi ý & lịch đồ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              outfit.occasion,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.iceSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${outfit.score.round()} điểm',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        outfit.title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        isFavorite ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Nhãn tương thích thời tiết
          Row(
            children: [
              const Icon(
                Icons.wb_twilight_rounded,
                size: 15,
                color: AppColors.skyAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  outfit.weatherTag,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.skyAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dải các món đồ cấu thành bộ trang phục
          SizedBox(
            height: 138,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: outfit.items.map(_buildItemThumb).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Lý do gợi ý
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.iceSurface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              outfit.reason,
              style: const TextStyle(
                fontSize: 12.8,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Hàng nút hành động
          if (primaryCtaLabel != null && onPrimaryCta != null)
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                  ),
                  onPressed: onPrimaryCta,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: Text(
                    primaryCtaLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 13,
                      ),
                    ),
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: isFavorite ? AppColors.error : AppColors.primary,
                    ),
                    label: Text(
                      isFavorite ? 'Đã lưu' : 'Lưu bộ đồ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (onSchedule != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 13,
                        ),
                      ),
                      onPressed: onSchedule,
                      icon: const Icon(
                        Icons.event_available_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Lên lịch mặc',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
