import 'clothing_item.dart';

class OutfitSuggestion {
  final String id;
  final String title;
  final String occasion;
  final List<ClothingItem> items;
  final double score;
  final String reason;
  final String weatherTag;
  final String? heroImageUrl;

  const OutfitSuggestion({
    required this.id,
    required this.title,
    required this.occasion,
    required this.items,
    required this.score,
    required this.reason,
    this.weatherTag = 'Phù hợp thời tiết hôm nay',
    this.heroImageUrl,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? [])
        .map((e) => ClothingItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return OutfitSuggestion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Bộ phối DailyFit',
      occasion: json['occasion']?.toString() ?? 'Đi học',
      items: rawItems,
      score: (json['score'] as num?)?.toDouble() ?? 88,
      reason: json['reason']?.toString() ?? '',
      weatherTag:
          json['weatherTag']?.toString() ?? 'Phù hợp thời tiết hôm nay',
      heroImageUrl: json['heroImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'occasion': occasion,
      'items': items.map((e) => e.toLocalJson()).toList(),
      'score': score,
      'reason': reason,
      'weatherTag': weatherTag,
      'heroImageUrl': heroImageUrl,
    };
  }
}
