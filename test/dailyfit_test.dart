import 'dart:convert';

import 'package:doanchuyennganh/data/mock_catalog.dart';
import 'package:doanchuyennganh/main.dart';
import 'package:doanchuyennganh/models/planned_outfit.dart';
import 'package:doanchuyennganh/models/user_preferences.dart';
import 'package:doanchuyennganh/models/weather_info.dart';
import 'package:doanchuyennganh/services/clothing_service.dart';
import 'package:doanchuyennganh/services/dailyfit_store.dart';
import 'package:doanchuyennganh/services/outfit_service.dart';
import 'package:doanchuyennganh/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    DailyFitStore.instance.resetForTesting();
    ClothingService.instance.items.value = [];
    ClothingService.instance.syncStatus.value = BackendSyncStatus.idle;
  });

  group('OutfitService, WeatherService & UserPreferences unit tests', () {
    test('Tên hồ sơ mặc định là Vưu Kiên Định và tự động nâng cấp dữ liệu cũ', () {
      final defaults = UserPreferences.defaults();
      expect(defaults.displayName, 'Vưu Kiên Định');

      final migratedFromVinh = UserPreferences.fromJson({
        'displayName': 'Vinh Nguyễn',
        'city': 'TP. Hồ Chí Minh',
      });
      expect(migratedFromVinh.displayName, 'Vưu Kiên Định');

      final migratedFromDinh = UserPreferences.fromJson({
        'displayName': 'Vưu Kiên Đinh',
        'city': 'TP. Hồ Chí Minh',
      });
      expect(migratedFromDinh.displayName, 'Vưu Kiên Định');

      final custom = UserPreferences.fromJson({
        'displayName': 'Vưu Kiên Định Pro',
        'city': 'Đà Nẵng',
      });
      expect(custom.displayName, 'Vưu Kiên Định Pro');
    });

    test('DailyFitStore tự động cập nhật SharedPreferences sang Vưu Kiên Định',
        () async {
      SharedPreferences.setMockInitialValues({
        'dailyfit_user_preferences_v1': jsonEncode({
          'displayName': 'Vưu Kiên Đinh',
          'city': 'TP. Hồ Chí Minh',
          'preferredStyles': ['Tối giản', 'Thanh lịch'],
          'favoriteColors': ['Xanh dương', 'Trắng'],
          'useCelsius': true,
        }),
      });

      await DailyFitStore.instance.initialize();
      expect(DailyFitStore.instance.preferences.value.displayName, 'Vưu Kiên Định');

      final prefs = await SharedPreferences.getInstance();
      final savedJson = jsonDecode(
        prefs.getString('dailyfit_user_preferences_v1')!,
      ) as Map<String, dynamic>;
      expect(savedJson['displayName'], 'Vưu Kiên Định');
    });

    test('Tạo gợi ý phối đồ cho Đi học, Đi làm, Đi chơi từ tủ đồ mẫu', () {
      final weather = WeatherService().buildMockWeather('TP. Hồ Chí Minh');
      final prefs = UserPreferences.defaults();

      for (final occasion in ['Đi học', 'Đi làm', 'Đi chơi']) {
        final outfits = OutfitService.generateOutfits(
          MockCatalog.defaultWardrobe,
          occasion,
          weather: weather,
          preferences: prefs,
        );

        expect(outfits, isNotEmpty);
        expect(outfits.first.occasion, occasion);
        expect(outfits.first.items.length, greaterThanOrEqualTo(2));
        expect(outfits.first.score, inInclusiveRange(60, 99));
      }
    });

    test('WeatherInfo trả về đúng đơn vị °C/°F và lời khuyên thời tiết', () {
      final mock = WeatherService().buildMockWeather('Đà Lạt');
      expect(mock.source, WeatherSource.mockFallback);
      expect(mock.isLive, isFalse);
      expect(mock.formatTemperature(useCelsius: true), contains('°C'));
      expect(mock.formatTemperature(useCelsius: false), contains('°F'));
      expect(mock.stylingAdvice, isNotEmpty);
    });

    test('PlannedOutfit serialize/deserialize JSON chính xác', () {
      final sampleOutfit = OutfitService.generateOutfits(
        MockCatalog.defaultWardrobe,
        'Đi làm',
      ).first;

      final date = DateTime(2026, 10, 30);
      final plan = PlannedOutfit(
        dateKey: PlannedOutfit.formatKey(date),
        occasion: 'Đi làm',
        note: 'Thuyết trình đồ án',
        outfit: sampleOutfit,
      );

      final restored = PlannedOutfit.fromJson(plan.toJson());
      expect(restored.dateKey, '2026-10-30');
      expect(restored.note, 'Thuyết trình đồ án');
      expect(restored.outfit.id, sampleOutfit.id);
    });
  });

  testWidgets(
      'DailyFitApp chạy mượt trên màn hình dọc 360x800, hiển thị tên Vưu Kiên Định và đóng hộp thoại không lỗi',
      (WidgetTester tester) async {
    // Giả lập kích thước điện thoại Android dọc thực tế (360x800) để bắt mọi lỗi tràn dòng
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    await DailyFitStore.instance.initialize();

    await tester.pumpWidget(const DailyFitApp());
    await tester.pump(const Duration(milliseconds: 350));

    // Kiểm tra tên Vưu Kiên Định trên lời chào Trang chủ
    expect(find.textContaining('Vưu Kiên Định'), findsOneWidget);

    // Mở bảng chọn thành phố trên Trang chủ và chọn Đà Lạt
    await tester.tap(find.text('TP. Hồ Chí Minh'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn khu vực thời tiết'), findsOneWidget);
    await tester.tap(find.text('Đà Lạt'));
    await tester.pumpAndSettle();

    // Mở màn hình Thêm trang phục và quay lại an toàn
    await tester.tap(find.byTooltip('Thêm trang phục nhanh'));
    await tester.pumpAndSettle();
    expect(find.text('Bổ sung vào tủ đồ'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Chuyển qua từng tab kiểm tra không có bất kỳ lỗi tràn khung hay assertion nào
    await tester.tap(find.text('Gợi ý'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Gợi ý phối đồ'), findsOneWidget);

    // Mở BottomSheet lên lịch mặc và lưu ghi chú để kiểm tra vòng đời TextEditingController
    final scheduleBtn = find.text('Lên lịch mặc').first;
    await tester.ensureVisible(scheduleBtn);
    await tester.tap(scheduleBtn);
    await tester.pumpAndSettle();

    expect(find.text('Lên lịch mặc trang phục'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      'Bảo vệ đồ án chuyên ngành',
    );
    await tester.tap(find.text('Xác nhận lưu lịch mặc'));
    // Chạy hết animation đóng BottomSheet để đảm bảo không lỗi _dependents.isEmpty
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Chuyển sang Tủ đồ
    await tester.tap(find.text('Tủ đồ'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Tủ đồ của tôi'), findsOneWidget);

    // Chuyển sang Lịch đồ
    await tester.tap(find.text('Lịch đồ'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Lịch phối đồ'), findsOneWidget);

    // Chuyển sang Hồ sơ và kiểm tra hiển thị Vưu Kiên Định + mở/đóng hộp thoại đổi tên
    await tester.tap(find.text('Hồ sơ'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Hồ sơ phong cách'), findsOneWidget);
    expect(find.text('Vưu Kiên Định'), findsOneWidget);
    expect(find.text('VĐ'), findsOneWidget);
    expect(find.text('Đà Lạt'), findsOneWidget);

    // Nhấn nút sửa tên -> mở hộp thoại -> bấm Hủy -> chờ hết hiệu ứng đóng
    await tester.tap(find.byTooltip('Đổi tên hiển thị'));
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật tên hiển thị'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    // Mở lại hộp thoại -> nhập tên mới -> bấm Lưu -> chờ hết hiệu ứng đóng
    await tester.tap(find.byTooltip('Đổi tên hiển thị'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Vưu Kiên Định');
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    expect(find.text('Vưu Kiên Định'), findsOneWidget);
  });
}
