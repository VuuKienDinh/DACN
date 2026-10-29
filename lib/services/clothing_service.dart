import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';
import '../data/mock_catalog.dart';
import '../models/clothing_item.dart';
import 'clothing_api_service.dart';

enum BackendSyncStatus {
  idle,
  syncing,
  connected,
  offlineFallback,
}

class AddClothingResult {
  final ClothingItem item;
  final bool syncedToServer;

  const AddClothingResult({
    required this.item,
    required this.syncedToServer,
  });
}

class ClothingService {
  ClothingService._();

  static final ClothingService instance = ClothingService._();

  static const String _localItemsKey = 'dailyfit_local_clothing_v1';
  static const String _deletedMockIdsKey = 'dailyfit_deleted_mock_ids_v1';

  final ClothingApiService _api = ClothingApiService();

  final ValueNotifier<List<ClothingItem>> items =
      ValueNotifier<List<ClothingItem>>([]);

  final ValueNotifier<BackendSyncStatus> syncStatus =
      ValueNotifier<BackendSyncStatus>(BackendSyncStatus.idle);

  final ValueNotifier<String> statusMessage = ValueNotifier<String>(
    'Chưa đồng bộ',
  );

  Future<void>? _inFlightLoad;

  bool get isOnlineConnected => syncStatus.value == BackendSyncStatus.connected;

  Future<List<ClothingItem>> _readLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localItemsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => ClothingItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ).copyWith(isLocalOnly: true),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocalItems(List<ClothingItem> localItems) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(localItems.map((e) => e.toLocalJson()).toList());
    await prefs.setString(_localItemsKey, encoded);
  }

  Future<Set<String>> _readDeletedMockIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_deletedMockIdsKey) ?? const [];
    return list.toSet();
  }

  Future<void> _markMockDeleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readDeletedMockIds();
    current.add(id);
    await prefs.setStringList(_deletedMockIdsKey, current.toList());
  }

  // Đồng bộ danh sách từ SQL Server; tự động chuyển sang Offline + Mock nếu mất kết nối
  Future<void> loadClothes() {
    if (_inFlightLoad != null) return _inFlightLoad!;
    final future = _performLoadClothes();
    _inFlightLoad = future.whenComplete(() {
      _inFlightLoad = null;
    });
    return _inFlightLoad!;
  }

  Future<void> _performLoadClothes() async {
    syncStatus.value = BackendSyncStatus.syncing;
    final localItems = await _readLocalItems();

    if (ConfigUrl.hasBackendUrl) {
      try {
        final serverClothes = await _api.getClothes();
        syncStatus.value = BackendSyncStatus.connected;
        statusMessage.value =
            'Đã kết nối máy chủ (${serverClothes.length} món trên SQL Server)';

        items.value = [...serverClothes, ...localItems];
        return;
      } catch (_) {
        // Máy chủ chưa bật hoặc không thể kết nối -> dùng dữ liệu cục bộ & mẫu thử
      }
    }

    final deletedMocks = await _readDeletedMockIds();
    final activeMocks = MockCatalog.defaultWardrobe
        .where((m) => !deletedMocks.contains(m.id))
        .toList();

    syncStatus.value = BackendSyncStatus.offlineFallback;
    statusMessage.value = ConfigUrl.hasBackendUrl
        ? 'Máy chủ tạm ngoại tuyến · Đang dùng dữ liệu trên máy & mẫu thử'
        : 'Chưa cấu hình BASE_URL · Đang dùng dữ liệu trên máy & mẫu thử';

    items.value = [...localItems, ...activeMocks];
  }

  // Nạp lại bộ trang phục mẫu chất lượng cao theo yêu cầu người dùng
  Future<void> restoreSampleWardrobe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deletedMockIdsKey);

    final currentIds = items.value.map((e) => e.id).toSet();
    final missingMocks = MockCatalog.defaultWardrobe
        .where((m) => !currentIds.contains(m.id))
        .toList();

    items.value = [...items.value, ...missingMocks];
  }

  // Giữ tương thích với hàm cũ
  Future<void> addClothing(ClothingItem item) async {
    if (ConfigUrl.hasBackendUrl) {
      try {
        final savedItem = await _api.addClothing(item);
        syncStatus.value = BackendSyncStatus.connected;
        items.value = [savedItem, ...items.value];
        return;
      } catch (_) {
        // Lưu cục bộ bên dưới
      }
    }

    final localItem = item.copyWith(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      isLocalOnly: true,
    );
    final localItems = await _readLocalItems();
    final updatedLocal = [localItem, ...localItems];
    await _writeLocalItems(updatedLocal);
    items.value = [localItem, ...items.value];
  }

  // Quy trình thêm trang phục kèm upload ảnh (tự động lưu trên thiết bị nếu Server offline)
  Future<AddClothingResult> addClothingWithImage({
    required String name,
    required String type,
    required String color,
    required String style,
    required String localImagePath,
    required String fileName,
  }) async {
    if (ConfigUrl.hasBackendUrl) {
      try {
        final serverImagePath = await _api.uploadImage(
          localImagePath,
          fileName,
        );
        final payload = ClothingItem(
          id: '',
          name: name,
          type: type,
          color: color,
          style: style,
          imagePath: serverImagePath,
        );
        final savedOnServer = await _api.addClothing(payload);
        syncStatus.value = BackendSyncStatus.connected;
        items.value = [savedOnServer, ...items.value];
        return AddClothingResult(
          item: savedOnServer,
          syncedToServer: true,
        );
      } catch (_) {
        // Máy chủ không phản hồi -> lưu ảnh và thông tin ngay trên điện thoại
      }
    }

    final localItem = ClothingItem(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      color: color,
      style: style,
      imagePath: localImagePath,
      isLocalOnly: true,
    );

    final localItems = await _readLocalItems();
    await _writeLocalItems([localItem, ...localItems]);
    items.value = [localItem, ...items.value];

    return AddClothingResult(
      item: localItem,
      syncedToServer: false,
    );
  }

  // Xóa quần áo trên SQL Server hoặc bộ nhớ cục bộ
  Future<void> deleteClothing(String id) async {
    if (id.startsWith('mock-')) {
      await _markMockDeleted(id);
      items.value = items.value.where((item) => item.id != id).toList();
      return;
    }

    if (id.startsWith('local-')) {
      final localItems = await _readLocalItems();
      await _writeLocalItems(
        localItems.where((item) => item.id != id).toList(),
      );
      items.value = items.value.where((item) => item.id != id).toList();
      return;
    }

    await _api.deleteClothing(id);
    items.value = items.value.where((item) => item.id != id).toList();
  }
}
