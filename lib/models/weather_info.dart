enum WeatherKind {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  cool,
}

enum WeatherSource {
  openWeatherMap,
  openMeteoLive,
  mockFallback,
}

class WeatherInfo {
  final String city;
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double windSpeedKmh;
  final String condition;
  final WeatherKind kind;
  final WeatherSource source;
  final DateTime updatedAt;

  const WeatherInfo({
    required this.city,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeedKmh,
    required this.condition,
    required this.kind,
    required this.source,
    required this.updatedAt,
  });

  String formatTemperature({bool useCelsius = true}) {
    if (useCelsius) {
      return '${temperatureC.round()}°C';
    }
    final f = (temperatureC * 9 / 5) + 32;
    return '${f.round()}°F';
  }

  String formatFeelsLike({bool useCelsius = true}) {
    if (useCelsius) {
      return '${feelsLikeC.round()}°C';
    }
    final f = (feelsLikeC * 9 / 5) + 32;
    return '${f.round()}°F';
  }

  String get sourceLabel {
    switch (source) {
      case WeatherSource.openWeatherMap:
        return 'OpenWeather Live';
      case WeatherSource.openMeteoLive:
        return 'Thời tiết trực tiếp';
      case WeatherSource.mockFallback:
        return 'Dữ liệu mẫu (Offline)';
    }
  }

  bool get isLive => source != WeatherSource.mockFallback;

  String get stylingAdvice {
    if (kind == WeatherKind.rainy) {
      return 'Trời có mưa và độ ẩm cao ($humidity%) — ưu tiên áo khoác trượt nước nhẹ, quần tối màu gọn gàng và giày da/sneaker đế cao dễ vệ sinh.';
    }
    if (temperatureC >= 31) {
      return 'Trời nắng nóng ${temperatureC.round()}°C — hãy chọn sơ mi linen, áo thun cotton mỏng nhẹ tông trắng hoặc xanh pastel thoáng mát.';
    }
    if (temperatureC >= 26) {
      return 'Thời tiết ấm áp dễ chịu — rất hợp phối sơ mi Oxford hoặc polo sáng màu cùng quần chinos/kaki và sneaker trắng tối giản.';
    }
    if (temperatureC >= 21) {
      return 'Tiết trời mát mẻ lý tưởng — bạn có thể phối layer nhẹ với cardigan mỏng hoặc blazer thanh lịch để tạo điểm nhấn.';
    }
    return 'Trời se lạnh ${temperatureC.round()}°C — nên kết hợp áo khoác dày dặn, blazer hoặc trench coat giữ ấm mà vẫn tinh tế.';
  }
}

