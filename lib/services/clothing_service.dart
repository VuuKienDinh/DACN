import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';
import '../data/mock_catalog.dart';
import '../models/clothing_item.dart';
import 'clothing_api_service.dart';
import 'dailyfit_store.dart';

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
    var localItems = await _readLocalItems();

    if (ConfigUrl.hasBackendUrl) {
      try {
        var serverClothes = await _api.getClothes();

        // Tự động đồng bộ các món đồ đã thêm lúc Offline lên SQL Server
        if (localItems.isNotEmpty) {
          localItems = await _syncPendingLocalItems(localItems, serverClothes);
          serverClothes = await _api.getClothes();
        }

        syncStatus.value = BackendSyncStatus.connected;
        statusMessage.value =
            'Đã kết nối máy chủ (${serverClothes.length} món trên SQL Server)';

        items.value = [...serverClothes, ...localItems];
        await DailyFitStore.instance.reconcileWithWardrobe(
          items.value,
          isAuthoritativeWardrobe: true,
        );
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

  // Đẩy các trang phục lưu tạm trên điện thoại lên SQL Server ngay khi có kết nối
  Future<List<ClothingItem>> _syncPendingLocalItems(
    List<ClothingItem> pendingLocal,
    List<ClothingItem> existingServer,
  ) async {
    final remaining = <ClothingItem>[];

    for (final local in pendingLocal.reversed) {
      final alreadyOnServer = existingServer.any(
        (s) =>
            s.name.trim().toLowerCase() == local.name.trim().toLowerCase() &&
            s.type == local.type &&
            s.color == local.color &&
            s.style == local.style,
      );

      if (alreadyOnServer) {
        continue;
      }

      try {
        String? serverImagePath;
        final imgPath = local.imagePath.trim();
        if (imgPath.isNotEmpty) {
          if (imgPath.startsWith('http://') ||
              imgPath.startsWith('https://') ||
              imgPath.startsWith('/uploads/')) {
            serverImagePath = imgPath;
          } else {
            final imgFile = File(imgPath);
            if (imgFile.existsSync()) {
              final fileName = imgPath.split(RegExp(r'[/\\]')).last;
              serverImagePath = await _api.uploadImage(imgPath, fileName);
            }
          }
        }

        await _api.addClothing(
          ClothingItem(
            id: '',
            name: local.name,
            type: local.type,
            color: local.color,
            style: local.style,
            imagePath: serverImagePath ?? '',
          ),
        );
      } catch (_) {
        remaining.insert(0, local);
      }
    }

    await _writeLocalItems(remaining);
    return remaining;
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

  // Cập nhật đầy đủ thông tin & ảnh trang phục (giữ nguyên ID trên SQL Server)
  Future<AddClothingResult> updateClothing({
    required ClothingItem existing,
    required String name,
    required String type,
    required String color,
    required String style,
    String? newLocalImagePath,
    String? newFileName,
  }) async {
    final isServerItem =
        !existing.id.startsWith('local-') && !existing.id.startsWith('mock-');

    if (isServerItem && ConfigUrl.hasBackendUrl) {
      try {
        var resolvedImagePath = existing.imagePath;
        if (newLocalImagePath != null && newLocalImagePath.trim().isNotEmpty) {
          resolvedImagePath = await _api.uploadImage(
            newLocalImagePath,
            newFileName ?? newLocalImagePath.split(RegExp(r'[/\\]')).last,
          );
        }

        final updated = existing.copyWith(
          name: name,
          type: type,
          color: color,
          style: style,
          imagePath: resolvedImagePath,
          isLocalOnly: false,
        );

        await _api.updateClothing(updated);
        syncStatus.value = BackendSyncStatus.connected;

        items.value = items.value
            .map((item) => item.id == existing.id ? updated : item)
            .toList();
        await DailyFitStore.instance.syncUpdatedClothingItem(updated);

        return AddClothingResult(
          item: updated,
          syncedToServer: true,
        );
      } catch (_) {
        // Nếu mất kết nối tạm thời vẫn cập nhật mượt trên thiết bị
      }
    }

    final fallbackUpdated = existing.copyWith(
      name: name,
      type: type,
      color: color,
      style: style,
      imagePath: (newLocalImagePath != null && newLocalImagePath.isNotEmpty)
          ? newLocalImagePath
          : existing.imagePath,
      isLocalOnly: true,
    );

    if (existing.id.startsWith('local-')) {
      final localItems = await _readLocalItems();
      final nextLocal = localItems
          .map((item) => item.id == existing.id ? fallbackUpdated : item)
          .toList();
      await _writeLocalItems(nextLocal);
    } else if (existing.id.startsWith('mock-')) {
      await _markMockDeleted(existing.id);
      final localIdItem = fallbackUpdated.copyWith(
        id: 'local-${existing.id}',
      );
      final localItems = await _readLocalItems();
      final filtered =
          localItems.where((i) => i.id != localIdItem.id).toList();
      await _writeLocalItems([localIdItem, ...filtered]);
      items.value = items.value
          .map((item) => item.id == existing.id ? localIdItem : item)
          .toList();
      await DailyFitStore.instance.syncUpdatedClothingItem(localIdItem);
      return AddClothingResult(
        item: localIdItem,
        syncedToServer: false,
      );
    }

    items.value = items.value
        .map((item) => item.id == existing.id ? fallbackUpdated : item)
        .toList();
    await DailyFitStore.instance.syncUpdatedClothingItem(fallbackUpdated);

    return AddClothingResult(
      item: fallbackUpdated,
      syncedToServer: false,
    );
  }

  // Cập nhật tên, danh mục, màu sắc hoặc đa phong cách của trang phục
  Future<bool> updateClothingItem(ClothingItem updated) async {
    final res = await updateClothing(
      existing: updated,
      name: updated.name,
      type: updated.type,
      color: updated.color,
      style: updated.style,
    );
    return res.syncedToServer;
  }

  // Xóa quần áo trên SQL Server hoặc bộ nhớ cục bộ (đồng thời dọn lịch mặc / yêu thích liên quan)
  Future<void> deleteClothing(String id) async {
    if (id.startsWith('mock-')) {
      await _markMockDeleted(id);
      items.value = items.value.where((item) => item.id != id).toList();
      await DailyFitStore.instance.removeClothingItemFromSavedOutfits(id);
      return;
    }

    if (id.startsWith('local-')) {
      final localItems = await _readLocalItems();
      await _writeLocalItems(
        localItems.where((item) => item.id != id).toList(),
      );
      items.value = items.value.where((item) => item.id != id).toList();
      await DailyFitStore.instance.removeClothingItemFromSavedOutfits(id);
      return;
    }

    await _api.deleteClothing(id);
    items.value = items.value.where((item) => item.id != id).toList();
    await DailyFitStore.instance.removeClothingItemFromSavedOutfits(id);
  }
}
