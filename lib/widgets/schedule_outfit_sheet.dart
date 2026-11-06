import 'package:flutter/material.dart';

import '../models/outfit_suggestion.dart';
import '../models/planned_outfit.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import 'clothing_card.dart';

String _formatScheduleDateLabel(DateTime d) {
  const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  final wd = weekdays[d.weekday % 7];
  return '$wd, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ScheduledResult {
  final DateTime date;
  final OutfitSuggestion outfit;

  const _ScheduledResult({
    required this.date,
    required this.outfit,
  });
}

Future<void> showScheduleOutfitSheet(
  BuildContext context, {
  OutfitSuggestion? outfit,
  DateTime? initialDate,
  String? initialOccasion,
  String? excludeOutfitId,
}) async {
  final result = await showModalBottomSheet<_ScheduledResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScheduleOutfitSheet(
      initialOutfit: outfit,
      initialDate: initialDate ?? DateTime.now(),
      initialOccasion: initialOccasion,
      excludeOutfitId: excludeOutfitId,
    ),
  );

  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lên lịch "${result.outfit.title}" cho ${_formatScheduleDateLabel(result.date)}',
        ),
      ),
    );
  }
}

class _ScheduleOutfitSheet extends StatefulWidget {
  final OutfitSuggestion? initialOutfit;
  final DateTime initialDate;
  final String? initialOccasion;
  final String? excludeOutfitId;

  const _ScheduleOutfitSheet({
    required this.initialOutfit,
    required this.initialDate,
    this.initialOccasion,
    this.excludeOutfitId,
  });

  @override
  State<_ScheduleOutfitSheet> createState() => _ScheduleOutfitSheetState();
}

class _ScheduleOutfitSheetState extends State<_ScheduleOutfitSheet> {
  late DateTime _selectedDate;
  late String _selectedOccasion;
  late final TextEditingController _noteController;

  List<OutfitSuggestion> _candidates = const [];
  int _variationIndex = 0;
  bool _userChangedOccasionOrDate = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedOccasion = widget.initialOccasion ??
        widget.initialOutfit?.occasion ??
        _defaultOccasionForDate(_selectedDate);

    final existingPlan = DailyFitStore.instance.getPlanForDate(_selectedDate);
    _noteController = TextEditingController(text: existingPlan?.note ?? '');

    _rebuildCandidates();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _defaultOccasionForDate(DateTime date) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    return isWeekend ? 'Đi chơi' : 'Đi làm';
  }

  void _rebuildCandidates() {
    final store = DailyFitStore.instance;
    final clothes = ClothingService.instance.items.value;
    final generated = OutfitService.generateOutfits(
      clothes,
      _selectedOccasion,
      weather: store.weather.value,
      preferences: store.preferences.value,
      variationSeed: _selectedDate.day + _selectedDate.month * 31,
      limit: 8,
    );

    // Tránh trùng lặp bộ đồ với ngày liền trước / liền sau khi có nhiều phương án phù hợp
    final neighborIds = <String>{
      if (widget.excludeOutfitId != null) widget.excludeOutfitId!,
    };
    final prevPlan = store.plannedOutfits
        .value[PlannedOutfit.formatKey(_selectedDate.subtract(const Duration(days: 1)))];
    final nextPlan = store.plannedOutfits
        .value[PlannedOutfit.formatKey(_selectedDate.add(const Duration(days: 1)))];
    if (prevPlan != null) neighborIds.add(prevPlan.outfit.id);
    if (nextPlan != null) neighborIds.add(nextPlan.outfit.id);

    final fresh = generated.where((o) => !neighborIds.contains(o.id)).toList();
    final repeated =
        generated.where((o) => neighborIds.contains(o.id)).toList();
    final ordered = <OutfitSuggestion>[...fresh, ...repeated];

    // Nếu người dùng bấm "Lên lịch mặc" từ 1 thẻ gợi ý cụ thể và chưa đổi hoàn cảnh -> giữ đúng bộ đó đầu tiên
    final pinned = widget.initialOutfit;
    if (!_userChangedOccasionOrDate &&
        widget.excludeOutfitId == null &&
        pinned != null &&
        pinned.occasion == _selectedOccasion) {
      ordered.removeWhere((o) => o.id == pinned.id);
      ordered.insert(0, pinned);
    }

    _candidates = ordered;
    if (_variationIndex >= _candidates.length) {
      _variationIndex = 0;
    }
  }

  OutfitSuggestion? get _activeOutfit {
    if (_candidates.isEmpty) return null;
    return _candidates[_variationIndex % _candidates.length];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        if (widget.initialOutfit == null) {
          _userChangedOccasionOrDate = true;
        }
        _variationIndex = 0;
        _rebuildCandidates();
      });
    }
  }

  void _onSelectOccasion(String occ) {
    if (occ == _selectedOccasion) return;
    setState(() {
      _selectedOccasion = occ;
      _userChangedOccasionOrDate = true;
      _variationIndex = 0;
      _rebuildCandidates();
    });
  }

  Future<void> _submit() async {
    final chosen = _activeOutfit;
    if (_isSaving || chosen == null) return;

    setState(() => _isSaving = true);
    try {
      await DailyFitStore.instance.scheduleOutfit(
        date: _selectedDate,
        outfit: chosen,
        occasion: _selectedOccasion,
        note: _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(
          context,
          _ScheduledResult(date: _selectedDate, outfit: chosen),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentOutfit = _activeOutfit;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.24),
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 22 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lên lịch mặc trang phục',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (_candidates.length > 1)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _variationIndex =
                              (_variationIndex + 1) % _candidates.length;
                        });
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.shuffle_rounded, size: 16),
                      label: Text(
                        'Đổi bộ (${(_variationIndex % _candidates.length) + 1}/${_candidates.length})',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Hộp xem trước trực tiếp bộ đồ sẽ được lưu cho hoàn cảnh đang chọn
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.iceSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: currentOutfit != null
                        ? AppColors.primary.withValues(alpha: 0.24)
                        : AppColors.warning.withValues(alpha: 0.45),
                  ),
                ),
                child: currentOutfit == null
                    ? Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.warningText,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tủ đồ hiện chưa có trang phục phù hợp cho hoàn cảnh "$_selectedOccasion". Hãy chọn hoàn cảnh khác hoặc thêm đồ mới.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningText,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentOutfit.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 54,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: currentOutfit.items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final item = currentOutfit.items[idx];
                                return Container(
                                  padding: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.subtleBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                          left: Radius.circular(11),
                                        ),
                                        child: SizedBox(
                                          width: 50,
                                          height: 52,
                                          child: buildClothingImage(
                                            item.imagePath,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 110,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.text,
                                              ),
                                            ),
                                            Text(
                                              item.type,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 14),
              Text(
                'Chọn ngày dự kiến',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.iceSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatScheduleDateLabel(_selectedDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đổi ngày',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hoàn cảnh (tự động phối lại đồ theo hoàn cảnh)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OutfitService.allOccasions.map((occ) {
                  final active = occ == _selectedOccasion;
                  return ChoiceChip(
                    label: Text(occ),
                    selected: active,
                    onSelected: (_) => _onSelectOccasion(occ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                style: TextStyle(color: AppColors.text),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Ghi chú (VD: Thuyết trình đồ án, Đá giao hữu...)',
                  filled: true,
                  fillColor: AppColors.iceSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isSaving || currentOutfit == null) ? null : _submit,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Xác nhận lưu lịch mặc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
