import 'package:flutter/material.dart';

import '../models/outfit_suggestion.dart';
import '../models/planned_outfit.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/outfit_showcase_card.dart';
import '../widgets/schedule_outfit_sheet.dart';
import '../widgets/state_views.dart';

class CalendarScreen extends StatefulWidget {
  final VoidCallback? onOpenRecommendations;

  const CalendarScreen({
    super.key,
    this.onOpenRecommendations,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> _buildWeekDates() {
    final anchor = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    // Tạo dải 7 ngày từ 2 ngày trước tới 4 ngày sau để dễ lập kế hoạch
    return List.generate(
      7,
      (index) => anchor.add(Duration(days: index - 2)),
    );
  }

  String _weekdayShort(DateTime d) {
    const names = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return names[d.weekday % 7];
  }

  String _fullDateTitle(DateTime d) {
    final names = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ];
    final wd = names[d.weekday % 7];
    return '$wd, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickAnyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _autoPlanForSelectedDay() async {
    final store = DailyFitStore.instance;
    final clothes = ClothingService.instance.items.value;
    if (clothes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tủ đồ đang trống — hãy thêm trang phục trước nhé!'),
        ),
      );
      return;
    }

    final isWeekend = _selectedDate.weekday == DateTime.saturday ||
        _selectedDate.weekday == DateTime.sunday;
    final occasion = isWeekend ? 'Đi chơi' : 'Đi làm';

    final generated = OutfitService.generateOutfits(
      clothes,
      occasion,
      weather: store.weather.value,
      preferences: store.preferences.value,
      variationSeed: _selectedDate.day,
      limit: 1,
    );

    if (generated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đủ quần áo để tự động phối đồ')),
      );
      return;
    }

    await showScheduleOutfitSheet(
      context,
      outfit: generated.first,
      initialDate: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DailyFitStore.instance;
    final weekDates = _buildWeekDates();

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          store.plannedOutfits,
          store.favorites,
        ]),
        builder: (context, _) {
          final plans = store.plannedOutfits.value;
          final favorites = store.favorites.value;
          final selectedPlan = store.getPlanForDate(_selectedDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lịch phối đồ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tháng ${_selectedDate.month}, ${_selectedDate.year} · ${plans.length} ngày đã lên lịch',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickAnyDate,
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text('Chọn ngày'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dải ngày 7 ngày kính mờ
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  enableBlur: false,
                  child: Row(
                    children: weekDates.map((date) {
                      final selected = _isSameDay(date, _selectedDate);
                      final hasPlan =
                          plans.containsKey(PlannedOutfit.formatKey(date));

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient:
                                  selected ? AppColors.primaryGradient : null,
                              color: selected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _weekdayShort(date),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppColors.white.withValues(alpha: 0.9)
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasPlan
                                        ? (selected
                                            ? AppColors.white
                                            : AppColors.primary)
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Kế hoạch cho ngày đang chọn
                Text(
                  _fullDateTitle(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 10),

                if (selectedPlan == null)
                  GlassEmptyStateCard(
                    icon: Icons.event_available_outlined,
                    title: 'Chưa có bộ đồ cho ngày này',
                    subtitle:
                        'Tạo nhanh một gợi ý phù hợp hoặc chọn một bộ đồ từ mục Yêu thích bên dưới.',
                    actionLabel: 'Gợi ý & lên lịch cho ngày này',
                    onAction: _autoPlanForSelectedDay,
                  )
                else
                  _buildPlannedDayCard(selectedPlan),

                const SizedBox(height: 26),

                // Mục Bộ đồ yêu thích (Favorites)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bộ đồ yêu thích (${favorites.length})',
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (widget.onOpenRecommendations != null)
                      TextButton.icon(
                        onPressed: widget.onOpenRecommendations,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                        label: const Text('Khám phá thêm'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (favorites.isEmpty)
                  GlassEmptyStateCard(
                    icon: Icons.favorite_border_rounded,
                    title: 'Chưa có bộ đồ yêu thích',
                    subtitle:
                        'Nhấn biểu tượng trái tim trên bất kỳ gợi ý phối đồ nào để lưu vào bộ sưu tập cá nhân.',
                    actionLabel: 'Xem gợi ý phối đồ',
                    onAction: widget.onOpenRecommendations,
                  )
                else
                  ...favorites.map((OutfitSuggestion favOutfit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OutfitShowcaseCard(
                        outfit: favOutfit,
                        isFavorite: true,
                        onToggleFavorite: () {
                          store.toggleFavorite(favOutfit);
                        },
                        onSchedule: () => showScheduleOutfitSheet(
                          context,
                          outfit: favOutfit,
                          initialDate: _selectedDate,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlannedDayCard(PlannedOutfit plan) {
    final store = DailyFitStore.instance;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      enableBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.occasion,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (plan.isWorn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Đã mặc',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Xoá lịch ngày này',
                onPressed: () async {
                  await store.removePlanForDate(_selectedDate);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xoá lịch phối đồ')),
                  );
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.outfit.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          if (plan.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Ghi chú: ${plan.note}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plan.outfit.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final item = plan.outfit.items[idx];
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: buildClothingImage(item.imagePath),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 84,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
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
                  onPressed: _autoPlanForSelectedDay,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text(
                    'Đổi bộ khác',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 13,
                    ),
                  ),
                  onPressed: () => store.togglePlanWorn(_selectedDate),
                  icon: Icon(
                    plan.isWorn
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    plan.isWorn ? 'Đã mặc' : 'Mặc hôm nay',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

