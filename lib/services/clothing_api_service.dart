
import 'dart:convert';

import '../models/clothing_item.dart';
import 'api_client.dart';

class ClothingApiService {
  final ApiClient _apiClient = ApiClient();

  // GET: Lấy danh sách quần áo
  Future<List<ClothingItem>> getClothes() async {
    final response = await _apiClient.get('Clothing');

    if (response.statusCode == 200) {
      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      return data.map((item) {
        return ClothingItem.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    }

    throw Exception(
      'Lỗi lấy quần áo: ${response.statusCode}',
    );
  }

  static String _fitStyleLimit(String rawStyle, int maxLen) {
    if (rawStyle.length <= maxLen) return rawStyle;
    final parts = rawStyle.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final kept = <String>[];
    for (final p in parts) {
      final candidate = kept.isEmpty ? p : '${kept.join(', ')}, $p';
      if (candidate.length <= maxLen) {
        kept.add(p);
      } else {
        break;
      }
    }
    return kept.isNotEmpty ? kept.join(', ') : rawStyle.substring(0, maxLen);
  }

  // POST: Thêm quần áo
  Future<ClothingItem> addClothing(
      ClothingItem item,
      ) async {
    var response = await _apiClient.post(
      'Clothing',
      body: item.toJson(),
    );

    if (response.statusCode == 400 && item.style.length > 50) {
      final compact = item.copyWith(style: _fitStyleLimit(item.style, 50));
      response = await _apiClient.post(
        'Clothing',
        body: compact.toJson(),
      );
    }

    if (response.statusCode == 201) {
      return ClothingItem.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        ),
      );
    }

    throw Exception(
      'Lỗi thêm quần áo: ${response.statusCode}',
    );
  }

  // PUT: Cập nhật thông tin / phong cách quần áo
  Future<void> updateClothing(ClothingItem item) async {
    final serverId = int.parse(item.id);
    var response = await _apiClient.put(
      'Clothing/$serverId',
      body: item.toJson(),
    );

    if (response.statusCode == 400 && item.style.length > 50) {
      final compact = item.copyWith(style: _fitStyleLimit(item.style, 50));
      response = await _apiClient.put(
        'Clothing/$serverId',
        body: compact.toJson(),
      );
    }

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Lỗi cập nhật quần áo: ${response.statusCode}');
    }
  }

  // DELETE: Xóa quần áo
  Future<void> deleteClothing(String id) async {
    final serverId = int.parse(id);

    final response = await _apiClient.delete(
      'Clothing/$serverId',
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Lỗi xóa quần áo: ${response.statusCode}',
      );
    }
  }

  // Upload ảnh và nhận đường dẫn từ Backend
  Future<String> uploadImage(
      String localImagePath,
      String fileName,
      ) async {
    final response = await _apiClient.uploadFile(
      'Clothing/upload-image',
      localImagePath,
      fileName,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>;

      final imagePath = data['imagePath'];

      if (imagePath is String &&
          imagePath.isNotEmpty) {
        return imagePath;
      }

      throw Exception(
        'Backend không trả về đường dẫn ảnh',
      );
    }

    throw Exception(
      'Không thể upload ảnh: '
          '${response.statusCode} - ${response.body}',
    );
  }

}
