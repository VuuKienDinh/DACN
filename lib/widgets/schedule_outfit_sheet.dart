import 'package:flutter/material.dart';

import '../models/outfit_suggestion.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';

String _formatScheduleDateLabel(DateTime d) {
  const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  final wd = weekdays[d.weekday % 7];
  return '$wd, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

Future<void> showScheduleOutfitSheet(
  BuildContext context, {
  required OutfitSuggestion outfit,
  DateTime? initialDate,
}) async {
  final savedDate = await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScheduleOutfitSheet(
      outfit: outfit,
      initialDate: initialDate ?? DateTime.now(),
    ),
  );

  if (savedDate != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lên lịch "${outfit.title}" cho ${_formatScheduleDateLabel(savedDate)}',
        ),
      ),
    );
  }
}

class _ScheduleOutfitSheet extends StatefulWidget {
  final OutfitSuggestion outfit;
  final DateTime initialDate;

  const _ScheduleOutfitSheet({
    required this.outfit,
    required this.initialDate,
  });

  @override
  State<_ScheduleOutfitSheet> createState() => _ScheduleOutfitSheetState();
}

class _ScheduleOutfitSheetState extends State<_ScheduleOutfitSheet> {
  late DateTime _selectedDate;
  late String _selectedOccasion;
  late final TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedOccasion = widget.outfit.occasion;
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
      });
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await DailyFitStore.instance.scheduleOutfit(
        date: _selectedDate,
        outfit: widget.outfit,
        occasion: _selectedOccasion,
        note: _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, _selectedDate);
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lên lịch mặc trang phục',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.outfit.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
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
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.iceSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
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
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
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
              const SizedBox(height: 16),
              const Text(
                'Hoàn cảnh',
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
                    onSelected: (_) {
                      setState(() {
                        _selectedOccasion = occ;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Ghi chú (VD: Thuyết trình đồ án, Họp nhóm...)',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
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
