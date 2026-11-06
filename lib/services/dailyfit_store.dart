import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';
import '../models/auth_user.dart';
import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../models/planned_outfit.dart';
import '../models/user_preferences.dart';
import '../models/weather_info.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';
import 'clothing_api_service.dart';
import 'clothing_service.dart';
import 'outfit_service.dart';
import 'weather_service.dart';

class DailyFitStore {
  DailyFitStore._();

  static final DailyFitStore instance = DailyFitStore._();

  static const String _prefsKey = 'dailyfit_user_preferences_v1';
  static const String _legacyFavoritesKey = 'dailyfit_favorite_outfits_v1';
  static const String _legacyPlansKey = 'dailyfit_planned_outfits_v1';
  static const String _authUserKey = 'dailyfit_auth_user_v1';
  static const String _guestModeKey = 'dailyfit_guest_mode_v1';

  static const Set<String> _legacyAutoSeededNotes = {
    'Lịch trình chính hôm nay',
    'Chuẩn bị trước cho ngày mai',
  };

  final WeatherService _weatherService = WeatherService();

  final ValueNotifier<bool> isReady = ValueNotifier<bool>(false);

  final ValueNotifier<AuthUser?> currentUser = ValueNotifier<AuthUser?>(null);

  final ValueNotifier<bool> isGuestSession = ValueNotifier<bool>(false);

  bool get hasActiveSession =>
      currentUser.value != null || isGuestSession.value;

  final ValueNotifier<UserPreferences> preferences =
      ValueNotifier<UserPreferences>(UserPreferences.defaults());

  final ValueNotifier<WeatherInfo?> weather = ValueNotifier<WeatherInfo?>(null);

  final ValueNotifier<bool> isLoadingWeather = ValueNotifier<bool>(false);

  final ValueNotifier<List<OutfitSuggestion>> favorites =
      ValueNotifier<List<OutfitSuggestion>>([]);

  final ValueNotifier<Map<String, PlannedOutfit>> plannedOutfits =
      ValueNotifier<Map<String, PlannedOutfit>>({});

  // --- Truy xuất nhanh thông tin hồ sơ đang hoạt động (Tài khoản hoặc Khách) ---
  String get activeDisplayName {
    final user = currentUser.value;
    if (user != null && user.fullName.trim().isNotEmpty) {
      return user.fullName.trim();
    }
    return preferences.value.displayName;
  }

  String get activeEmail =>
      currentUser.value?.email ?? preferences.value.email;

  String get activePhone =>
      currentUser.value?.phoneNumber ?? preferences.value.phoneNumber;

  String get activeAddress =>
      currentUser.value?.address ?? preferences.value.address;

  String get activeGender =>
      currentUser.value?.gender ?? preferences.value.gender;

  String get activeBirthDate =>
      currentUser.value?.birthDate ?? preferences.value.birthDate;

  String get activeBio => currentUser.value?.bio ?? preferences.value.bio;

  String get activeAvatarPath =>
      currentUser.value?.avatarUrl ?? preferences.value.avatarPath;

  bool _initialized = false;

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    isReady.value = false;
    currentUser.value = null;
    isGuestSession.value = false;
    preferences.value = UserPreferences.defaults();
    AppColors.isDark = false;
    weather.value = null;
    isLoadingWeather.value = false;
    favorites.value = [];
    plannedOutfits.value = {};
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();

    // 0. Đọc phiên đăng nhập hoặc chế độ Khách đã lưu
    final rawAuthUser = prefs.getString(_authUserKey);
    if (rawAuthUser != null && rawAuthUser.isNotEmpty) {
      try {
        final decodedUser = jsonDecode(rawAuthUser) as Map<String, dynamic>;
        currentUser.value = AuthUser.fromJson(decodedUser);
      } catch (_) {}
    }
    isGuestSession.value =
        currentUser.value == null && (prefs.getBool(_guestModeKey) ?? false);

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

    if (currentUser.value != null &&
        currentUser.value!.fullName.trim().isNotEmpty &&
        preferences.value.displayName != currentUser.value!.fullName) {
      preferences.value = preferences.value.copyWith(
        displayName: currentUser.value!.fullName,
      );
    }

    AppColors.isDark = preferences.value.isDarkMode;
    AppTheme.applySystemOverlay(isDark: AppColors.isDark);

    // 2. Đọc danh sách Yêu thích & Lịch phối đồ theo đúng phiên tài khoản (tự động dọn dữ liệu mẫu cũ)
    await _loadSessionCollections(prefs);

    // Đánh dấu đã đọc xong phiên đăng nhập cục bộ để hiển thị giao diện ngay lập tức
    isReady.value = true;

    // 3. Nạp thời tiết ban đầu, tủ đồ và đồng bộ hồ sơ tài khoản (nếu trực tuyến) song song
    await Future.wait([
      refreshWeather(),
      ClothingService.instance.loadClothes(),
      _syncAuthenticatedProfileIfPossible(),
    ]);

    // 4. Đối soát lại Lịch mặc & Yêu thích với tủ đồ thực tế sau khi tải xong
    await reconcileWithWardrobe(
      ClothingService.instance.items.value,
      isAuthoritativeWardrobe: ClothingService.instance.isOnlineConnected,
    );
  }

  String _activeScopeSuffix() {
    final user = currentUser.value;
    if (user != null && user.username.trim().isNotEmpty) {
      return 'user_${user.username.trim().toLowerCase()}';
    }
    return 'guest';
  }

  String get _activeFavoritesKey =>
      'dailyfit_favorites_${_activeScopeSuffix()}';

  String get _activePlansKey => 'dailyfit_plans_${_activeScopeSuffix()}';

  bool _isLegacySeededPlan(PlannedOutfit plan) {
    if (_legacyAutoSeededNotes.contains(plan.note.trim())) {
      return true;
    }
    return false;
  }

  Future<void> _loadSessionCollections([SharedPreferences? existingPrefs]) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    final favKey = _activeFavoritesKey;
    final planKey = _activePlansKey;

    // Nạp hoặc chuyển tiếp Yêu thích từ khóa cũ sang khóa riêng của tài khoản
    String? rawFavs = prefs.getString(favKey);
    bool migratedFavs = false;
    if (rawFavs == null && prefs.containsKey(_legacyFavoritesKey)) {
      rawFavs = prefs.getString(_legacyFavoritesKey);
      await prefs.remove(_legacyFavoritesKey);
      migratedFavs = true;
    }

    final parsedFavs = <OutfitSuggestion>[];
    if (rawFavs != null && rawFavs.isNotEmpty) {
      try {
        final list = jsonDecode(rawFavs) as List<dynamic>;
        for (final e in list) {
          final suggestion = OutfitSuggestion.fromJson(
            Map<String, dynamic>.from(e as Map),
          );
          if (suggestion.items.isNotEmpty) {
            parsedFavs.add(suggestion);
          }
        }
      } catch (_) {}
    }
    favorites.value = parsedFavs;
    if (migratedFavs) {
      await _persistFavorites();
    }

    // Nạp hoặc chuyển tiếp Lịch phối đồ (loại bỏ hoàn toàn 2 lịch mẫu tự sinh trước đây)
    String? rawPlans = prefs.getString(planKey);
    bool needsPlanPersist = false;
    if (rawPlans == null && prefs.containsKey(_legacyPlansKey)) {
      rawPlans = prefs.getString(_legacyPlansKey);
      await prefs.remove(_legacyPlansKey);
      needsPlanPersist = true;
    }

    final parsedPlans = <String, PlannedOutfit>{};
    if (rawPlans != null && rawPlans.isNotEmpty) {
      try {
        final map = jsonDecode(rawPlans) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final plan = PlannedOutfit.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
          final normalizedDate = PlannedOutfit.tryParseKey(entry.key);
          if (normalizedDate == null ||
              plan.outfit.items.isEmpty ||
              _isLegacySeededPlan(plan)) {
            needsPlanPersist = true;
            continue;
          }
          final cleanKey = PlannedOutfit.formatKey(normalizedDate);
          parsedPlans[cleanKey] = cleanKey == plan.dateKey
              ? plan
              : PlannedOutfit(
                  dateKey: cleanKey,
                  occasion: plan.occasion,
                  note: plan.note,
                  outfit: plan.outfit,
                  isWorn: plan.isWorn,
                );
        }
      } catch (_) {}
    }
    plannedOutfits.value = parsedPlans;
    if (needsPlanPersist) {
      await _persistPlans();
    }
  }

  // Giữ Lịch phối đồ & Yêu thích đồng bộ tuyệt đối với Tủ đồ thực tế
  Future<void> reconcileWithWardrobe(
    List<ClothingItem> wardrobe, {
    required bool isAuthoritativeWardrobe,
  }) async {
    final byId = <String, ClothingItem>{
      for (final item in wardrobe) item.id: item,
    };

    bool outfitValid(OutfitSuggestion outfit) {
      if (outfit.items.isEmpty) return false;
      if (!isAuthoritativeWardrobe) return true;
      // Khi đã kết nối tủ đồ thực trên SQL Server, loại bỏ các bộ đồ mồ côi hoặc hàng mẫu mock-*
      return outfit.items.every(
        (i) => !i.id.startsWith('mock-') && byId.containsKey(i.id),
      );
    }

    OutfitSuggestion refreshItems(OutfitSuggestion outfit) {
      final refreshed = outfit.items.map((i) => byId[i.id] ?? i).toList();
      return OutfitSuggestion(
        id: outfit.id,
        title: outfit.title,
        occasion: outfit.occasion,
        items: refreshed,
        score: outfit.score,
        reason: outfit.reason,
        weatherTag: outfit.weatherTag,
        heroImageUrl: refreshed.first.imagePath.isNotEmpty
            ? refreshed.first.imagePath
            : outfit.heroImageUrl,
      );
    }

    final nextFavs = favorites.value
        .where(outfitValid)
        .map(refreshItems)
        .toList();
    if (nextFavs.length != favorites.value.length) {
      favorites.value = nextFavs;
      await _persistFavorites();
    }

    final nextPlans = <String, PlannedOutfit>{};
    bool plansChanged = false;
    for (final entry in plannedOutfits.value.entries) {
      final plan = entry.value;
      if (_isLegacySeededPlan(plan) || !outfitValid(plan.outfit)) {
        plansChanged = true;
        continue;
      }

      var syncedOutfit = refreshItems(plan.outfit);

      // Tự động sửa các lịch cũ bị lệch hoàn cảnh (ví dụ nhãn 'Thể thao' nhưng đang gắn nhầm bộ 'Đi chơi')
      if (wardrobe.isNotEmpty && syncedOutfit.occasion != plan.occasion) {
        final dt = PlannedOutfit.tryParseKey(plan.dateKey);
        final regenerated = OutfitService.generateOutfits(
          wardrobe,
          plan.occasion,
          weather: weather.value,
          preferences: preferences.value,
          variationSeed: dt != null ? (dt.day + dt.month * 31) : 0,
          limit: 1,
        );
        if (regenerated.isNotEmpty) {
          syncedOutfit = regenerated.first;
          plansChanged = true;
        }
      }

      nextPlans[entry.key] = PlannedOutfit(
        dateKey: plan.dateKey,
        occasion: plan.occasion,
        note: plan.note,
        outfit: syncedOutfit,
        isWorn: plan.isWorn,
      );
    }
    if (plansChanged || nextPlans.length != plannedOutfits.value.length) {
      plannedOutfits.value = nextPlans;
      await _persistPlans();
    }
  }

  // Xoá các lịch mặc / yêu thích chứa món đồ vừa bị người dùng xoá khỏi tủ đồ
  Future<void> removeClothingItemFromSavedOutfits(String deletedItemId) async {
    final beforeFavCount = favorites.value.length;
    final nextFavs = favorites.value
        .where((f) => !f.items.any((i) => i.id == deletedItemId))
        .toList();
    if (nextFavs.length != beforeFavCount) {
      favorites.value = nextFavs;
      await _persistFavorites();
    }

    final nextPlans = <String, PlannedOutfit>{};
    bool removedAnyPlan = false;
    for (final entry in plannedOutfits.value.entries) {
      if (entry.value.outfit.items.any((i) => i.id == deletedItemId)) {
        removedAnyPlan = true;
        continue;
      }
      nextPlans[entry.key] = entry.value;
    }
    if (removedAnyPlan) {
      plannedOutfits.value = nextPlans;
      await _persistPlans();
    }
  }

  Future<void> _syncAuthenticatedProfileIfPossible() async {
    final user = currentUser.value;
    if (user == null || user.isLocalAccount || user.id <= 0) return;

    // Lấy dữ liệu gốc từ SQL Server (chưa trộn bộ nhớ đệm) để phát hiện trường còn thiếu trên DB
    AuthUser? rawServerUser;
    if (ConfigUrl.hasBackendUrl) {
      try {
        final res = await AuthService.instance.fetchRawServerProfile(user.id);
        rawServerUser = res;
      } catch (_) {}
    }
    if (rawServerUser == null || currentUser.value?.id != user.id) return;

    final merged = rawServerUser.copyWith(
      phoneNumber: rawServerUser.phoneNumber.isNotEmpty
          ? rawServerUser.phoneNumber
          : user.phoneNumber,
      address:
          rawServerUser.address.isNotEmpty ? rawServerUser.address : user.address,
      gender:
          rawServerUser.gender.isNotEmpty ? rawServerUser.gender : user.gender,
      birthDate: rawServerUser.birthDate.isNotEmpty
          ? rawServerUser.birthDate
          : user.birthDate,
      bio: rawServerUser.bio.isNotEmpty ? rawServerUser.bio : user.bio,
      avatarUrl: rawServerUser.avatarUrl.isNotEmpty
          ? rawServerUser.avatarUrl
          : user.avatarUrl,
    );

    final isLocalAvatarFile = merged.avatarUrl.isNotEmpty &&
        !merged.avatarUrl.startsWith('/uploads/') &&
        !merged.avatarUrl.startsWith('uploads/') &&
        !merged.avatarUrl.startsWith('http');

    final needsServerPush = isLocalAvatarFile ||
        (merged.avatarUrl.isNotEmpty && rawServerUser.avatarUrl.isEmpty) ||
        (merged.phoneNumber.isNotEmpty && rawServerUser.phoneNumber.isEmpty) ||
        (merged.address.isNotEmpty && rawServerUser.address.isEmpty) ||
        (merged.gender.isNotEmpty && rawServerUser.gender.isEmpty) ||
        (merged.birthDate.isNotEmpty && rawServerUser.birthDate.isEmpty) ||
        (merged.bio.isNotEmpty && rawServerUser.bio.isEmpty);

    if (needsServerPush) {
      try {
        final pushed = await AuthService.instance.updateProfile(
          merged,
          newAvatarLocalPath: isLocalAvatarFile ? merged.avatarUrl : null,
          newAvatarFileName: isLocalAvatarFile
              ? merged.avatarUrl.split(RegExp(r'[/\\]')).last
              : null,
        );
        await setAuthenticatedUser(pushed);
        return;
      } catch (_) {}
    }

    await setAuthenticatedUser(merged);
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
      _activeFavoritesKey,
      jsonEncode(favorites.value.map((e) => e.toJson()).toList()),
    );
  }

  // Đồng bộ thông tin sản phẩm vừa chỉnh sửa vào các bộ đồ đã lưu / lên lịch
  Future<void> syncUpdatedClothingItem(ClothingItem updated) async {
    OutfitSuggestion replaceInOutfit(OutfitSuggestion outfit) {
      if (!outfit.items.any((i) => i.id == updated.id)) return outfit;
      final nextItems = outfit.items
          .map((i) => i.id == updated.id ? updated : i)
          .toList();
      return OutfitSuggestion(
        id: outfit.id,
        title: outfit.title,
        occasion: outfit.occasion,
        items: nextItems,
        score: outfit.score,
        reason: outfit.reason,
        weatherTag: outfit.weatherTag,
        heroImageUrl: nextItems.first.imagePath.isNotEmpty
            ? nextItems.first.imagePath
            : outfit.heroImageUrl,
      );
    }

    if (favorites.value.any((f) => f.items.any((i) => i.id == updated.id))) {
      favorites.value = favorites.value.map(replaceInOutfit).toList();
      await _persistFavorites();
    }

    if (plannedOutfits.value.values
        .any((p) => p.outfit.items.any((i) => i.id == updated.id))) {
      final nextPlans = <String, PlannedOutfit>{};
      for (final entry in plannedOutfits.value.entries) {
        nextPlans[entry.key] = PlannedOutfit(
          dateKey: entry.value.dateKey,
          occasion: entry.value.occasion,
          note: entry.value.note,
          outfit: replaceInOutfit(entry.value.outfit),
          isWorn: entry.value.isWorn,
        );
      }
      plannedOutfits.value = nextPlans;
      await _persistPlans();
    }
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
    await prefs.setString(_activePlansKey, jsonEncode(serialized));
  }

  // --- Quản lý Tài khoản & Phiên đăng nhập ---
  Future<void> setAuthenticatedUser(AuthUser user) async {
    final previousScope = _activeScopeSuffix();
    currentUser.value = user;
    isGuestSession.value = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authUserKey, jsonEncode(user.toJson()));
    await prefs.remove(_guestModeKey);

    if (user.fullName.trim().isNotEmpty) {
      preferences.value = preferences.value.copyWith(
        displayName: user.fullName.trim(),
      );
      await _persistPreferences();
    }

    if (_activeScopeSuffix() != previousScope) {
      await _loadSessionCollections(prefs);
      await reconcileWithWardrobe(
        ClothingService.instance.items.value,
        isAuthoritativeWardrobe: ClothingService.instance.isOnlineConnected,
      );
    }
  }

  Future<void> continueAsGuest() async {
    currentUser.value = null;
    isGuestSession.value = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authUserKey);
    await prefs.setBool(_guestModeKey, true);
    await _loadSessionCollections(prefs);
  }

  Future<void> logout() async {
    currentUser.value = null;
    isGuestSession.value = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authUserKey);
    await prefs.remove(_guestModeKey);
    favorites.value = [];
    plannedOutfits.value = {};
  }

  // --- Quản lý Hồ sơ cá nhân chi tiết & Ảnh đại diện ---
  Future<void> updateUserProfile({
    required String fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? gender,
    String? birthDate,
    String? bio,
    String? avatarUrl,
    String? newAvatarLocalPath,
    String? newAvatarFileName,
  }) async {
    final cleanName = fullName.trim();
    if (cleanName.isEmpty) {
      throw const AuthException('Vui lòng nhập họ và tên hiển thị');
    }

    final user = currentUser.value;
    if (user != null) {
      final draft = user.copyWith(
        fullName: cleanName,
        email: email != null ? email.trim().toLowerCase() : user.email,
        phoneNumber: phoneNumber ?? user.phoneNumber,
        address: address ?? user.address,
        gender: gender ?? user.gender,
        birthDate: birthDate ?? user.birthDate,
        bio: bio ?? user.bio,
        avatarUrl: avatarUrl ?? user.avatarUrl,
      );
      final saved = await AuthService.instance.updateProfile(
        draft,
        newAvatarLocalPath: newAvatarLocalPath,
        newAvatarFileName: newAvatarFileName,
      );
      await setAuthenticatedUser(saved);
      return;
    }

    // Chế độ Khách (Guest)
    final cleanEmail = (email ?? preferences.value.email).trim().toLowerCase();
    if (cleanEmail.isNotEmpty &&
        (!cleanEmail.contains('@') || !cleanEmail.contains('.'))) {
      throw const AuthException('Địa chỉ email không hợp lệ');
    }

    String resolvedAvatar = avatarUrl ?? preferences.value.avatarPath;
    if (newAvatarLocalPath != null && newAvatarLocalPath.trim().isNotEmpty) {
      resolvedAvatar = newAvatarLocalPath.trim();
      if (ConfigUrl.hasBackendUrl) {
        try {
          resolvedAvatar = await ClothingApiService().uploadImage(
            resolvedAvatar,
            newAvatarFileName ?? 'avatar.jpg',
          );
        } catch (_) {}
      }
    }

    preferences.value = preferences.value.copyWith(
      displayName: cleanName,
      email: cleanEmail,
      phoneNumber: (phoneNumber ?? preferences.value.phoneNumber).trim(),
      address: (address ?? preferences.value.address).trim(),
      gender: (gender ?? preferences.value.gender).trim(),
      birthDate: (birthDate ?? preferences.value.birthDate).trim(),
      bio: (bio ?? preferences.value.bio).trim(),
      avatarPath: resolvedAvatar.trim(),
    );
    await _persistPreferences();
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await updateUserProfile(fullName: trimmed);
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

  Future<void> setDarkMode(bool enabled) async {
    if (preferences.value.isDarkMode == enabled &&
        AppColors.isDark == enabled) {
      return;
    }
    AppColors.isDark = enabled;
    AppTheme.applySystemOverlay(isDark: enabled);
    preferences.value = preferences.value.copyWith(isDarkMode: enabled);
    await _persistPreferences();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!preferences.value.isDarkMode);
  }

  Future<void> _persistPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(preferences.value.toJson()),
    );
  }
}
