import 'dart:convert';

import 'package:doanchuyennganh/data/mock_catalog.dart';
import 'package:doanchuyennganh/main.dart';
import 'package:doanchuyennganh/models/clothing_item.dart';
import 'package:doanchuyennganh/models/planned_outfit.dart';
import 'package:doanchuyennganh/models/user_preferences.dart';
import 'package:doanchuyennganh/models/weather_info.dart';
import 'package:doanchuyennganh/screens/home_screen.dart';
import 'package:doanchuyennganh/services/auth_service.dart';
import 'package:doanchuyennganh/services/clothing_service.dart';
import 'package:doanchuyennganh/services/dailyfit_store.dart';
import 'package:doanchuyennganh/services/outfit_service.dart';
import 'package:doanchuyennganh/services/weather_service.dart';
import 'package:doanchuyennganh/theme/app_theme.dart';
import 'package:doanchuyennganh/widgets/clothing_card.dart';
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

  group('OutfitService, WeatherService, AuthService & UserPreferences tests',
      () {
    test('Tên hồ sơ mặc định là Vưu Kiên Định và tự động nâng cấp dữ liệu cũ',
        () {
      expect(
        HomeScreen.formatVietnameseDate(DateTime(2026, 11, 6)),
        'Thứ Sáu, 6 tháng 11, 2026',
      );
      expect(
        HomeScreen.formatVietnameseDate(DateTime(2026, 11, 8)),
        'Chủ Nhật, 8 tháng 11, 2026',
      );

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
      expect(
        DailyFitStore.instance.preferences.value.displayName,
        'Vưu Kiên Định',
      );

      final prefs = await SharedPreferences.getInstance();
      final savedJson = jsonDecode(
        prefs.getString('dailyfit_user_preferences_v1')!,
      ) as Map<String, dynamic>;
      expect(savedJson['displayName'], 'Vưu Kiên Định');
    });

    test('Đăng ký, đăng nhập, kiểm tra trùng lặp và đồng bộ phiên người dùng',
        () async {
      SharedPreferences.setMockInitialValues({});
      await DailyFitStore.instance.initialize();
      expect(DailyFitStore.instance.hasActiveSession, isFalse);

      final created = await AuthService.instance.register(
        fullName: 'Vưu Kiên Định',
        username: 'vuukiendinh',
        email: 'dinh@dailyfit.vn',
        password: 'Password123',
      );
      expect(created.fullName, 'Vưu Kiên Định');
      expect(created.username, 'vuukiendinh');

      // Chặn đăng ký trùng username
      await expectLater(
        () => AuthService.instance.register(
          fullName: 'Người Khác',
          username: 'vuukiendinh',
          email: 'khac@dailyfit.vn',
          password: 'Password123',
        ),
        throwsA(isA<AuthException>()),
      );

      // Chặn sai mật khẩu
      await expectLater(
        () => AuthService.instance.login(
          usernameOrEmail: 'vuukiendinh',
          password: 'SaiMatKhau',
        ),
        throwsA(isA<AuthException>()),
      );

      // Đăng nhập bằng email thành công
      final loggedIn = await AuthService.instance.login(
        usernameOrEmail: 'DINH@DAILYFIT.VN',
        password: 'Password123',
      );
      await DailyFitStore.instance.setAuthenticatedUser(loggedIn);

      expect(DailyFitStore.instance.hasActiveSession, isTrue);
      expect(DailyFitStore.instance.currentUser.value?.username, 'vuukiendinh');
      expect(
        DailyFitStore.instance.preferences.value.displayName,
        'Vưu Kiên Định',
      );

      // Cập nhật chi tiết hồ sơ cá nhân (SĐT, địa chỉ, giới tính, ngày sinh, ảnh đại diện)
      await DailyFitStore.instance.updateUserProfile(
        fullName: 'Vưu Kiên Định',
        email: 'dinhvuu11@gmail.com',
        phoneNumber: '0909123456',
        address: '475A Điện Biên Phủ, TP.HCM',
        gender: 'Nam',
        birthDate: '11/11/2004',
        bio: 'Yêu thích phong cách tối giản & thanh lịch',
        avatarUrl: '/uploads/avatar_dinh.jpg',
      );
      expect(DailyFitStore.instance.activePhone, '0909123456');
      expect(DailyFitStore.instance.activeAddress, '475A Điện Biên Phủ, TP.HCM');
      expect(DailyFitStore.instance.activeAvatarPath, '/uploads/avatar_dinh.jpg');

      // Đăng xuất xóa phiên và đăng nhập lại vẫn giữ nguyên thông tin hồ sơ đã lưu
      await DailyFitStore.instance.logout();
      expect(DailyFitStore.instance.hasActiveSession, isFalse);
      expect(DailyFitStore.instance.currentUser.value, isNull);

      final relogged = await AuthService.instance.login(
        usernameOrEmail: 'vuukiendinh',
        password: 'Password123',
      );
      expect(relogged.phoneNumber, '0909123456');
      expect(relogged.address, '475A Điện Biên Phủ, TP.HCM');
      expect(relogged.avatarUrl, '/uploads/avatar_dinh.jpg');
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

    test(
        'Chặn tuyệt đối phối lệch tông (Áo Đá Banh + Quần Tây) và hỗ trợ đa phong cách',
        () {
      const wardrobe = [
        ClothingItem(
          id: '2',
          name: 'Áo Thun',
          type: 'Áo',
          color: 'Đen',
          style: 'Thường ngày, Tối giản',
          imagePath: '',
        ),
        ClothingItem(
          id: '3',
          name: 'Áo Đá Banh',
          type: 'Áo',
          color: 'Xanh dương',
          style: 'Thể thao',
          imagePath: '',
        ),
        ClothingItem(
          id: '4',
          name: 'Áo Polo',
          type: 'Áo',
          color: 'Đen',
          style: 'Thanh lịch, Smart Casual',
          imagePath: '',
        ),
        ClothingItem(
          id: '5',
          name: 'Quần Tây',
          type: 'Quần',
          color: 'Xám',
          style: 'Thanh lịch, Công sở',
          imagePath: '',
        ),
        ClothingItem(
          id: '6',
          name: 'Quần Đá Banh',
          type: 'Quần',
          color: 'Đen',
          style: 'Thể thao',
          imagePath: '',
        ),
      ];

      expect(wardrobe[0].styles, ['Thường ngày', 'Tối giản']);

      // Kiểm tra mọi hoàn cảnh: KHÔNG BAO GIỜ có bộ ghép Áo Đá Banh với Quần Tây hoặc Áo Polo với Quần Đá Banh
      for (final occasion in OutfitService.allOccasions) {
        final results = OutfitService.generateOutfits(wardrobe, occasion);
        for (final outfit in results) {
          final names = outfit.items.map((e) => e.name).toSet();
          expect(
            names.contains('Áo Đá Banh') && names.contains('Quần Tây'),
            isFalse,
            reason: 'Không được ghép Áo Đá Banh với Quần Tây ở dịp $occasion',
          );
          expect(
            names.contains('Áo Polo') && names.contains('Quần Đá Banh'),
            isFalse,
            reason: 'Không được ghép Áo Polo với Quần Đá Banh ở dịp $occasion',
          );
        }
      }

      // Đi học & Đi làm: Chỉ gợi ý Áo Polo/Áo Thun với Quần Tây, không lọt đồ đá banh
      final schoolOutfits = OutfitService.generateOutfits(wardrobe, 'Đi học');
      expect(schoolOutfits, isNotEmpty);
      for (final o in schoolOutfits) {
        expect(o.items.any((e) => e.name.contains('Đá Banh')), isFalse);
      }

      // Thể thao: Chỉ gợi ý Áo Đá Banh / Áo Thun với Quần Đá Banh, không lọt Quần Tây
      final sportOutfits = OutfitService.generateOutfits(wardrobe, 'Thể thao');
      expect(sportOutfits, isNotEmpty);
      expect(
        sportOutfits.first.items.map((e) => e.name).toList(),
        ['Áo Đá Banh', 'Quần Đá Banh'],
      );
      for (final o in sportOutfits) {
        expect(o.items.any((e) => e.name == 'Quần Tây'), isFalse);
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

    test(
        'Tự động dọn sạch 2 lịch mẫu cũ để giữ đúng số ngày người dùng thực sự lên lịch và xoá lịch khi xoá áo quần',
        () async {
      const realWardrobe = [
        ClothingItem(
          id: '4',
          name: 'Áo Polo',
          type: 'Áo',
          color: 'Đen',
          style: 'Thanh lịch',
          imagePath: '',
        ),
        ClothingItem(
          id: '5',
          name: 'Quần Tây',
          type: 'Quần',
          color: 'Xám',
          style: 'Thanh lịch',
          imagePath: '',
        ),
      ];
      final realOutfit =
          OutfitService.generateOutfits(realWardrobe, 'Đi làm').first;
      final mockOutfit = OutfitService.generateOutfits(
        MockCatalog.defaultWardrobe,
        'Đi học',
      ).first;

      SharedPreferences.setMockInitialValues({
        'dailyfit_planned_outfits_v1': jsonEncode({
          '2026-10-29': PlannedOutfit(
            dateKey: '2026-10-29',
            occasion: 'Đi làm',
            note: 'Lịch trình chính hôm nay',
            outfit: mockOutfit,
          ).toJson(),
          '2026-10-30': PlannedOutfit(
            dateKey: '2026-10-30',
            occasion: 'Đi học',
            note: 'Chuẩn bị trước cho ngày mai',
            outfit: mockOutfit,
          ).toJson(),
          '2026-11-06': PlannedOutfit(
            dateKey: '2026-11-06',
            occasion: 'Đi làm',
            note: '',
            outfit: realOutfit,
          ).toJson(),
        }),
      });

      await DailyFitStore.instance.initialize();
      // Chỉ giữ lại đúng 1 ngày (2026-11-06) do người dùng tự thêm, loại bỏ 2 ngày tự sinh cũ
      expect(DailyFitStore.instance.plannedOutfits.value.length, 1);
      expect(
        DailyFitStore.instance.plannedOutfits.value.containsKey('2026-11-06'),
        isTrue,
      );

      // Khi người dùng xoá Áo Polo ('4'), lịch mặc chứa món đó cũng tự động được gỡ đồng bộ
      await DailyFitStore.instance.removeClothingItemFromSavedOutfits('4');
      expect(DailyFitStore.instance.plannedOutfits.value, isEmpty);

      // Tự động sửa lịch bị lệch hoàn cảnh (ví dụ ngày 07/11 gắn nhãn 'Thể thao' nhưng lưu nhầm bộ 'Đi chơi')
      const fullWardrobe = [
        ...realWardrobe,
        ClothingItem(
          id: '3',
          name: 'Áo Đá Banh',
          type: 'Áo',
          color: 'Xanh dương',
          style: 'Thể thao',
          imagePath: '',
        ),
        ClothingItem(
          id: '6',
          name: 'Quần Đá Banh',
          type: 'Quần',
          color: 'Đen',
          style: 'Thể thao',
          imagePath: '',
        ),
      ];
      final casualPoloOutfit =
          OutfitService.generateOutfits(fullWardrobe, 'Đi chơi').first;
      await DailyFitStore.instance.scheduleOutfit(
        date: DateTime(2026, 11, 7),
        outfit: casualPoloOutfit,
        occasion: 'Thể thao',
      );
      await DailyFitStore.instance.reconcileWithWardrobe(
        fullWardrobe,
        isAuthoritativeWardrobe: true,
      );
      final fixedSportPlan =
          DailyFitStore.instance.getPlanForDate(DateTime(2026, 11, 7))!;
      expect(fixedSportPlan.occasion, 'Thể thao');
      expect(fixedSportPlan.outfit.occasion, 'Thể thao');
      expect(
        fixedSportPlan.outfit.items.map((e) => e.name).toList(),
        ['Áo Đá Banh', 'Quần Đá Banh'],
      );
    });

    test('Chế độ tối AMOLED (#000000) chuyển đổi tức thì và lưu bền vững',
        () async {
      SharedPreferences.setMockInitialValues({});
      await DailyFitStore.instance.initialize();
      expect(DailyFitStore.instance.preferences.value.isDarkMode, isFalse);
      expect(AppColors.background, const Color(0xFFF4F8FF));

      await DailyFitStore.instance.toggleDarkMode();
      expect(DailyFitStore.instance.preferences.value.isDarkMode, isTrue);
      expect(AppColors.background, const Color(0xFF000000));

      final prefs = await SharedPreferences.getInstance();
      final savedJson = jsonDecode(
        prefs.getString('dailyfit_user_preferences_v1')!,
      ) as Map<String, dynamic>;
      expect(savedJson['isDarkMode'], isTrue);
    });
  });

  testWidgets(
      'DailyFitApp hỗ trợ Đăng ký, Đăng nhập, Chế độ Khách, Đăng xuất và chạy mượt trên 360x800',
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

    // 1. Khi chưa có phiên, mở màn hình Đăng nhập / Đăng ký
    expect(find.text('Tiếp tục với tư cách Khách'), findsOneWidget);

    // Chuyển sang tab Đăng ký và tạo tài khoản Vưu Kiên Định
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('register_fullname')),
      'Vưu Kiên Định',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_username')),
      'vuukiendinh',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_email')),
      'dinh@dailyfit.vn',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password_reg')),
      'Password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_confirm_password')),
      'Password123',
    );

    final createBtn = find.text('Tạo tài khoản mới');
    await tester.ensureVisible(createBtn);
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    // 2. Sau khi đăng ký thành công, tự động vào Trang chủ với tên Vưu Kiên Định & ngày tháng thực tế
    expect(find.textContaining('Vưu Kiên Định'), findsAtLeastNWidgets(1));
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();
    expect(find.textContaining('Vưu Kiên Định'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_live_date')), findsOneWidget);
    // Tài khoản mới hoàn toàn bắt đầu với 0 lịch mặc và 0 yêu thích (không tự độn lịch ảo)
    expect(DailyFitStore.instance.plannedOutfits.value, isEmpty);
    expect(DailyFitStore.instance.favorites.value, isEmpty);

    // Xác minh dòng Thứ/Ngày/Tháng/Năm nằm dưới tên DailyFit và nằm trên lời chào Chào buổi...
    final brandDy = tester.getTopLeft(find.text('DailyFit')).dy;
    final dateDy =
        tester.getTopLeft(find.byKey(const ValueKey('home_live_date'))).dy;
    final greetingDy =
        tester.getTopLeft(find.textContaining('Vưu Kiên Định')).dy;
    expect(dateDy, greaterThan(brandDy));
    expect(greetingDy, greaterThan(dateDy));

    // Bật chế độ Tối AMOLED ngay từ nút góc trên phải Trang chủ (thay cho nút máy ảnh cũ)
    expect(DailyFitStore.instance.preferences.value.isDarkMode, isFalse);
    await tester.tap(find.byTooltip('Chuyển đổi giao diện Sáng / Tối'));
    await tester.pumpAndSettle();
    expect(DailyFitStore.instance.preferences.value.isDarkMode, isTrue);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      const Color(0xFF000000),
    );

    // Kiểm tra Avatar góc trên trái Trang chủ (thay cho logo 3 ngôi sao cũ) -> mở Thông tin cá nhân
    expect(find.byTooltip('Xem thông tin hồ sơ cá nhân'), findsOneWidget);
    await tester.tap(find.byTooltip('Xem thông tin hồ sơ cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('@vuukiendinh · Tài khoản DailyFit'), findsOneWidget);
    expect(find.text('dinh@dailyfit.vn'), findsOneWidget);

    // Chỉnh sửa SĐT, địa chỉ nhà, giới tính ngay trên màn hình Thông tin cá nhân
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profile_phone')),
      '0909123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile_address')),
      '475A Điện Biên Phủ, Bình Thạnh, TP.HCM',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('0909123456'), findsOneWidget);
    expect(find.text('475A Điện Biên Phủ, Bình Thạnh, TP.HCM'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Mở bảng chọn thành phố trên Trang chủ ở chế độ Tối AMOLED và chọn Đà Lạt
    await tester.tap(find.text('TP. Hồ Chí Minh'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn khu vực thời tiết'), findsOneWidget);
    await tester.tap(find.text('Đà Lạt'));
    await tester.pumpAndSettle();

    // Chuyển qua từng tab ở chế độ Tối AMOLED kiểm tra không có bất kỳ lỗi tràn khung hay assertion nào
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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final confirmScheduleBtn = find.text('Xác nhận lưu lịch mặc');
    await tester.ensureVisible(confirmScheduleBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmScheduleBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Chuyển sang Tủ đồ và mở màn hình Thêm đồ ở chế độ Tối AMOLED
    await tester.tap(find.text('Tủ đồ'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Tủ đồ của tôi'), findsOneWidget);

    await tester.tap(find.text('Thêm đồ'));
    await tester.pumpAndSettle();
    expect(find.text('Bổ sung vào tủ đồ'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Bấm vào sản phẩm đầu tiên trong Tủ đồ -> mở Xem chi tiết -> bấm Chỉnh sửa -> Lưu cập nhật
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ClothingCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết trang phục'), findsOneWidget);
    expect(find.text('Hoàn cảnh mặc phù hợp'), findsOneWidget);

    final editDetailBtn = find.text('Chỉnh sửa thông tin trang phục');
    await tester.ensureVisible(editDetailBtn);
    await tester.pumpAndSettle();
    await tester.tap(editDetailBtn);
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa trang phục'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Áo Sơ Mi Oxford Cao Cấp',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final saveUpdateBtn = find.text('Lưu cập nhật trang phục');
    await tester.ensureVisible(saveUpdateBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveUpdateBtn);
    await tester.pumpAndSettle();

    // Quay về màn hình Chi tiết trang phục với tên mới đã cập nhật ngay lập tức
    expect(find.text('Chi tiết trang phục'), findsOneWidget);
    expect(find.text('Áo Sơ Mi Oxford Cao Cấp'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Áo Sơ Mi Oxford Cao Cấp'), findsOneWidget);

    // Chuyển sang Lịch đồ và xác minh đúng 1 ngày đã lên lịch đồng bộ tuyệt đối
    await tester.tap(find.text('Lịch đồ'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Lịch phối đồ'), findsOneWidget);
    expect(DailyFitStore.instance.plannedOutfits.value.length, 1);
    expect(find.textContaining('1 ngày đã lên lịch'), findsOneWidget);

    // Chọn sang ngày mai trên dải tuần -> bấm lên lịch -> đổi hoàn cảnh sang 'Thể thao' -> xác minh lưu đúng bộ Thể thao
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}').first);
    await tester.pumpAndSettle();
    expect(find.text('Chưa có bộ đồ cho ngày này'), findsOneWidget);

    final planDayBtn = find.text('Gợi ý & lên lịch cho ngày này');
    await tester.ensureVisible(planDayBtn);
    await tester.pumpAndSettle();
    await tester.tap(planDayBtn);
    await tester.pumpAndSettle();

    final sportChip = find.widgetWithText(ChoiceChip, 'Thể thao');
    await tester.ensureVisible(sportChip);
    await tester.pumpAndSettle();
    await tester.tap(sportChip);
    await tester.pumpAndSettle();

    final saveTomorrowBtn = find.text('Xác nhận lưu lịch mặc');
    await tester.ensureVisible(saveTomorrowBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveTomorrowBtn);
    await tester.pumpAndSettle();

    final tomorrowPlan = DailyFitStore.instance.getPlanForDate(tomorrow);
    expect(tomorrowPlan, isNotNull);
    expect(tomorrowPlan!.occasion, 'Thể thao');
    expect(tomorrowPlan.outfit.occasion, 'Thể thao');
    expect(DailyFitStore.instance.plannedOutfits.value.length, 2);

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    // Chuyển sang Hồ sơ và kiểm tra hiển thị tài khoản + SĐT/địa chỉ + mở chi tiết hồ sơ
    await tester.tap(find.text('Hồ sơ'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Hồ sơ phong cách'), findsOneWidget);
    expect(find.text('Vưu Kiên Định'), findsOneWidget);
    expect(find.text('@vuukiendinh · dinh@dailyfit.vn'), findsOneWidget);
    expect(
      find.textContaining('0909123456 · 475A Điện Biên Phủ'),
      findsOneWidget,
    );
    expect(find.text('VĐ'), findsOneWidget);
    expect(find.text('Đà Lạt'), findsOneWidget);

    // Bấm vào nút chỉnh sửa hồ sơ trên thẻ Hồ sơ -> mở màn hình Chỉnh sửa hồ sơ -> quay lại
    await tester.tap(find.byTooltip('Xem và chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Đăng xuất quay về màn hình AuthScreen và vào lại bằng chế độ Khách
    await tester.tap(find.text('Đăng xuất tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Tiếp tục với tư cách Khách'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục với tư cách Khách'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vưu Kiên Định'), findsOneWidget);
  });
}
