import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String _readEnv(String key) {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env[key] ?? '').trim();
  }

  // URL Backend .NET / SQL Server
  static String get baseUrl {
    final url = _readEnv('BASE_URL');
    if (url.isEmpty) {
      return '';
    }
    return url.endsWith('/') ? url : '$url/';
  }

  static bool get hasBackendUrl => baseUrl.isNotEmpty;

  // OpenWeatherMap API Key (tuỳ chọn; nếu trống sẽ dùng Open-Meteo / Mock)
  static String get weatherApiKey => _readEnv('WEATHER_API_KEY');

  static bool get hasWeatherApiKey => weatherApiKey.isNotEmpty;

  // Cấu hình Supabase (sẵn sàng mở rộng xác thực & lưu trữ đám mây)
  static String get supabaseUrl => _readEnv('SUPABASE_URL');

  static String get supabaseAnonKey => _readEnv('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
