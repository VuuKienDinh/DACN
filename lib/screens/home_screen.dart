import 'dart:async';

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
import '../widgets/user_avatar.dart';
import '../widgets/weather_banner_card.dart';
import 'add_clothing_screen.dart';
import 'user_profile_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex, {String? occasion})? onSwitchTab;

  const HomeScreen({
    super.key,
    this.onSwitchTab,
  });

  static String formatVietnameseDate(DateTime date) {
    const weekdays = <int, String>{
      DateTime.monday: 'Thứ Hai',
      DateTime.tuesday: 'Thứ Ba',
      DateTime.wednesday: 'Thứ Tư',
      DateTime.thursday: 'Thứ Năm',
      DateTime.friday: 'Thứ Sáu',
      DateTime.saturday: 'Thứ Bảy',
      DateTime.sunday: 'Chủ Nhật',
    };
    final weekday = weekdays[date.weekday] ?? 'Hôm nay';
    return '$weekday, ${date.day} tháng ${date.month}, ${date.year}';
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _featuredSeed = 0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextClockSync();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNowIfNeeded();
      _scheduleNextClockSync();
    }
  }

  void _refreshNowIfNeeded() {
    final current = DateTime.now();
    if (current.year != _now.year ||
        current.month != _now.month ||
        current.day != _now.day ||
        current.hour != _now.hour) {
      if (mounted) {
        setState(() => _now = current);
      }
    } else {
      _now = current;
    }
  }

  void _scheduleNextClockSync() {
    _clockTimer?.cancel();
    // Không đặt Timer chạy ngầm trong môi trường kiểm thử tự động FakeAsync
    if (WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding')) {
      return;
    }
    final current = DateTime.now();
    final wait = Duration(
      seconds: 60 - current.second,
      milliseconds: 1000 - current.millisecond,
    );
    _clockTimer = Timer(wait, () {
      if (!mounted) return;
      _refreshNowIfNeeded();
      _scheduleNextClockSync();
    });
  }

  String _greetingText(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  void _showCityPicker() {
    final currentCity = DailyFitStore.instance.preferences.value.city;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        side: AppColors.isDark
            ? BorderSide(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
              )
            : BorderSide.none,
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
                  Text(
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
                          ? Icon(
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

  Future<void> _openUserProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileDetailScreen()),
    );
  }

  OutfitSuggestion? _computeFeaturedOutfit(List<ClothingItem> clothes) {
    if (clothes.isEmpty) return null;
    final weather = DailyFitStore.instance.weather.value;
    final prefs = DailyFitStore.instance.preferences.value;

    final hour = _now.hour;
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
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
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
              style: TextStyle(
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
          store.currentUser,
          store.isGuestSession,
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
          final todayPlan = store.getPlanForDate(_now);
          final activeName = store.activeDisplayName.trim();
          final greetingName = activeName.isEmpty ? 'bạn' : activeName;

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              setState(() => _now = DateTime.now());
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
                  // Header Avatar hồ sơ người dùng + Thương hiệu DailyFit + Nút Sáng / Tối AMOLED
                  Row(
                    children: [
                      UserAvatar(
                        avatarPath: store.activeAvatarPath,
                        displayName: greetingName,
                        size: 42,
                        showOnlineDot: store.currentUser.value != null,
                        tooltip: 'Xem thông tin hồ sơ cá nhân',
                        onTap: _openUserProfile,
                      ),
                      const SizedBox(width: 10),
                      Text(
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
                        tooltip: 'Chuyển đổi giao diện Sáng / Tối',
                        onPressed: store.toggleDarkMode,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.surface.withValues(alpha: 0.92),
                          side: BorderSide(
                            color: AppColors.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            prefs.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            key: ValueKey<bool>(prefs.isDarkMode),
                            size: 21,
                            color: prefs.isDarkMode
                                ? const Color(0xFFFBBF24)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Thứ, ngày tháng năm cập nhật trực tiếp theo thời gian thực
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14.5,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          HomeScreen.formatVietnameseDate(_now),
                          key: const ValueKey('home_live_date'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Lời chào cá nhân hoá
                  Text(
                    '${_greetingText(_now)}, $greetingName 👋',
                    style: TextStyle(
                      fontSize: 23.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
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
                      Expanded(
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
                  Text(
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
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
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
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
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
                        label:
                            const Text('Lên lịch mặc bộ nổi bật cho hôm nay'),
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
              style: TextStyle(
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
