class ClothingItem {
  final String id;
  final String name;
  final String type;
  final String color;
  final String style;
  final String imagePath;
  final bool isLocalOnly;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.style,
    required this.imagePath,
    this.isLocalOnly = false,
  });

  ClothingItem copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    String? style,
    String? imagePath,
    bool? isLocalOnly,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      style: style ?? this.style,
      imagePath: imagePath ?? this.imagePath,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    );
  }

  // Chuyển JSON từ API thành đối tượng Flutter
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Áo',
      color: json['color']?.toString() ?? 'Trắng',
      style: json['style']?.toString() ?? 'Thường ngày',
      imagePath: json['imagePath']?.toString() ?? '',
      isLocalOnly: json['isLocalOnly'] == true,
    );
  }

  // Chuyển đối tượng thành dữ liệu gửi API Backend .NET
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'color': color,
      'style': style,
      // Ảnh đã upload hoặc URL hợp lệ để lưu lên Backend
      'imagePath': imagePath.isEmpty ? null : imagePath,
    };
  }

  // Dữ liệu đầy đủ để lưu bộ nhớ đệm cục bộ trên thiết bị
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'style': style,
      'imagePath': imagePath,
      'isLocalOnly': isLocalOnly,
    };
  }
}
