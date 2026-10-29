import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/config_url.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? Config_URL.baseUrl;

  // GET
  Future<http.Response> get(String endpoint) {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  // POST
  Future<http.Response> post(
      String endpoint, {
        dynamic body,
      }) {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  // PUT
  Future<http.Response> put(
      String endpoint, {
        dynamic body,
      }) {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  // DELETE
  Future<http.Response> delete(String endpoint) {
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
    );
  }

  // Upload file ảnh lên Backend
  Future<http.Response> uploadFile(
      String endpoint,
      String filePath,
      String fileName,
      ) async {
    final extension =
    fileName.split('.').last.toLowerCase();

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
        throw Exception(
          'Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP',
        );
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

    final streamedResponse = await request.send();

    return http.Response.fromStream(streamedResponse);
  }

}
