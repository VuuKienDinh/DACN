
import 'clothing_item.dart';

class OutfitSuggestion {
  final List<ClothingItem> items;
  final double score;
  final String reason;

  const OutfitSuggestion({
    required this.items,
    required this.score,
    required this.reason,
  });
}
