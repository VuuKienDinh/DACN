import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../models/user_preferences.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/outfit_showcase_card.dart';
import '../widgets/schedule_outfit_sheet.dart';
import '../widgets/state_views.dart';
import '../widgets/weather_banner_card.dart';
import 'add_clothing_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex, {String? occasion})? onSwitchTab;

  const HomeScreen({
    super.key,
    this.onSwitchTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _featuredSeed = 0;

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  void _showCityPicker() {
    final currentCity = DailyFitStore.instance.preferences.value.city;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn khu vực thời tiết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...UserPreferences.supportedCities.map((city) {
                    final active = city.name == currentCity;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      leading: Icon(
                        Icons.location_on_rounded,
                        color: active ? AppColors.primary : AppColors.textMuted,
                      ),
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? AppColors.primary : AppColors.text,
                        ),
                      ),
                      trailing: active
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        DailyFitStore.instance.updateCity(city.name);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddClothing() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddClothingScreen()),
    );
  }

  OutfitSuggestion? _computeFeaturedOutfit(List<ClothingItem> clothes) {
    if (clothes.isEmpty) return null;
    final weather = DailyFitStore.instance.weather.value;
    final prefs = DailyFitStore.instance.preferences.value;

    final hour = DateTime.now().hour;
    final defaultOccasion =
        (hour >= 7 && hour <= 17) ? 'Đi làm' : 'Đi chơi';

    final list = OutfitService.generateOutfits(
      clothes,
      defaultOccasion,
      weather: weather,
      preferences: prefs,
      variationSeed: _featuredSeed,
      limit: 4,
    );
    if (list.isEmpty) return null;
    return list[_featuredSeed % list.length];
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        borderRadius: 20,
        enableBlur: false,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
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
          store.preferences,
          store.weather,
          store.isLoadingWeather,
          store.favorites,
          store.plannedOutfits,
          ClothingService.instance.items,
          ClothingService.instance.syncStatus,
        ]),
        builder: (context, _) {
          final prefs = store.preferences.value;
          final weather = store.weather.value;
          final clothes = ClothingService.instance.items.value;
          final featured = _computeFeaturedOutfit(clothes);
          final todayPlan = store.getPlanForDate(DateTime.now());
          final greetingName = prefs.displayName.trim().isEmpty
              ? 'bạn'
              : prefs.displayName.trim();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await Future.wait([
                store.refreshWeather(),
                ClothingService.instance.loadClothes(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Thương hiệu DailyFit
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'DailyFit',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Thêm trang phục nhanh',
                        onPressed: _openAddClothing,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.white.withValues(alpha: 0.85),
                        ),
                        icon: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Lời chào cá nhân hoá
                  Text(
                    '${_greetingText()}, $greetingName 👋',
                    style: const TextStyle(
                      fontSize: 23.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cùng chọn bộ trang phục tự tin và hợp thời tiết nhất hôm nay.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Thẻ kính Thời tiết & Lời khuyên phối đồ
                  WeatherBannerCard(
                    weather: weather,
                    isLoading: store.isLoadingWeather.value,
                    useCelsius: prefs.useCelsius,
                    onRefresh: store.refreshWeather,
                    onTapCity: _showCityPicker,
                  ),

                  const SizedBox(height: 18),

                  // Hàng thống kê nhanh
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.checkroom_rounded,
                        value: '${clothes.length}',
                        label: 'Trang phục',
                        onTap: () => widget.onSwitchTab?.call(2),
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.favorite_rounded,
                        value: '${store.favorites.value.length}',
                        label: 'Yêu thích',
                        onTap: () => widget.onSwitchTab?.call(3),
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.event_note_rounded,
                        value: '${store.plannedOutfits.value.length}',
                        label: 'Lịch mặc',
                        onTap: () => widget.onSwitchTab?.call(3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tiêu đề Bộ đồ nổi bật
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bộ đồ nổi bật hôm nay',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _featuredSeed++;
                          });
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 17),
                        label: const Text('Đổi bộ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (ClothingService.instance.syncStatus.value ==
                          BackendSyncStatus.syncing &&
                      clothes.isEmpty)
                    const GlassLoadingCard(
                      message: 'Đang chuẩn bị bộ trang phục nổi bật...',
                    )
                  else if (featured == null)
                    GlassEmptyStateCard(
                      icon: Icons.checkroom_outlined,
                      title: 'Chưa đủ trang phục để gợi ý',
                      subtitle:
                          'Hãy thêm ít nhất áo và quần/váy vào tủ đồ để DailyFit tạo gợi ý thông minh cho bạn.',
                      actionLabel: 'Thêm quần áo ngay',
                      onAction: _openAddClothing,
                    )
                  else
                    OutfitShowcaseCard(
                      outfit: featured,
                      showHeroBanner: true,
                      isFavorite: store.isFavorite(featured.id),
                      onToggleFavorite: () async {
                        final added = await store.toggleFavorite(featured);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Đã lưu vào Bộ đồ yêu thích'
                                  : 'Đã bỏ khỏi Bộ đồ yêu thích',
                            ),
                          ),
                        );
                      },
                      primaryCtaLabel: 'Phối đồ ngay · Style My Outfit',
                      onPrimaryCta: () => widget.onSwitchTab?.call(1),
                    ),

                  const SizedBox(height: 22),

                  // Gợi ý nhanh theo hoàn cảnh
                  const Text(
                    'Phối nhanh theo hoàn cảnh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _quickOccasionChip(
                        icon: Icons.school_rounded,
                        label: 'Đi học',
                      ),
                      const SizedBox(width: 10),
                      _quickOccasionChip(
                        icon: Icons.business_center_rounded,
                        label: 'Đi làm',
                      ),
                      const SizedBox(width: 10),
                      _quickOccasionChip(
                        icon: Icons.local_cafe_rounded,
                        label: 'Đi chơi',
                      ),
                    ],
                  ),

                  if (todayPlan != null) ...[
                    const SizedBox(height: 22),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      enableBlur: false,
                      onTap: () => widget.onSwitchTab?.call(3),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lịch mặc hôm nay của bạn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  todayPlan.outfit.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ] else if (featured != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => showScheduleOutfitSheet(
                          context,
                          outfit: featured,
                        ),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Lên lịch mặc bộ nổi bật cho hôm nay'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _quickOccasionChip({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        borderRadius: 18,
        enableBlur: false,
        onTap: () => widget.onSwitchTab?.call(1, occasion: label),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
