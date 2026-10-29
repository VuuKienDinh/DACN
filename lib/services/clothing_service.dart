
import 'package:flutter/foundation.dart';

import '../models/clothing_item.dart';
import 'clothing_api_service.dart';

class ClothingService {
  ClothingService._();

  static final ClothingService instance =
  ClothingService._();

  final ClothingApiService _api = ClothingApiService();

  final ValueNotifier<List<ClothingItem>> items =
  ValueNotifier<List<ClothingItem>>([]);

  // GET: Đồng bộ danh sách từ SQL Server
  Future<void> loadClothes() async {
    final clothes = await _api.getClothes();

    items.value = clothes;
  }

  // POST: Lưu quần áo vào SQL Server
  Future<void> addClothing(ClothingItem item) async {
    final savedItem = await _api.addClothing(item);

    // Dùng dữ liệu do Backend trả về
    items.value = [...items.value, savedItem];
  }

  // DELETE: Xóa trên SQL Server trước
  Future<void> deleteClothing(String id) async {
    await _api.deleteClothing(id);

    items.value = items.value
        .where((item) => item.id != id)
        .toList();
  }
}
