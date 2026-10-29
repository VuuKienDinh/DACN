import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/config_url.dart';

class ApiClient {
  final String baseUrl;
  final Duration timeout;

  ApiClient({
    String? baseUrl,
    this.timeout = const Duration(seconds: 8),
  }) : baseUrl = baseUrl ?? ConfigUrl.baseUrl;

  void _ensureConfigured() {
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL chưa được cấu hình trong file .env');
    }
  }

  // GET
  Future<http.Response> get(String endpoint) {
    _ensureConfigured();
    return http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: const {
            'Content-Type': 'application/json',
          },
        )
        .timeout(timeout);
  }

  // POST
  Future<http.Response> post(
    String endpoint, {
    dynamic body,
  }) {
    _ensureConfigured();
    return http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  // PUT
  Future<http.Response> put(
    String endpoint, {
    dynamic body,
  }) {
    _ensureConfigured();
    return http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  // DELETE
  Future<http.Response> delete(String endpoint) {
    _ensureConfigured();
    return http.delete(Uri.parse('$baseUrl$endpoint')).timeout(timeout);
  }

  // Upload file ảnh lên Backend
  Future<http.Response> uploadFile(
    String endpoint,
    String filePath,
    String fileName,
  ) async {
    _ensureConfigured();

    final extension = fileName.split('.').last.toLowerCase();
    late final MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'webp':
        contentType = MediaType('image', 'webp');
        break;
      default:
        throw Exception('Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
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
        await request.send().timeout(const Duration(seconds: 15));

    return http.Response.fromStream(streamedResponse);
  }
}
