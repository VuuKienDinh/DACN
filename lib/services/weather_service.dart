import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/config_url.dart';
import '../models/user_preferences.dart';
import '../models/weather_info.dart';

class WeatherService {
  static const Duration _timeout = Duration(seconds: 6);

  Future<WeatherInfo> fetchWeatherForCity(String cityName) async {
    final city = UserPreferences.findCity(cityName);

    // 1. Ưu tiên OpenWeatherMap nếu người dùng đã cấu hình WEATHER_API_KEY trong .env
    if (ConfigUrl.hasWeatherApiKey) {
      try {
        final uri = Uri.https(
          'api.openweathermap.org',
          '/data/2.5/weather',
          {
            'lat': city.latitude.toString(),
            'lon': city.longitude.toString(),
            'units': 'metric',
            'lang': 'vi',
            'appid': ConfigUrl.weatherApiKey,
          },
        );
        final res = await http.get(uri).timeout(_timeout);
        if (res.statusCode == 200) {
          final data =
              jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final main = data['main'] as Map<String, dynamic>? ?? {};
          final wind = data['wind'] as Map<String, dynamic>? ?? {};
          final weatherList = data['weather'] as List<dynamic>? ?? [];
          final firstWeather = weatherList.isNotEmpty
              ? Map<String, dynamic>.from(weatherList.first as Map)
              : <String, dynamic>{};

          final temp = (main['temp'] as num?)?.toDouble() ?? city.defaultTempC;
          final feelsLike = (main['feels_like'] as num?)?.toDouble() ?? temp;
          final humidity =
              (main['humidity'] as num?)?.toInt() ?? city.defaultHumidity;
          final windSpeed = ((wind['speed'] as num?)?.toDouble() ?? 2.5) * 3.6;
          final rawDesc =
              firstWeather['description']?.toString() ?? city.defaultCondition;
          final mainCode =
              (firstWeather['main']?.toString() ?? '').toLowerCase();

          return WeatherInfo(
            city: city.name,
            temperatureC: temp,
            feelsLikeC: feelsLike,
            humidity: humidity,
            windSpeedKmh: windSpeed,
            condition: _capitalize(rawDesc),
            kind: _mapOpenWeatherKind(mainCode, temp),
            source: WeatherSource.openWeatherMap,
            updatedAt: DateTime.now(),
          );
        }
      } catch (_) {
        // Chuyển tiếp sang Open-Meteo hoặc Mock Fallback an toàn
      }
    }

    // 2. Truy vấn Open-Meteo (miễn phí, không lộ API key phía client)
    try {
      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': city.latitude.toString(),
          'longitude': city.longitude.toString(),
          'current':
              'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
          'timezone': 'Asia/Ho_Chi_Minh',
        },
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final temp =
            (current['temperature_2m'] as num?)?.toDouble() ?? city.defaultTempC;
        final feelsLike =
            (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
        final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ??
            city.defaultHumidity;
        final windSpeed =
            (current['wind_speed_10m'] as num?)?.toDouble() ?? 9.5;
        final wmoCode = (current['weather_code'] as num?)?.toInt() ?? 1;
        final mapped = _mapWmoCode(wmoCode, temp);

        return WeatherInfo(
          city: city.name,
          temperatureC: temp,
          feelsLikeC: feelsLike,
          humidity: humidity,
          windSpeedKmh: windSpeed,
          condition: mapped.$1,
          kind: mapped.$2,
          source: WeatherSource.openMeteoLive,
          updatedAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Ngoại tuyến hoặc lỗi mạng -> trả về dữ liệu mẫu trung thực
    }

    // 3. Dữ liệu mẫu (Mock Fallback) khi thiết bị không có kết nối mạng
    return buildMockWeather(city.name);
  }

  WeatherInfo buildMockWeather(String cityName) {
    final city = UserPreferences.findCity(cityName);
    final kind = city.defaultTempC <= 21
        ? WeatherKind.cool
        : WeatherKind.partlyCloudy;

    return WeatherInfo(
      city: city.name,
      temperatureC: city.defaultTempC,
      feelsLikeC: city.defaultTempC + 1,
      humidity: city.defaultHumidity,
      windSpeedKmh: 10.5,
      condition: city.defaultCondition,
      kind: kind,
      source: WeatherSource.mockFallback,
      updatedAt: DateTime.now(),
    );
  }

  WeatherKind _mapOpenWeatherKind(String mainCode, double temp) {
    if (mainCode.contains('rain') ||
        mainCode.contains('drizzle') ||
        mainCode.contains('thunder')) {
      return WeatherKind.rainy;
    }
    if (temp <= 21) return WeatherKind.cool;
    if (mainCode.contains('clear')) return WeatherKind.sunny;
    if (mainCode.contains('cloud')) return WeatherKind.partlyCloudy;
    return WeatherKind.partlyCloudy;
  }

  (String, WeatherKind) _mapWmoCode(int code, double temp) {
    if (code == 0) {
      return (
        temp <= 21 ? 'Trời quang, se lạnh' : 'Trời nắng quang đãng',
        temp <= 21 ? WeatherKind.cool : WeatherKind.sunny,
      );
    }
    if (code == 1 || code == 2) {
      return (
        temp <= 21 ? 'Mát lạnh, ít mây' : 'Nắng dịu, mây rải rác',
        temp <= 21 ? WeatherKind.cool : WeatherKind.partlyCloudy,
      );
    }
    if (code == 3 || code == 45 || code == 48) {
      return ('Nhiều mây, dịu mát', WeatherKind.cloudy);
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 99)) {
      return ('Có mưa rào nhẹ', WeatherKind.rainy);
    }
    return ('Thời tiết dễ chịu', WeatherKind.partlyCloudy);
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

