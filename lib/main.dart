
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/api_client.dart';
import 'config/config_url.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đọc file .env
  await dotenv.load(fileName: '.env');

  // Chạy giao diện DailyFit bình thường
  runApp(const DailyFitApp());

  // Kiểm tra kết nối API khi chạy Debug
  if (kDebugMode) {
    unawaited(testClothingApi());
  }
}

// Hàm kiểm tra kết nối Backend
Future<void> testClothingApi() async {
  try {
    debugPrint('===== KIỂM TRA API DAILYFIT =====');

    final url = '${Config_URL.baseUrl}Clothing';
    debugPrint('URL API: $url');

    final apiClient = ApiClient();

    final response = await apiClient
        .get('Clothing')
        .timeout(const Duration(seconds: 20));

    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is List) {
        debugPrint('KẾT NỐI API THÀNH CÔNG!');
        debugPrint('Số lượng quần áo: ${data.length}');
        debugPrint('Dữ liệu: $data');
      } else {
        debugPrint(
          'API trả về JSON nhưng không phải danh sách.',
        );
      }
    } else {
      debugPrint('API trả về lỗi.');
      debugPrint('Response: ${response.body}');
    }
  } catch (e) {
    debugPrint('LỖI KẾT NỐI: $e');
  }
}

class DailyFitApp extends StatelessWidget {
  const DailyFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
