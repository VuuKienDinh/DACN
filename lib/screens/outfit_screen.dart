import 'package:flutter/material.dart';

import '../models/outfit_suggestion.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/outfit_showcase_card.dart';
import '../widgets/schedule_outfit_sheet.dart';
import '../widgets/state_views.dart';
import 'add_clothing_screen.dart';

class OutfitScreen extends StatefulWidget {
  final String? initialOccasion;

  const OutfitScreen({
    super.key,
    this.initialOccasion,
  });

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  late String _occasion;
  int _variationSeed = 0;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _occasion = widget.initialOccasion ?? 'Đi học';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ClothingService.instance.items.value.isEmpty &&
          ClothingService.instance.syncStatus.value == BackendSyncStatus.idle) {
        _reloadWardrobe();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OutfitScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOccasion != null &&
        widget.initialOccasion != oldWidget.initialOccasion &&
        widget.initialOccasion != _occasion) {
      setState(() {
        _occasion = widget.initialOccasion!;
        _variationSeed = 0;
      });
    }
  }

  Future<void> _reloadWardrobe() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    try {
      await ClothingService.instance.loadClothes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể đồng bộ tủ đồ: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _refreshSuggestions() {
    setState(() {
      _variationSeed++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text('Đã làm mới gợi ý cho dịp "$_occasion"'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DailyFitStore.instance;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          ClothingService.instance.items,
          store.weather,
          store.preferences,
          store.favorites,
        ]),
        builder: (context, _) {
          final clothes = ClothingService.instance.items.value;
          final weather = store.weather.value;
          final prefs = store.preferences.value;

          final List<OutfitSuggestion> suggestions = clothes.isEmpty
              ? const []
              : OutfitService.generateOutfits(
                  clothes,
                  _occasion,
                  weather: weather,
                  preferences: prefs,
                  variationSeed: _variationSeed,
                  limit: 4,
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gợi ý phối đồ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gợi ý cho Đi học, Đi làm, Đi chơi và sự kiện',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshSuggestions,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Làm mới'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Khung lọc hoàn cảnh + Thông tin cá nhân hoá
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn hoàn cảnh xuất hiện',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: OutfitService.allOccasions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = OutfitService.allOccasions[index];
                            final selected = item == _occasion;
                            return ChoiceChip(
                              label: Text(item),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _occasion = item;
                                  _variationSeed = 0;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      if (weather != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.iceSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.thermostat_rounded,
                                size: 17,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đang tối ưu theo ${weather.city} (${weather.formatTemperature(useCelsius: prefs.useCelsius)} · ${weather.condition}) & phong cách ${prefs.preferredStyles.take(2).join(", ")}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  GlassStatusBanner(
                    icon: Icons.error_outline_rounded,
                    accentColor: AppColors.error,
                    message: _errorMessage!,
                    actionLabel: 'Thử lại',
                    onAction: _reloadWardrobe,
                  ),
                ],

                const SizedBox(height: 20),

                if (_isRefreshing)
                  const GlassLoadingCard(
                    message: 'Đang phân tích tủ đồ và thời tiết...',
                  )
                else if (suggestions.isEmpty)
                  GlassEmptyStateCard(
                    icon: Icons.style_outlined,
                    title: 'Chưa đủ món đồ để kết hợp',
                    subtitle:
                        'Hãy bổ sung ít nhất 1 chiếc áo và 1 chiếc quần/váy (hoặc đầm) vào Tủ đồ để hệ thống tạo gợi ý hoàn chỉnh.',
                    actionLabel: 'Thêm trang phục mới',
                    onAction: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddClothingScreen(),
                        ),
                      );
                    },
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đề xuất cho "$_occasion" (${suggestions.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Từ ${clothes.length} món trong tủ',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...suggestions.map((suggestion) {
                    final fav = store.isFavorite(suggestion.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutfitShowcaseCard(
                        outfit: suggestion,
                        isFavorite: fav,
                        onToggleFavorite: () async {
                          final added = await store.toggleFavorite(suggestion);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Đã lưu "${suggestion.title}" vào Yêu thích'
                                    : 'Đã bỏ lưu bộ trang phục',
                              ),
                            ),
                          );
                        },
                        onSchedule: () => showScheduleOutfitSheet(
                          context,
                          outfit: suggestion,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
