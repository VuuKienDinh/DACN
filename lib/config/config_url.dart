import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String? _activeBaseUrl;

  static String _readEnv(String key) {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env[key] ?? '').trim();
  }

  static String _normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  // URL Backend .NET / SQL Server ưu tiên hiện tại
  static String get baseUrl {
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      return _activeBaseUrl!;
    }
    return _normalize(_readEnv('BASE_URL'));
  }

  static void setActiveBaseUrl(String url) {
    final normalized = _normalize(url);
    if (normalized.isNotEmpty) {
      _activeBaseUrl = normalized;
    }
  }

  // Danh sách địa chỉ tự động dò (hỗ trợ cả Máy thật USB, Máy ảo Emulator và Wi-Fi LAN)
  static List<String> get candidateBaseUrls {
    final configured = _normalize(_readEnv('BASE_URL'));
    if (configured.isEmpty) return const [];

    final candidates = <String>[
      if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) _activeBaseUrl!,
      configured,
      'http://127.0.0.1:5080/api/',
      'http://10.0.2.2:5080/api/',
      'http://192.168.1.98:5080/api/',
    ];

    final seen = <String>{};
    return candidates.where((u) => seen.add(u)).toList();
  }

  static bool get hasBackendUrl => _readEnv('BASE_URL').isNotEmpty;

  // OpenWeatherMap API Key (tuỳ chọn; nếu trống sẽ dùng Open-Meteo / Mock)
  static String get weatherApiKey => _readEnv('WEATHER_API_KEY');

  static bool get hasWeatherApiKey => weatherApiKey.isNotEmpty;

  // Cấu hình Supabase (sẵn sàng mở rộng xác thực & lưu trữ đám mây)
  static String get supabaseUrl => _readEnv('SUPABASE_URL');

  static String get supabaseAnonKey => _readEnv('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
