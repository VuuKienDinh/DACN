import '../models/clothing_item.dart';

class MockCatalog {
  // Ảnh editorial thời trang chất lượng cao cho các hoàn cảnh
  static const Map<String, String> editorialPhotosByOccasion = {
    'Đi học':
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?auto=format&fit=crop&w=900&q=80',
    'Đi làm':
        'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?auto=format&fit=crop&w=900&q=80',
    'Đi chơi':
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
    'Hẹn hò':
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&w=900&q=80',
    'Thể thao':
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=900&q=80',
    'Dự tiệc':
        'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=900&q=80',
  };

  // Bộ tủ đồ mẫu chất lượng cao (dùng khi chưa có kết nối Backend hoặc người dùng nạp mẫu thử)
  static const List<ClothingItem> defaultWardrobe = [
    ClothingItem(
      id: 'mock-1',
      name: 'Áo sơ mi Oxford xanh pastel',
      type: 'Áo',
      color: 'Xanh dương',
      style: 'Thanh lịch',
      imagePath:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-2',
      name: 'Áo thun Cotton trắng Essential',
      type: 'Áo',
      color: 'Trắng',
      style: 'Tối giản',
      imagePath:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-3',
      name: 'Áo Polo dệt kim xanh Navy',
      type: 'Áo',
      color: 'Xanh dương',
      style: 'Công sở',
      imagePath:
          'https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-4',
      name: 'Quần Chinos ống đứng trắng kem',
      type: 'Quần',
      color: 'Kem',
      style: 'Hàn Quốc',
      imagePath:
          'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-5',
      name: 'Quần âu Tailored xám tro',
      type: 'Quần',
      color: 'Xám',
      style: 'Công sở',
      imagePath:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-6',
      name: 'Quần Jeans xanh sáng năng động',
      type: 'Quần',
      color: 'Xanh dương',
      style: 'Năng động',
      imagePath:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-7',
      name: 'Blazer Linen xanh coban nhẹ',
      type: 'Áo khoác',
      color: 'Xanh dương',
      style: 'Thanh lịch',
      imagePath:
          'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-8',
      name: 'Áo khoác Cardigan màu Be',
      type: 'Áo khoác',
      color: 'Be',
      style: 'Hàn Quốc',
      imagePath:
          'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-9',
      name: 'Sneaker da trắng Minimalist',
      type: 'Giày',
      color: 'Trắng',
      style: 'Tối giản',
      imagePath:
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-10',
      name: 'Giày Loafer da đen cổ điển',
      type: 'Giày',
      color: 'Đen',
      style: 'Công sở',
      imagePath:
          'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-11',
      name: 'Giày chạy bộ Cloud trắng xanh',
      type: 'Giày',
      color: 'Xanh dương',
      style: 'Thể thao',
      imagePath:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
    ClothingItem(
      id: 'mock-12',
      name: 'Túi Tote Canvas phối da',
      type: 'Túi xách',
      color: 'Trắng',
      style: 'Hàn Quốc',
      imagePath:
          'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=700&q=80',
      isLocalOnly: true,
    ),
  ];
}

