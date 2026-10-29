import 'outfit_suggestion.dart';

class PlannedOutfit {
  final String dateKey; // Định dạng YYYY-MM-DD
  final String occasion;
  final String note;
  final OutfitSuggestion outfit;
  final bool isWorn;

  const PlannedOutfit({
    required this.dateKey,
    required this.occasion,
    required this.outfit,
    this.note = '',
    this.isWorn = false,
  });

  PlannedOutfit copyWith({
    String? dateKey,
    String? occasion,
    String? note,
    OutfitSuggestion? outfit,
    bool? isWorn,
  }) {
    return PlannedOutfit(
      dateKey: dateKey ?? this.dateKey,
      occasion: occasion ?? this.occasion,
      note: note ?? this.note,
      outfit: outfit ?? this.outfit,
      isWorn: isWorn ?? this.isWorn,
    );
  }

  factory PlannedOutfit.fromJson(Map<String, dynamic> json) {
    return PlannedOutfit(
      dateKey: json['dateKey']?.toString() ?? '',
      occasion: json['occasion']?.toString() ?? 'Đi làm',
      note: json['note']?.toString() ?? '',
      isWorn: json['isWorn'] == true,
      outfit: OutfitSuggestion.fromJson(
        Map<String, dynamic>.from(json['outfit'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'occasion': occasion,
      'note': note,
      'isWorn': isWorn,
      'outfit': outfit.toJson(),
    };
  }

  static String formatKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

