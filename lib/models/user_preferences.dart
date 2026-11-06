class VietnamCity {
  final String name;
  final double latitude;
  final double longitude;
  final double defaultTempC;
  final int defaultHumidity;
  final String defaultCondition;

  const VietnamCity({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.defaultTempC,
    required this.defaultHumidity,
    required this.defaultCondition,
  });
}

class UserPreferences {
  final String displayName;
  final String city;
  final List<String> preferredStyles;
  final List<String> favoriteColors;
  final bool useCelsius;
  final bool isDarkMode;
  final String email;
  final String phoneNumber;
  final String address;
  final String gender;
  final String birthDate;
  final String bio;
  final String avatarPath;

  const UserPreferences({
    required this.displayName,
    required this.city,
    required this.preferredStyles,
    required this.favoriteColors,
    this.useCelsius = true,
    this.isDarkMode = false,
    this.email = '',
    this.phoneNumber = '',
    this.address = '',
    this.gender = '',
    this.birthDate = '',
    this.bio = '',
    this.avatarPath = '',
  });

  static const List<VietnamCity> supportedCities = [
    VietnamCity(
      name: 'TP. Hồ Chí Minh',
      latitude: 10.8231,
      longitude: 106.6297,
      defaultTempC: 29,
      defaultHumidity: 68,
      defaultCondition: 'Nắng dịu',
    ),
    VietnamCity(
      name: 'Hà Nội',
      latitude: 21.0278,
      longitude: 105.8342,
      defaultTempC: 25,
      defaultHumidity: 72,
      defaultCondition: 'Mát mẻ, ít mây',
    ),
    VietnamCity(
      name: 'Đà Nẵng',
      latitude: 16.0544,
      longitude: 108.2022,
      defaultTempC: 28,
      defaultHumidity: 74,
      defaultCondition: 'Nắng nhẹ gió biển',
    ),
    VietnamCity(
      name: 'Đà Lạt',
      latitude: 11.9404,
      longitude: 108.4583,
      defaultTempC: 19,
      defaultHumidity: 80,
      defaultCondition: 'Se lạnh dễ chịu',
    ),
    VietnamCity(
      name: 'Cần Thơ',
      latitude: 10.0452,
      longitude: 105.7469,
      defaultTempC: 30,
      defaultHumidity: 75,
      defaultCondition: 'Nắng ấm',
    ),
    VietnamCity(
      name: 'Hải Phòng',
      latitude: 20.8449,
      longitude: 106.6881,
      defaultTempC: 26,
      defaultHumidity: 76,
      defaultCondition: 'Trời quang mây',
    ),
  ];

  static const String defaultDisplayName = 'Vưu Kiên Định';
  static const Set<String> _legacyDefaultDisplayNames = {
    'Vinh Nguyễn',
    'Vưu Kiên Đinh',
  };

  static VietnamCity findCity(String cityName) {
    for (final item in supportedCities) {
      if (item.name == cityName) return item;
    }
    return supportedCities.first;
  }

  factory UserPreferences.defaults() {
    return const UserPreferences(
      displayName: defaultDisplayName,
      city: 'TP. Hồ Chí Minh',
      preferredStyles: ['Tối giản', 'Thanh lịch', 'Hàn Quốc'],
      favoriteColors: ['Xanh dương', 'Trắng', 'Be', 'Đen'],
      useCelsius: true,
      isDarkMode: false,
    );
  }

  UserPreferences copyWith({
    String? displayName,
    String? city,
    List<String>? preferredStyles,
    List<String>? favoriteColors,
    bool? useCelsius,
    bool? isDarkMode,
    String? email,
    String? phoneNumber,
    String? address,
    String? gender,
    String? birthDate,
    String? bio,
    String? avatarPath,
  }) {
    return UserPreferences(
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      favoriteColors: favoriteColors ?? this.favoriteColors,
      useCelsius: useCelsius ?? this.useCelsius,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final styles = (json['preferredStyles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Tối giản', 'Thanh lịch', 'Hàn Quốc'];
    final colors = (json['favoriteColors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Xanh dương', 'Trắng', 'Be', 'Đen'];

    final rawName = json['displayName']?.toString().trim();
    final resolvedName = (rawName == null ||
            rawName.isEmpty ||
            _legacyDefaultDisplayNames.contains(rawName))
        ? defaultDisplayName
        : rawName;

    return UserPreferences(
      displayName: resolvedName,
      city: json['city']?.toString() ?? 'TP. Hồ Chí Minh',
      preferredStyles: styles,
      favoriteColors: colors,
      useCelsius: json['useCelsius'] != false,
      isDarkMode: json['isDarkMode'] == true,
      email: (json['email'] ?? '').toString().trim(),
      phoneNumber: (json['phoneNumber'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      gender: (json['gender'] ?? '').toString().trim(),
      birthDate: (json['birthDate'] ?? '').toString().trim(),
      bio: (json['bio'] ?? '').toString().trim(),
      avatarPath: (json['avatarPath'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'city': city,
      'preferredStyles': preferredStyles,
      'favoriteColors': favoriteColors,
      'useCelsius': useCelsius,
      'isDarkMode': isDarkMode,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'gender': gender,
      'birthDate': birthDate,
      'bio': bio,
      'avatarPath': avatarPath,
    };
  }
}
