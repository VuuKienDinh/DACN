import '../data/mock_catalog.dart';
import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../models/user_preferences.dart';
import '../models/weather_info.dart';

class OutfitService {
  // Danh sách hoàn cảnh xuất hiện
  static const List<String> allOccasions = [
    'Đi học',
    'Đi làm',
    'Đi chơi',
    'Hẹn hò',
    'Thể thao',
    'Dự tiệc',
  ];

  // Danh mục 20 phong cách thời trang đa dạng, sát thực tế
  static const List<String> allStyles = [
    'Thường ngày',
    'Thanh lịch',
    'Công sở',
    'Smart Casual',
    'Tối giản',
    'Hàn Quốc',
    'Năng động',
    'Đường phố',
    'Thể thao',
    'Preppy',
    'Old Money',
    'Vintage',
    'Retro',
    'Oversize',
    'Y2K',
    'Bụi bặm',
    'Nữ tính',
    'Cá tính',
    'Dự tiệc',
    'Du lịch',
  ];

  // Phong cách phù hợp với từng hoàn cảnh
  static const Map<String, Set<String>> occasionStyles = {
    'Đi học': {
      'Thường ngày',
      'Smart Casual',
      'Thanh lịch',
      'Tối giản',
      'Hàn Quốc',
      'Preppy',
      'Năng động',
      'Oversize',
      'Vintage',
      'Retro',
      'Nữ tính',
    },
    'Đi làm': {
      'Công sở',
      'Thanh lịch',
      'Smart Casual',
      'Tối giản',
      'Old Money',
      'Hàn Quốc',
      'Nữ tính',
    },
    'Đi chơi': {
      'Thường ngày',
      'Đường phố',
      'Năng động',
      'Smart Casual',
      'Thanh lịch',
      'Tối giản',
      'Hàn Quốc',
      'Vintage',
      'Retro',
      'Oversize',
      'Y2K',
      'Bụi bặm',
      'Cá tính',
      'Nữ tính',
      'Du lịch',
      'Preppy',
    },
    'Hẹn hò': {
      'Thanh lịch',
      'Smart Casual',
      'Hàn Quốc',
      'Tối giản',
      'Old Money',
      'Nữ tính',
      'Vintage',
      'Retro',
      'Preppy',
      'Cá tính',
    },
    'Thể thao': {
      'Thể thao',
      'Năng động',
    },
    'Dự tiệc': {
      'Dự tiệc',
      'Thanh lịch',
      'Old Money',
      'Nữ tính',
      'Cá tính',
      'Smart Casual',
    },
  };

  // Các nhóm phong cách để kiểm tra độ ăn ý & chặn lệch tông
  static const Set<String> _formalStyles = {
    'Công sở',
    'Thanh lịch',
    'Smart Casual',
    'Old Money',
    'Preppy',
    'Dự tiệc',
  };

  static const Set<String> _strictFormalStyles = {
    'Công sở',
    'Dự tiệc',
    'Old Money',
  };

  static const Set<String> _versatileCasualStyles = {
    'Thường ngày',
    'Tối giản',
    'Hàn Quốc',
    'Nữ tính',
    'Vintage',
    'Retro',
  };

  static const Set<String> _edgyStreetStyles = {
    'Đường phố',
    'Y2K',
    'Bụi bặm',
    'Oversize',
    'Cá tính',
  };

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
    'Xanh lá',
  };

  static const Set<String> _darkRainSafeColors = {
    'Đen',
    'Xám',
    'Nâu',
    'Xanh dương',
  };

  // --- Phân tích bản chất thực tế của món đồ qua Tên + Nhãn phong cách ---
  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  // Nhận diện đồ thể thao chuyên dụng (Áo đá banh, quần đá banh, đồ tập gym, chạy bộ...)
  static bool _isPureSportswear(ClothingItem item) {
    final name = item.name.toLowerCase();
    if (_containsAny(name, const [
      'đá banh',
      'bóng đá',
      'bóng rổ',
      'cầu lông',
      'tập gym',
      'đồ tập',
      'chạy bộ',
      'jersey',
      'quần đùi thể thao',
      'giày đá',
      'đồ bơi',
    ])) {
      return true;
    }

    final styles = item.styles.toSet();
    if (!styles.contains('Thể thao')) return false;

    // Nếu người dùng chỉ gắn "Thể thao" (hoặc "Thể thao, Năng động") mà không gắn phong cách đời thường
    final nonSport = styles.difference(const {'Thể thao', 'Năng động'});
    return nonSport.isEmpty;
  }

  // Nhận diện đồ Âu / Công sở / Trang trọng (Quần tây, quần âu, vest, sơ mi công sở, giày tây...)
  static bool _isTailoredFormal(ClothingItem item) {
    final name = item.name.toLowerCase();
    if (_containsAny(name, const [
      'quần tây',
      'quần âu',
      'vest',
      'suit',
      'blazer',
      'giày tây',
      'oxford',
      'derby',
      'loafer',
      'cao gót',
      'dạ hội',
      'công sở',
    ])) {
      return true;
    }

    final styles = item.styles.toSet();
    return styles.isNotEmpty &&
        styles.every((s) => _strictFormalStyles.contains(s));
  }

  // Nhận diện món đồ mang tính trang trọng / thanh lịch nói chung (gồm cả Áo Polo thanh lịch, Sơ mi...)
  static bool _hasFormalLeaning(ClothingItem item) {
    if (_isTailoredFormal(item)) return true;
    final name = item.name.toLowerCase();
    if (_containsAny(name, const ['sơ mi', 'polo'])) return true;
    final styles = item.styles.toSet();
    return styles.any(_formalStyles.contains) &&
        !styles.contains('Thể thao') &&
        !styles.contains('Đường phố');
  }

  // Nhận diện dép lê / đồ đi biển xuề xòa
  static bool _isUltraCasualBeachOrSlipper(ClothingItem item) {
    final name = item.name.toLowerCase();
    if (item.type == 'Dép' &&
        !_containsAny(name, const ['sandal', 'quai hậu', 'cao gót'])) {
      return true;
    }
    return _containsAny(name, const [
      'dép lê',
      'dép lào',
      'tông',
      'đi biển',
      'ba lỗ',
      'quần đùi ngủ',
    ]);
  }

  // Danh sách các hoàn cảnh phù hợp để mặc một trang phục cụ thể
  static List<String> suitableOccasionsForItem(ClothingItem item) {
    return allOccasions
        .where((occ) => _isItemAllowedForOccasion(item, occ))
        .toList();
  }

  // Kiểm tra 1 món đồ có được phép xuất hiện trong hoàn cảnh (Occasion) không
  static bool _isItemAllowedForOccasion(ClothingItem item, String occasion) {
    final name = item.name.toLowerCase();
    final styles = item.styles.toSet();
    final pureSport = _isPureSportswear(item);
    final tailored = _isTailoredFormal(item);
    final ultraCasual = _isUltraCasualBeachOrSlipper(item);

    switch (occasion) {
      case 'Đi làm':
        if (pureSport || ultraCasual) return false;
        if (_containsAny(name, const ['quần đùi', 'quần short', 'croptop'])) {
          return false;
        }
        // Tránh đồ chỉ thuần Bụi bặm / Y2K / Du lịch khi đi làm
        if (styles.every(
          (s) => const {'Bụi bặm', 'Y2K', 'Du lịch', 'Thể thao'}.contains(s),
        )) {
          return false;
        }
        return true;

      case 'Đi học':
        // Không mặc áo đá banh, quần đá banh, đồ tập gym hoặc đầm dạ hội đi học giảng đường
        if (pureSport || ultraCasual) return false;
        if (_containsAny(name, const ['quần đùi', 'dạ hội'])) return false;
        if (styles.length == 1 && styles.contains('Dự tiệc')) return false;
        return true;

      case 'Hẹn hò':
        if (pureSport || ultraCasual) return false;
        return true;

      case 'Dự tiệc':
        if (pureSport || ultraCasual) return false;
        if (_containsAny(name, const ['quần đùi', 'quần short', 'jogger'])) {
          return false;
        }
        return true;

      case 'Thể thao':
        // Không bao giờ mặc Quần Tây, Áo Sơ mi, Áo Polo thanh lịch, Váy/Đầm, Giày Tây đi tập thể thao
        if (tailored || _hasFormalLeaning(item) || ultraCasual) return false;
        if (item.type == 'Đầm' || item.type == 'Túi xách') return false;
        if (item.type == 'Váy' &&
            !_containsAny(name, const ['tennis', 'thể thao', 'cầu lông'])) {
          return false;
        }
        // Chỉ nhận đồ Thể thao, Năng động hoặc đồ Thường ngày/Oversize cơ bản dễ vận động
        return styles.any(
          (s) => const {
            'Thể thao',
            'Năng động',
            'Thường ngày',
            'Oversize',
            'Tối giản',
          }.contains(s),
        );

      case 'Đi chơi':
      default:
        // Đi chơi linh hoạt, nhưng quần đá banh chuyên dụng chỉ hợp đi tập thể thao
        if (_containsAny(name, const ['quần đá banh', 'quần tập gym'])) {
          return false;
        }
        return true;
    }
  }

  // Kiểm tra tổng thể cả bộ trang phục có hài hòa thực tế với nhau không (Chặn Áo Đá Banh + Quần Tây!)
  static bool _isOutfitHarmonious(List<ClothingItem> items, String occasion) {
    if (items.isEmpty) return false;

    final hasPureSport = items.any(_isPureSportswear);
    final hasTailored = items.any(_isTailoredFormal);
    final hasFormalLeaning = items.any(_hasFormalLeaning);
    final hasUltraCasual = items.any(_isUltraCasualBeachOrSlipper);

    // QUY TẮC CỐT LÕI 1: Không bao giờ ghép Đồ Thể thao chuyên dụng (Áo/Quần đá banh, đồ tập)
    // với Quần Tây / Đồ Âu / Áo Polo thanh lịch / Sơ mi / Blazer / Giày Tây!
    if (hasPureSport && (hasTailored || hasFormalLeaning)) {
      return false;
    }

    // QUY TẮC CỐT LÕI 2: Quần Tây / Suit / Đầm trang trọng không đi với Dép lê hoặc đồ quá bụi bặm
    if (hasTailored && hasUltraCasual) {
      return false;
    }

    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        final a = items[i];
        final b = items[j];
        final aStyles = a.styles.toSet();
        final bStyles = b.styles.toSet();

        // Chặn ghép đồ thuần Công sở/Dự tiệc/Old Money với đồ thuần Bụi bặm/Y2K/Du lịch
        final aStrictFormal =
            _isTailoredFormal(a) || aStyles.every(_strictFormalStyles.contains);
        final bStrictEdgy = bStyles.every(
          (s) => const {'Bụi bặm', 'Y2K', 'Du lịch', 'Thể thao'}.contains(s),
        );
        final bStrictFormal =
            _isTailoredFormal(b) || bStyles.every(_strictFormalStyles.contains);
        final aStrictEdgy = aStyles.every(
          (s) => const {'Bụi bặm', 'Y2K', 'Du lịch', 'Thể thao'}.contains(s),
        );

        if ((aStrictFormal && bStrictEdgy) || (bStrictFormal && aStrictEdgy)) {
          return false;
        }
      }
    }

    // QUY TẮC CỐT LÕI 3: Dịp Thể thao bắt buộc phải có ít nhất 1 món mang tính Thể thao / Năng động thật sự
    if (occasion == 'Thể thao') {
      final hasAthleticCore = items.any(
        (item) =>
            _isPureSportswear(item) ||
            item.styles.any((s) => s == 'Thể thao' || s == 'Năng động'),
      );
      if (!hasAthleticCore) return false;
    }

    // QUY TẮC CỐT LÕI 4: Dịp Dự tiệc bắt buộc phải có ít nhất 1 món lịch sự/nổi bật
    if (occasion == 'Dự tiệc') {
      final hasDressyPiece = items.any(
        (item) =>
            _hasFormalLeaning(item) ||
            item.type == 'Đầm' ||
            item.styles.any((s) => (occasionStyles['Dự tiệc']!).contains(s)),
      );
      if (!hasDressyPiece) return false;
    }

    return true;
  }

  // Điểm ăn ý về phong cách giữa các món đồ & độ khớp hoàn cảnh
  static double _styleAndCohesionScore(
    List<ClothingItem> items,
    String occasion,
    UserPreferences? prefs,
  ) {
    final targetStyles = occasionStyles[occasion] ?? const {};

    // 1. Điểm khớp hoàn cảnh trung bình của từng món
    double itemSum = 0;
    for (final item in items) {
      final itemStyles = item.styles;
      final matchedOccasion = itemStyles.any(targetStyles.contains);
      final isVersatileBridge = itemStyles.any(_versatileCasualStyles.contains);

      double s = matchedOccasion
          ? 94
          : (isVersatileBridge && occasion != 'Dự tiệc' ? 80 : 66);

      if (prefs != null &&
          itemStyles.any((st) => prefs.preferredStyles.contains(st))) {
        s += 5;
      }
      itemSum += s.clamp(0, 100);
    }
    final avgOccasionFit = itemSum / items.length;

    // 2. Điểm đồng điệu phong cách giữa Áo và Quần/Váy
    double cohesion = 85;
    if (items.length >= 2) {
      final firstStyles = items[0].styles.toSet();
      final secondStyles = items[1].styles.toSet();

      if (firstStyles.intersection(secondStyles).isNotEmpty) {
        cohesion = 97; // Cùng chung nhãn phong cách (VD: Thanh lịch + Thanh lịch, Thể thao + Thể thao)
      } else if ((firstStyles.any(_formalStyles.contains) &&
              secondStyles.any(_formalStyles.contains)) ||
          (firstStyles.any(_edgyStreetStyles.contains) &&
              secondStyles.any(_edgyStreetStyles.contains))) {
        cohesion = 93; // Cùng họ phong cách
      } else if ((firstStyles.any(_formalStyles.contains) &&
              secondStyles.any(_versatileCasualStyles.contains)) ||
          (secondStyles.any(_formalStyles.contains) &&
              firstStyles.any(_versatileCasualStyles.contains))) {
        cohesion = 89; // Smart Casual chuẩn (VD: Áo Thun tối giản/thường ngày + Quần Tây thanh lịch)
      }
    }

    return (avgOccasionFit * 0.62 + cohesion * 0.38).clamp(0, 100);
  }

  // Điểm phối màu theo nguyên tắc bánh xe màu & gam trung tính thực tế
  static double _colorScore(
    List<ClothingItem> items,
    UserPreferences? prefs,
  ) {
    if (items.isEmpty) return 0;
    final colors = items
        .map((e) => e.color.trim())
        .where((c) => c != 'Khác')
        .toList();
    if (colors.isEmpty) return 82;

    final distinct = colors.toSet();
    final nonNeutrals = distinct.where((c) => !neutralColors.contains(c)).toSet();

    double base;
    if (distinct.length == 1) {
      // Monochrome / Ton-sur-ton đồng bộ
      base = neutralColors.contains(distinct.first) ? 91 : 85;
    } else if (nonNeutrals.isEmpty) {
      // Toàn bộ là gam trung tính (Trắng, Đen, Xám, Be, Kem, Nâu) -> cực kỳ sang và an toàn
      base = 95;
    } else if (nonNeutrals.length == 1) {
      // Quy tắc kinh điển: Nền trung tính + 1 màu nhấn chủ đạo (VD: Xanh dương + Trắng/Xám/Đen)
      base = 94;
    } else if (nonNeutrals.length == 2 && distinct.any(neutralColors.contains)) {
      base = 82;
    } else {
      // Phối quá nhiều màu nổi không có gam trung tính cân bằng -> rối mắt
      base = 62;
    }

    if (prefs != null &&
        colors.any((c) => prefs.favoriteColors.contains(c))) {
      base += 4;
    }
    return base.clamp(0, 100);
  }

  // Điểm thích ứng thời tiết thực tế
  static double _weatherScore(
    List<ClothingItem> items,
    WeatherInfo? weather,
  ) {
    if (weather == null) return 88;
    final hasJacket = items.any((e) => e.type == 'Áo khoác');
    final hasLightColor =
        items.any((e) => coolBreathableColors.contains(e.color));
    final bottomOrShoeDark = items
        .where((e) => e.type == 'Quần' || e.type == 'Váy' || e.type == 'Giày')
        .any((e) => _darkRainSafeColors.contains(e.color));

    if (weather.kind == WeatherKind.rainy) {
      double score = hasJacket ? 93 : 84;
      if (bottomOrShoeDark) score += 5; // Quần/giày tối màu sạch sẽ khi trời mưa
      return score.clamp(0, 100);
    }
    if (weather.temperatureC >= 29) {
      if (hasJacket) return 70; // Trời nắng nóng hạn chế khoác dày
      return hasLightColor ? 96 : 89;
    }
    if (weather.temperatureC <= 22) {
      return hasJacket ? 98 : 75;
    }
    return hasLightColor ? 93 : 88;
  }

  static double _calculateScore(
    List<ClothingItem> items,
    String occasion,
    WeatherInfo? weather,
    UserPreferences? prefs,
  ) {
    if (items.isEmpty) return 0;

    final styleCohesion = _styleAndCohesionScore(items, occasion, prefs);
    final color = _colorScore(items, prefs);
    final weatherCompatibility = _weatherScore(items, weather);

    return (styleCohesion * 0.48 + color * 0.30 + weatherCompatibility * 0.22)
        .clamp(60, 99);
  }

  static String _dominantStyleLabel(List<ClothingItem> items, String occasion) {
    final target = occasionStyles[occasion] ?? const {};
    // Ưu tiên hiển thị phong cách khớp với hoàn cảnh đang chọn
    for (final item in items) {
      for (final st in item.styles) {
        if (target.contains(st)) return st;
      }
    }
    return items.isNotEmpty ? items.first.primaryStyle : 'Thanh lịch';
  }

  static String _buildTitle(List<ClothingItem> items, String occasion) {
    final dominantStyle = _dominantStyleLabel(items, occasion);
    switch (occasion) {
      case 'Đi học':
        return 'Thanh lịch Giảng đường · $dominantStyle';
      case 'Đi làm':
        return 'Chuẩn mực Công sở · $dominantStyle';
      case 'Đi chơi':
        return 'Dạo phố Tự tin · $dominantStyle';
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
          : 'Gọn gàng sạch sẽ · Trời mưa $temp°C';
    }
    if (weather.temperatureC >= 28 && !hasJacket) {
      return 'Thoáng mát dễ chịu · Hợp $temp°C';
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
    final names = items.map((e) => e.name).join(' kết hợp cùng ');
    final colors = items.map((e) => e.color).toSet().join(' - ');
    final styleLabel = _dominantStyleLabel(items, occasion);
    final weatherClause = weather == null
        ? 'thoải mái hoạt động cả ngày'
        : 'phù hợp tiết trời ${weather.condition.toLowerCase()} ${weather.temperatureC.round()}°C tại ${weather.city}';

    final favMatch = prefs != null &&
        items.any((e) => prefs.favoriteColors.contains(e.color));
    final personalClause = favMatch
        ? ' đồng thời đúng tông màu yêu thích trong hồ sơ của bạn.'
        : ' giữ được phom dáng đồng điệu và dễ ứng dụng thực tế.';

    return '$names trên tông màu ($colors) tạo tổng thể $styleLabel chuẩn dịp "$occasion", $weatherClause,$personalClause';
  }

  // Tạo gợi ý phối đồ thông minh (có lọc nghiêm ngặt các cặp lệch tông)
  static List<OutfitSuggestion> generateOutfits(
    List<ClothingItem> clothes,
    String occasion, {
    WeatherInfo? weather,
    UserPreferences? preferences,
    int variationSeed = 0,
    int limit = 4,
  }) {
    // Bước 1: Chỉ giữ lại các món đồ thực sự phù hợp với hoàn cảnh đang chọn
    final eligible = clothes
        .where((item) => _isItemAllowedForOccasion(item, occasion))
        .toList();

    final tops = eligible.where((item) => item.type == 'Áo').toList();
    final bottoms = eligible
        .where((item) => item.type == 'Quần' || item.type == 'Váy')
        .toList();
    final onePieces = eligible
        .where((item) => item.type == 'Đầm' || item.type == 'Đồ bộ')
        .toList();
    final shoes = eligible
        .where((item) => item.type == 'Giày' || item.type == 'Dép')
        .toList();
    final jackets =
        eligible.where((item) => item.type == 'Áo khoác').toList();
    final accessories = eligible
        .where(
          (item) =>
              item.type == 'Túi xách' ||
              item.type == 'Nón / Mũ' ||
              item.type == 'Phụ kiện',
        )
        .toList();

    final List<List<ClothingItem>> combinations = [];

    // Kiểu 1: Áo + Quần/Váy (+ Giày/Dép nếu có món giày hợp phong cách)
    for (final top in tops) {
      for (final bottom in bottoms) {
        if (!_isOutfitHarmonious([top, bottom], occasion)) continue;

        final matchingShoes = shoes
            .where((shoe) => _isOutfitHarmonious([top, bottom, shoe], occasion))
            .toList();

        if (matchingShoes.isEmpty) {
          combinations.add([top, bottom]);
        } else {
          for (final shoe in matchingShoes) {
            combinations.add([top, bottom, shoe]);
          }
        }
      }
    }

    // Kiểu 2: Đầm/Đồ bộ (+ Giày/Dép hợp phong cách)
    for (final onePiece in onePieces) {
      if (!_isOutfitHarmonious([onePiece], occasion)) continue;

      final matchingShoes = shoes
          .where((shoe) => _isOutfitHarmonious([onePiece, shoe], occasion))
          .toList();

      if (matchingShoes.isEmpty) {
        combinations.add([onePiece]);
      } else {
        for (final shoe in matchingShoes) {
          combinations.add([onePiece, shoe]);
        }
      }
    }

    // Bước 2: Mở rộng Áo khoác & Phụ kiện (chỉ ghép khi hài hòa phong cách)
    final List<List<ClothingItem>> expanded = [];
    final shouldPreferLayer = occasion != 'Thể thao' &&
        (weather != null
            ? (weather.temperatureC <= 25 ||
                weather.kind == WeatherKind.rainy ||
                occasion == 'Đi làm' ||
                occasion == 'Dự tiệc')
            : (occasion == 'Đi làm' || occasion == 'Dự tiệc'));

    for (final base in combinations) {
      expanded.add(base);
      if (shouldPreferLayer || (variationSeed.isOdd && occasion != 'Thể thao')) {
        for (final jacket in jackets) {
          final layered = [...base, jacket];
          if (_isOutfitHarmonious(layered, occasion)) {
            expanded.add(layered);
          }
        }
      }
      for (final acc in accessories) {
        final withAcc = [...base, acc];
        if (_isOutfitHarmonious(withAcc, occasion)) {
          expanded.add(withAcc);
        }
      }
    }

    if (expanded.isEmpty) return const [];

    final heroUrl = MockCatalog.editorialPhotosByOccasion[occasion] ??
        MockCatalog.editorialPhotosByOccasion['Đi học'];

    final scored = expanded.map((items) {
      final baseScore = _calculateScore(items, occasion, weather, preferences);
      final idSig = items.map((e) => e.id).join('_');
      final jitter = variationSeed == 0
          ? 0.0
          : (((idSig.hashCode ^ variationSeed).abs() % 5) - 2).toDouble();

      return OutfitSuggestion(
        id: 'outfit_${occasion.hashCode.abs()}_$idSig',
        title: _buildTitle(items, occasion),
        occasion: occasion,
        items: items,
        score: (baseScore + jitter).clamp(65, 99),
        reason: _buildReason(items, occasion, weather, preferences),
        weatherTag: _buildWeatherTag(items, weather),
        heroImageUrl: heroUrl,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Bước 3: Ưu tiên các bộ khác nhau về cặp món đồ chính (Áo + Quần)
    final List<OutfitSuggestion> distinct = [];
    final Set<String> usedPrimaryPairs = {};

    for (final candidate in scored) {
      final pairKey = candidate.items.take(2).map((e) => e.id).join('-');
      if (!usedPrimaryPairs.contains(pairKey)) {
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
