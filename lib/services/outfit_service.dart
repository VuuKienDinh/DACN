import '../data/mock_catalog.dart';
import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../models/user_preferences.dart';
import '../models/weather_info.dart';

class OutfitService {
  // Danh sách hoàn cảnh chính (bao gồm Đi học, Đi làm, Đi chơi và mở rộng)
  static const List<String> allOccasions = [
    'Đi học',
    'Đi làm',
    'Đi chơi',
    'Hẹn hò',
    'Thể thao',
    'Dự tiệc',
  ];

  // Phong cách phù hợp với từng hoàn cảnh
  static const Map<String, List<String>> occasionStyles = {
    'Đi học': [
      'Thường ngày',
      'Năng động',
      'Tối giản',
      'Hàn Quốc',
    ],
    'Đi làm': [
      'Công sở',
      'Thanh lịch',
      'Tối giản',
    ],
    'Đi chơi': [
      'Thường ngày',
      'Đường phố',
      'Năng động',
      'Vintage',
      'Hàn Quốc',
    ],
    'Dự tiệc': [
      'Dự tiệc',
      'Thanh lịch',
      'Nữ tính',
      'Cá tính',
    ],
    'Thể thao': [
      'Thể thao',
      'Năng động',
    ],
    'Hẹn hò': [
      'Thanh lịch',
      'Nữ tính',
      'Hàn Quốc',
      'Tối giản',
    ],
  };

  // Nhóm màu trung tính dễ phối
  static const Set<String> neutralColors = {
    'Trắng',
    'Đen',
    'Xám',
    'Be',
    'Kem',
    'Nâu',
  };

  static const Set<String> coolBreathableColors = {
    'Trắng',
    'Kem',
    'Be',
    'Xanh dương',
  };

  static double _styleScore(
    ClothingItem item,
    String occasion,
    UserPreferences? prefs,
  ) {
    final suitableStyles = occasionStyles[occasion] ?? const [];
    double score = suitableStyles.contains(item.style) ? 94 : 58;

    if (prefs != null && prefs.preferredStyles.contains(item.style)) {
      score += 6;
    }
    return score.clamp(0, 100);
  }

  static double _colorScore(
    List<ClothingItem> items,
    UserPreferences? prefs,
  ) {
    if (items.isEmpty) return 0;
    final colors = items.map((e) => e.color).toList();
    double base = 68;

    if (colors.toSet().length == 1) {
      base = 86;
    } else if (colors.any(neutralColors.contains)) {
      base = 92;
    }

    if (prefs != null &&
        colors.any((c) => prefs.favoriteColors.contains(c))) {
      base += 6;
    }
    return base.clamp(0, 100);
  }

  static double _weatherScore(
    List<ClothingItem> items,
    WeatherInfo? weather,
  ) {
    if (weather == null) return 88;
    final hasJacket = items.any((e) => e.type == 'Áo khoác');
    final hasLightColor =
        items.any((e) => coolBreathableColors.contains(e.color));

    if (weather.kind == WeatherKind.rainy) {
      return hasJacket ? 96 : 80;
    }
    if (weather.temperatureC >= 29) {
      if (!hasJacket && hasLightColor) return 97;
      if (hasJacket) return 74;
      return 88;
    }
    if (weather.temperatureC <= 22) {
      return hasJacket ? 98 : 76;
    }
    return hasLightColor ? 93 : 87;
  }

  static double _calculateScore(
    List<ClothingItem> items,
    String occasion,
    WeatherInfo? weather,
    UserPreferences? prefs,
  ) {
    if (items.isEmpty) return 0;

    final styleAvg = items
            .map((item) => _styleScore(item, occasion, prefs))
            .reduce((a, b) => a + b) /
        items.length;
    final color = _colorScore(items, prefs);
    final weatherCompatibility = _weatherScore(items, weather);

    return (styleAvg * 0.48 + color * 0.30 + weatherCompatibility * 0.22)
        .clamp(55, 99);
  }

  static String _buildTitle(List<ClothingItem> items, String occasion) {
    final dominantStyle =
        items.isNotEmpty ? items.first.style : 'Thanh lịch';
    switch (occasion) {
      case 'Đi học':
        return 'Năng động Giảng đường · $dominantStyle';
      case 'Đi làm':
        return 'Smart Casual Công sở · $dominantStyle';
      case 'Đi chơi':
        return 'Dạo phố Cuối tuần · $dominantStyle';
      case 'Hẹn hò':
        return 'Tinh tế Hẹn hò · $dominantStyle';
      case 'Thể thao':
        return 'Vận động Thoáng khí · $dominantStyle';
      case 'Dự tiệc':
        return 'Tâm điểm Sự kiện · $dominantStyle';
      default:
        return 'Bộ phối DailyFit · $dominantStyle';
    }
  }

  static String _buildWeatherTag(
    List<ClothingItem> items,
    WeatherInfo? weather,
  ) {
    if (weather == null) return 'Cân bằng màu sắc & phom dáng';
    final temp = weather.temperatureC.round();
    final hasJacket = items.any((e) => e.type == 'Áo khoác');

    if (weather.kind == WeatherKind.rainy) {
      return hasJacket
          ? 'Che chắn nhẹ · Hợp trời mưa $temp°C'
          : 'Gọn gàng · Thời tiết $temp°C';
    }
    if (weather.temperatureC >= 28 && !hasJacket) {
      return 'Thoáng mát · Rất hợp $temp°C';
    }
    if (weather.temperatureC <= 22 && hasJacket) {
      return 'Giữ ấm tinh tế · Hợp $temp°C';
    }
    return 'Hài hòa thời tiết $temp°C';
  }

  static String _buildReason(
    List<ClothingItem> items,
    String occasion,
    WeatherInfo? weather,
    UserPreferences? prefs,
  ) {
    final names = items.map((e) => e.name.toLowerCase()).join(', ');
    final colors = items.map((e) => e.color).toSet().join(' - ');
    final weatherClause = weather == null
        ? 'dễ ứng dụng cả ngày'
        : 'thích ứng tốt với tiết trời ${weather.condition.toLowerCase()} ${weather.temperatureC.round()}°C tại ${weather.city}';

    final favMatch = prefs != null &&
        items.any((e) => prefs.favoriteColors.contains(e.color));
    final personalClause = favMatch
        ? ' đồng thời tôn bật tông màu yêu thích trong hồ sơ của bạn.'
        : ' tạo tổng thể cân đối, lịch sự và có chiều sâu thị giác.';

    return 'Sự kết hợp giữa $names trên bảng màu ($colors) mang lại diện mạo chuẩn "$occasion", $weatherClause,$personalClause';
  }

  // Tạo gợi ý phối đồ thông minh
  static List<OutfitSuggestion> generateOutfits(
    List<ClothingItem> clothes,
    String occasion, {
    WeatherInfo? weather,
    UserPreferences? preferences,
    int variationSeed = 0,
    int limit = 4,
  }) {
    final tops = clothes.where((item) => item.type == 'Áo').toList();
    final bottoms = clothes
        .where((item) => item.type == 'Quần' || item.type == 'Váy')
        .toList();
    final onePieces = clothes
        .where((item) => item.type == 'Đầm' || item.type == 'Đồ bộ')
        .toList();
    final shoes = clothes
        .where((item) => item.type == 'Giày' || item.type == 'Dép')
        .toList();
    final jackets = clothes.where((item) => item.type == 'Áo khoác').toList();
    final accessories = clothes
        .where(
          (item) =>
              item.type == 'Túi xách' ||
              item.type == 'Nón / Mũ' ||
              item.type == 'Phụ kiện',
        )
        .toList();

    final List<List<ClothingItem>> combinations = [];

    // Kiểu 1: Áo + Quần/Váy + Giày/Dép (hoặc phối 2 món nếu tủ đồ chưa có giày)
    for (final top in tops) {
      for (final bottom in bottoms) {
        if (shoes.isEmpty) {
          combinations.add([top, bottom]);
        } else {
          for (final shoe in shoes) {
            combinations.add([top, bottom, shoe]);
          }
        }
      }
    }

    // Kiểu 2: Đầm/Đồ bộ + Giày/Dép
    for (final onePiece in onePieces) {
      if (shoes.isEmpty) {
        combinations.add([onePiece]);
      } else {
        for (final shoe in shoes) {
          combinations.add([onePiece, shoe]);
        }
      }
    }

    // Mở rộng layer Áo khoác & Phụ kiện
    final List<List<ClothingItem>> expanded = [];
    final shouldPreferLayer = weather != null
        ? (weather.temperatureC <= 25 ||
            weather.kind == WeatherKind.rainy ||
            occasion == 'Đi làm' ||
            occasion == 'Dự tiệc')
        : (occasion == 'Đi làm' || occasion == 'Dự tiệc');

    for (final base in combinations) {
      expanded.add(base);
      if (shouldPreferLayer || variationSeed.isOdd) {
        for (final jacket in jackets) {
          expanded.add([...base, jacket]);
        }
      }
      for (final acc in accessories) {
        expanded.add([...base, acc]);
      }
    }

    if (expanded.isEmpty) return const [];

    final heroUrl = MockCatalog.editorialPhotosByOccasion[occasion] ??
        MockCatalog.editorialPhotosByOccasion['Đi học'];

    final scored = expanded.map((items) {
      final baseScore = _calculateScore(items, occasion, weather, preferences);
      final idSig = items.map((e) => e.id).join('_');
      // Biến thiên nhẹ khi người dùng nhấn "Làm mới" để khám phá bộ đồ đa dạng
      final jitter = variationSeed == 0
          ? 0.0
          : (((idSig.hashCode ^ variationSeed).abs() % 7) - 3).toDouble();

      return OutfitSuggestion(
        id: 'outfit_${occasion.hashCode.abs()}_$idSig',
        title: _buildTitle(items, occasion),
        occasion: occasion,
        items: items,
        score: (baseScore + jitter).clamp(60, 99),
        reason: _buildReason(items, occasion, weather, preferences),
        weatherTag: _buildWeatherTag(items, weather),
        heroImageUrl: heroUrl,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Lọc trùng lặp cao (giữ các bộ khác biệt món chính để gợi ý phong phú)
    final List<OutfitSuggestion> distinct = [];
    final Set<String> usedPrimaryPairs = {};

    for (final candidate in scored) {
      final pairKey = candidate.items.take(2).map((e) => e.id).join('-');
      if (!usedPrimaryPairs.contains(pairKey) || distinct.length < 2) {
        distinct.add(candidate);
        usedPrimaryPairs.add(pairKey);
      }
      if (distinct.length >= limit) break;
    }

    if (distinct.length < limit) {
      for (final candidate in scored) {
        if (!distinct.any((d) => d.id == candidate.id)) {
          distinct.add(candidate);
        }
        if (distinct.length >= limit) break;
      }
    }

    return distinct;
  }
}
