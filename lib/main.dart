import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/config_url.dart';
import 'screens/main_shell_screen.dart';
import 'services/api_client.dart';
import 'services/dailyfit_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình thanh trạng thái Android trong suốt hiện đại
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Đọc file .env an toàn (không làm văng ứng dụng nếu thiếu .env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Lưu ý: Chưa tìm thấy file .env ($e) — dùng cấu hình mặc định.');
  }

  // Khởi chạy ứng dụng ngay, đồng thời đồng bộ dữ liệu nền mượt mà
  unawaited(DailyFitStore.instance.initialize());

  runApp(const DailyFitApp());

  if (kDebugMode && ConfigUrl.hasBackendUrl) {
    unawaited(testClothingApi());
  }
}

// Hàm kiểm tra nhanh kết nối Backend khi chạy Debug
Future<void> testClothingApi() async {
  try {
    debugPrint('===== KIỂM TRA API DAILYFIT =====');
    debugPrint('URL API: ${ConfigUrl.baseUrl}Clothing');

    final response = await ApiClient().get('Clothing');
    debugPrint('Status Code: ${response.statusCode}');
  } catch (e) {
    debugPrint('Backend hiện ngoại tuyến (Chuyển sang Offline Fallback): $e');
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
      home: const MainShellScreen(),
    );
  }
}
