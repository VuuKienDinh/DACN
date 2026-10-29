
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config_URL {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception(
        'BASE_URL chưa được cấu hình trong file .env',
      );
    }

    return url.endsWith('/') ? url : '$url/';
  }
}
