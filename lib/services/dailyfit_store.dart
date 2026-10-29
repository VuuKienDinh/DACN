import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/outfit_suggestion.dart';
import '../models/planned_outfit.dart';
import '../models/user_preferences.dart';
import '../models/weather_info.dart';
import 'clothing_service.dart';
import 'outfit_service.dart';
import 'weather_service.dart';

class DailyFitStore {
  DailyFitStore._();

  static final DailyFitStore instance = DailyFitStore._();

  static const String _prefsKey = 'dailyfit_user_preferences_v1';
  static const String _favoritesKey = 'dailyfit_favorite_outfits_v1';
  static const String _plansKey = 'dailyfit_planned_outfits_v1';
  static const String _seededKey = 'dailyfit_initial_seeded_v1';

  final WeatherService _weatherService = WeatherService();

  final ValueNotifier<UserPreferences> preferences =
      ValueNotifier<UserPreferences>(UserPreferences.defaults());

  final ValueNotifier<WeatherInfo?> weather = ValueNotifier<WeatherInfo?>(null);

  final ValueNotifier<bool> isLoadingWeather = ValueNotifier<bool>(false);

  final ValueNotifier<List<OutfitSuggestion>> favorites =
      ValueNotifier<List<OutfitSuggestion>>([]);

  final ValueNotifier<Map<String, PlannedOutfit>> plannedOutfits =
      ValueNotifier<Map<String, PlannedOutfit>>({});

  bool _initialized = false;

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    preferences.value = UserPreferences.defaults();
    weather.value = null;
    isLoadingWeather.value = false;
    favorites.value = [];
    plannedOutfits.value = {};
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();

    // 1. Đọc hồ sơ cá nhân (tự động đồng bộ tên mặc định mới nếu dữ liệu cũ lưu tên mặc định trước đó)
    final rawPrefs = prefs.getString(_prefsKey);
    if (rawPrefs != null && rawPrefs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPrefs) as Map<String, dynamic>;
        final loaded = UserPreferences.fromJson(decoded);
        preferences.value = loaded;
        if (decoded['displayName']?.toString().trim() != loaded.displayName) {
          await _persistPreferences();
        }
      } catch (_) {}
    }

    // 2. Đọc danh sách Yêu thích
    final rawFavs = prefs.getString(_favoritesKey);
    if (rawFavs != null && rawFavs.isNotEmpty) {
      try {
        final list = jsonDecode(rawFavs) as List<dynamic>;
        favorites.value = list
            .map(
              (e) => OutfitSuggestion.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } catch (_) {}
    }

    // 3. Đọc lịch phối đồ
    final rawPlans = prefs.getString(_plansKey);
    if (rawPlans != null && rawPlans.isNotEmpty) {
      try {
        final map = jsonDecode(rawPlans) as Map<String, dynamic>;
        final parsed = <String, PlannedOutfit>{};
        for (final entry in map.entries) {
          parsed[entry.key] = PlannedOutfit.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
        plannedOutfits.value = parsed;
      } catch (_) {}
    }

    // 4. Nạp thời tiết ban đầu và tủ đồ song song
    await Future.wait([
      refreshWeather(),
      ClothingService.instance.loadClothes(),
    ]);

    // 5. Khởi tạo gợi ý mẫu lần đầu nếu người dùng mới cài đặt hoàn toàn
    final alreadySeeded = prefs.getBool(_seededKey) ?? false;
    if (!alreadySeeded) {
      await _seedStarterPlansIfPossible();
      await prefs.setBool(_seededKey, true);
    }
  }

  Future<void> _seedStarterPlansIfPossible() async {
    final clothes = ClothingService.instance.items.value;
    if (clothes.isEmpty) return;

    final workOutfits = OutfitService.generateOutfits(
      clothes,
      'Đi làm',
      weather: weather.value,
      preferences: preferences.value,
      limit: 2,
    );
    final schoolOutfits = OutfitService.generateOutfits(
      clothes,
      'Đi học',
      weather: weather.value,
      preferences: preferences.value,
      limit: 1,
    );

    final starterFavs = <OutfitSuggestion>[
      if (workOutfits.isNotEmpty) workOutfits.first,
      if (schoolOutfits.isNotEmpty) schoolOutfits.first,
    ];

    if (favorites.value.isEmpty && starterFavs.isNotEmpty) {
      favorites.value = starterFavs;
      await _persistFavorites();
    }

    if (plannedOutfits.value.isEmpty && workOutfits.isNotEmpty) {
      final todayKey = PlannedOutfit.formatKey(DateTime.now());
      final tomorrowKey = PlannedOutfit.formatKey(
        DateTime.now().add(const Duration(days: 1)),
      );
      final map = <String, PlannedOutfit>{
        todayKey: PlannedOutfit(
          dateKey: todayKey,
          occasion: 'Đi làm',
          note: 'Lịch trình chính hôm nay',
          outfit: workOutfits.first,
        ),
        if (schoolOutfits.isNotEmpty)
          tomorrowKey: PlannedOutfit(
            dateKey: tomorrowKey,
            occasion: 'Đi học',
            note: 'Chuẩn bị trước cho ngày mai',
            outfit: schoolOutfits.first,
          ),
      };
      plannedOutfits.value = map;
      await _persistPlans();
    }
  }

  Future<void> refreshWeather() async {
    isLoadingWeather.value = true;
    try {
      weather.value = await _weatherService.fetchWeatherForCity(
        preferences.value.city,
      );
    } finally {
      isLoadingWeather.value = false;
    }
  }

  // --- Quản lý Yêu thích ---
  bool isFavorite(String outfitId) {
    return favorites.value.any((e) => e.id == outfitId);
  }

  Future<bool> toggleFavorite(OutfitSuggestion outfit) async {
    final exists = isFavorite(outfit.id);
    if (exists) {
      favorites.value =
          favorites.value.where((e) => e.id != outfit.id).toList();
    } else {
      favorites.value = [outfit, ...favorites.value];
    }
    await _persistFavorites();
    return !exists;
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _favoritesKey,
      jsonEncode(favorites.value.map((e) => e.toJson()).toList()),
    );
  }

  // --- Quản lý Lịch phối đồ ---
  PlannedOutfit? getPlanForDate(DateTime date) {
    return plannedOutfits.value[PlannedOutfit.formatKey(date)];
  }

  Future<void> scheduleOutfit({
    required DateTime date,
    required OutfitSuggestion outfit,
    String? occasion,
    String note = '',
  }) async {
    final key = PlannedOutfit.formatKey(date);
    final updated = Map<String, PlannedOutfit>.from(plannedOutfits.value);
    updated[key] = PlannedOutfit(
      dateKey: key,
      occasion: occasion ?? outfit.occasion,
      note: note,
      outfit: outfit,
    );
    plannedOutfits.value = updated;
    await _persistPlans();
  }

  Future<void> togglePlanWorn(DateTime date) async {
    final key = PlannedOutfit.formatKey(date);
    final existing = plannedOutfits.value[key];
    if (existing == null) return;

    final updated = Map<String, PlannedOutfit>.from(plannedOutfits.value);
    updated[key] = existing.copyWith(isWorn: !existing.isWorn);
    plannedOutfits.value = updated;
    await _persistPlans();
  }

  Future<void> removePlanForDate(DateTime date) async {
    final key = PlannedOutfit.formatKey(date);
    final updated = Map<String, PlannedOutfit>.from(plannedOutfits.value);
    updated.remove(key);
    plannedOutfits.value = updated;
    await _persistPlans();
  }

  Future<void> _persistPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = <String, dynamic>{};
    for (final entry in plannedOutfits.value.entries) {
      serialized[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_plansKey, jsonEncode(serialized));
  }

  // --- Quản lý Hồ sơ & Sở thích ---
  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    preferences.value = preferences.value.copyWith(displayName: trimmed);
    await _persistPreferences();
  }

  Future<void> updateCity(String city) async {
    if (city == preferences.value.city) return;
    preferences.value = preferences.value.copyWith(city: city);
    await _persistPreferences();
    await refreshWeather();
  }

  Future<void> togglePreferredStyle(String style) async {
    final current = List<String>.from(preferences.value.preferredStyles);
    if (current.contains(style)) {
      if (current.length > 1) {
        current.remove(style);
      }
    } else {
      current.add(style);
    }
    preferences.value = preferences.value.copyWith(preferredStyles: current);
    await _persistPreferences();
  }

  Future<void> toggleFavoriteColor(String color) async {
    final current = List<String>.from(preferences.value.favoriteColors);
    if (current.contains(color)) {
      if (current.length > 1) {
        current.remove(color);
      }
    } else {
      current.add(color);
    }
    preferences.value = preferences.value.copyWith(favoriteColors: current);
    await _persistPreferences();
  }

  Future<void> setTemperatureUnit({required bool useCelsius}) async {
    preferences.value = preferences.value.copyWith(useCelsius: useCelsius);
    await _persistPreferences();
  }

  Future<void> _persistPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(preferences.value.toJson()),
    );
  }
}

