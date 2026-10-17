
import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';

class OutfitService {
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

  // Tính điểm phong cách
  static double _styleScore(
      ClothingItem item,
      String occasion,
      ) {
    final suitableStyles = occasionStyles[occasion] ?? [];

    if (suitableStyles.contains(item.style)) {
      return 100;
    }

    return 40;
  }

  // Tính điểm phối màu cho cả bộ
  static double _colorScore(List<ClothingItem> items) {
    if (items.isEmpty) return 0;

    final colors = items.map((e) => e.color).toList();

    // Nếu tất cả cùng màu
    if (colors.toSet().length == 1) {
      return 85;
    }

    // Nếu có ít nhất một màu trung tính
    if (colors.any(neutralColors.contains)) {
      return 90;
    }

    // Các trường hợp màu khác
    return 60;
  }

  // Tính điểm tổng theo trọng số
  static double _calculateScore(
      List<ClothingItem> items,
      String occasion,
      ) {
    if (items.isEmpty) return 0;

    final styleAverage = items
        .map((item) => _styleScore(item, occasion))
        .reduce((a, b) => a + b) /
        items.length;

    final colorScore = _colorScore(items);

    // 60% phong cách, 40% màu sắc
    return styleAverage * 0.6 + colorScore * 0.4;
  }

  // Tạo gợi ý phối đồ
  static List<OutfitSuggestion> generateOutfits(
      List<ClothingItem> clothes,
      String occasion,
      ) {
    final tops = clothes
        .where((item) => item.type == 'Áo')
        .toList();

    final bottoms = clothes
        .where((item) =>
    item.type == 'Quần' || item.type == 'Váy')
        .toList();

    final onePieces = clothes
        .where((item) =>
    item.type == 'Đầm' || item.type == 'Đồ bộ')
        .toList();

    final shoes = clothes
        .where((item) =>
    item.type == 'Giày' || item.type == 'Dép')
        .toList();

    final jackets = clothes
        .where((item) => item.type == 'Áo khoác')
        .toList();

    final accessories = clothes
        .where((item) =>
    item.type == 'Túi xách' ||
        item.type == 'Nón / Mũ' ||
        item.type == 'Phụ kiện')
        .toList();

    final List<List<ClothingItem>> combinations = [];

    // Kiểu 1: Áo + Quần/Váy + Giày/Dép
    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoes) {
          combinations.add([top, bottom, shoe]);
        }
      }
    }

    // Kiểu 2: Đầm/Đồ bộ + Giày/Dép
    for (final onePiece in onePieces) {
      for (final shoe in shoes) {
        combinations.add([onePiece, shoe]);
      }
    }

    // Thêm áo khoác và phụ kiện nếu có
    final List<List<ClothingItem>> expanded = [];

    for (final combination in combinations) {
      expanded.add(combination);

      for (final jacket in jackets) {
        expanded.add([...combination, jacket]);
      }

      for (final accessory in accessories) {
        expanded.add([...combination, accessory]);
      }
    }

    // Chấm điểm
    final suggestions = expanded.map((items) {
      final score = _calculateScore(items, occasion);

      return OutfitSuggestion(
        items: items,
        score: score,
        reason:
        'Bộ trang phục được đánh giá theo phong cách '
            'phù hợp với hoàn cảnh và khả năng phối màu.',
      );
    }).toList();

    // Sắp xếp điểm cao xuống thấp
    suggestions.sort(
          (a, b) => b.score.compareTo(a.score),
    );

    // Trả về tối đa 3 bộ gợi ý
    return suggestions.take(3).toList();
  }
}
