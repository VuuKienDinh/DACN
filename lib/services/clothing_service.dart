
import 'package:flutter/foundation.dart';
import '../models/clothing_item.dart';

class ClothingService {
  ClothingService._();

  static final ClothingService instance = ClothingService._();

  final ValueNotifier<List<ClothingItem>> items =
  ValueNotifier<List<ClothingItem>>([]);

  void addClothing(ClothingItem item) {
    items.value = [...items.value, item];
  }

  void deleteClothing(String id) {
    items.value = items.value
        .where((item) => item.id != id)
        .toList();
  }
}
