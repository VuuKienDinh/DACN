
class ClothingItem {
  final String id;
  final String name;
  final String type;
  final String color;
  final String style;
  final String imagePath;

  ClothingItem({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.style,
    required this.imagePath,
  });

  // Chuyển JSON từ API thành đối tượng Flutter
  factory ClothingItem.fromJson(
      Map<String, dynamic> json,
      ) {
    return ClothingItem(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
    );
  }

  // Chuyển đối tượng thành dữ liệu gửi API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'color': color,
      'style': style,
      // Chưa gửi đường dẫn ảnh cục bộ lên server.
      // Ảnh sẽ được upload ở bước tiếp theo.
      'imagePath': imagePath.isEmpty ? null : imagePath,
    };
  }
}
