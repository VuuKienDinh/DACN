import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/config_url.dart';

class ApiClient {
  final String? _explicitBaseUrl;
  final Duration timeout;

  ApiClient({
    String? baseUrl,
    this.timeout = const Duration(seconds: 6),
  }) : _explicitBaseUrl = baseUrl;

  List<String> _resolveTargets() {
    if (_explicitBaseUrl != null && _explicitBaseUrl.trim().isNotEmpty) {
      final t = _explicitBaseUrl.trim();
      return [t.endsWith('/') ? t : '$t/'];
    }
    final candidates = ConfigUrl.candidateBaseUrls;
    if (candidates.isEmpty) {
      throw Exception('BASE_URL chưa được cấu hình trong file .env');
    }
    return candidates;
  }

  Future<http.Response> _sendWithAutoFallback(
    Future<http.Response> Function(String targetBaseUrl, Duration stepTimeout)
        action,
  ) async {
    final targets = _resolveTargets();
    Object? lastError;

    for (var i = 0; i < targets.length; i++) {
      final candidate = targets[i];
      // Thử nhanh các cổng dự phòng để chuyển đổi mượt giữa Máy thật USB / Máy ảo / Wi-Fi
      final stepTimeout = i == 0 ? timeout : const Duration(milliseconds: 2200);
      try {
        final response = await action(candidate, stepTimeout);
        // Tránh nhận nhầm phản hồi 307 Redirect nếu cổng HTTP bị chuyển hướng SSL
        if (response.statusCode == 307 || response.statusCode == 308) {
          lastError = Exception('Máy chủ chuyển hướng HTTPS (${response.statusCode})');
          continue;
        }
        ConfigUrl.setActiveBaseUrl(candidate);
        return response;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Không thể kết nối tới Backend API');
  }

  // GET
  Future<http.Response> get(String endpoint) {
    return _sendWithAutoFallback(
      (base, stepTimeout) => http
          .get(
            Uri.parse('$base$endpoint'),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(stepTimeout),
    );
  }

  // POST
  Future<http.Response> post(
    String endpoint, {
    dynamic body,
  }) {
    final encoded = jsonEncode(body);
    return _sendWithAutoFallback(
      (base, stepTimeout) => http
          .post(
            Uri.parse('$base$endpoint'),
            headers: const {'Content-Type': 'application/json'},
            body: encoded,
          )
          .timeout(stepTimeout),
    );
  }

  // PUT
  Future<http.Response> put(
    String endpoint, {
    dynamic body,
  }) {
    final encoded = jsonEncode(body);
    return _sendWithAutoFallback(
      (base, stepTimeout) => http
          .put(
            Uri.parse('$base$endpoint'),
            headers: const {'Content-Type': 'application/json'},
            body: encoded,
          )
          .timeout(stepTimeout),
    );
  }

  // DELETE
  Future<http.Response> delete(String endpoint) {
    return _sendWithAutoFallback(
      (base, stepTimeout) =>
          http.delete(Uri.parse('$base$endpoint')).timeout(stepTimeout),
    );
  }

  // Upload file ảnh lên Backend
  Future<http.Response> uploadFile(
    String endpoint,
    String filePath,
    String fileName,
  ) async {
    final extension = fileName.split('.').last.toLowerCase();
    late final MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'jfif':
        contentType = MediaType('image', 'jpeg');
        break;
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'webp':
        contentType = MediaType('image', 'webp');
        break;
      case 'heic':
        contentType = MediaType('image', 'heic');
        break;
      case 'heif':
        contentType = MediaType('image', 'heif');
        break;
      default:
        throw Exception('Chỉ hỗ trợ ảnh JPG, PNG, WEBP hoặc HEIC');
    }

    return _sendWithAutoFallback((base, _) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base$endpoint'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
          contentType: contentType,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 12));

      return http.Response.fromStream(streamedResponse);
    });
  }
}
