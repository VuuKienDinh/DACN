import 'package:flutter/material.dart';

import '../config/config_url.dart';
import '../models/user_preferences.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isTestingConnection = false;

  static const List<String> _allStyles = OutfitService.allStyles;

  static const List<String> _allColors = [
    'Xanh dương',
    'Trắng',
    'Đen',
    'Be',
    'Kem',
    'Xám',
    'Nâu',
    'Xanh lá',
    'Hồng',
  ];

  Future<void> _openProfileDetail({bool editMode = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileDetailScreen(initialEditMode: editMode),
      ),
    );
  }

  Future<void> _retestServices() async {
    setState(() => _isTestingConnection = true);
    try {
      await Future.wait([
        ClothingService.instance.loadClothes(),
        DailyFitStore.instance.refreshWeather(),
      ]);
      if (!mounted) return;
      final connected = ClothingService.instance.isOnlineConnected;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected
                ? 'Đã kết nối thành công tới Backend API & dịch vụ thời tiết!'
                : 'Thời tiết đã cập nhật · Backend hiện ngoại tuyến (đang dùng chế độ Offline an toàn).',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = DailyFitStore.instance;
    final clothingService = ClothingService.instance;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          store.currentUser,
          store.isGuestSession,
          store.preferences,
          store.weather,
          store.favorites,
          store.plannedOutfits,
          clothingService.items,
          clothingService.syncStatus,
          clothingService.statusMessage,
        ]),
        builder: (context, _) {
          final authUser = store.currentUser.value;
          final prefs = store.preferences.value;
          final weather = store.weather.value;
          final isBackendLive =
              clothingService.syncStatus.value == BackendSyncStatus.connected;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồ sơ phong cách',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cá nhân hóa sở thích thời trang, màu sắc và giao diện hiển thị.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 18),

                // Thẻ thông tin người dùng (bấm để xem chi tiết SĐT, địa chỉ, email, ảnh đại diện)
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  enableBlur: false,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openProfileDetail(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              UserAvatar(
                                avatarPath: store.activeAvatarPath,
                                displayName: store.activeDisplayName,
                                size: 64,
                                showCameraBadge: true,
                                onTap: () => _openProfileDetail(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.activeDisplayName,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authUser != null
                                          ? '@${authUser.username} · ${authUser.email}'
                                          : 'Chế độ Khách (Guest)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      store.activePhone.isNotEmpty ||
                                              store.activeAddress.isNotEmpty
                                          ? [
                                              if (store.activePhone.isNotEmpty)
                                                store.activePhone,
                                              if (store
                                                  .activeAddress.isNotEmpty)
                                                store.activeAddress,
                                            ].join(' · ')
                                          : 'Bấm để xem hồ sơ, SĐT, địa chỉ & ảnh đại diện ›',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Xem và chỉnh sửa hồ sơ',
                                onPressed: () =>
                                    _openProfileDetail(editMode: true),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger =
                                ScaffoldMessenger.maybeOf(context);
                            final wasLoggedIn = authUser != null;
                            await store.logout();
                            if (wasLoggedIn) {
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã đăng xuất tài khoản thành công.',
                                  ),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: authUser != null
                                ? AppColors.error
                                : AppColors.primary,
                            side: BorderSide(
                              color: (authUser != null
                                      ? AppColors.error
                                      : AppColors.primary)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          icon: Icon(
                            authUser != null
                                ? Icons.logout_rounded
                                : Icons.login_rounded,
                            size: 18,
                          ),
                          label: Text(
                            authUser != null
                                ? 'Đăng xuất tài khoản'
                                : 'Đăng nhập / Tạo tài khoản',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Phong cách cá nhân
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.style_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phong cách cá nhân',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Các phong cách được chọn sẽ được cộng điểm ưu tiên khi gợi ý đồ.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allStyles.map((style) {
                          final active = prefs.preferredStyles.contains(style);
                          return ChoiceChip(
                            label: Text(style),
                            selected: active,
                            onSelected: (_) {
                              store.togglePreferredStyle(style);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Màu sắc yêu thích
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bảng màu yêu thích',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _allColors.map((colorName) {
                          final selected =
                              prefs.favoriteColors.contains(colorName);
                          final swatch = AppColors.swatchForName(colorName);
                          final isLightSwatch = colorName == 'Trắng' ||
                              colorName == 'Kem' ||
                              colorName == 'Be';

                          return GestureDetector(
                            onTap: () => store.toggleFavoriteColor(colorName),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: swatch,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.subtleBorder,
                                      width: selected ? 2.6 : 1.0,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: selected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: isLightSwatch
                                              ? const Color(0xFF2563EB)
                                              : AppColors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  colorName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tùy chọn Giao diện AMOLED, Khu vực & Nhiệt độ
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Giao diện, Khu vực & Thời tiết',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Chế độ tối AMOLED (Đen sâu)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          prefs.isDarkMode
                              ? 'Đang bật nền đen #000000 tiết kiệm pin màn hình AMOLED'
                              : 'Đang dùng giao diện Sáng (Blue & White Glass)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        value: prefs.isDarkMode,
                        activeThumbColor: AppColors.white,
                        onChanged: (val) {
                          store.setDarkMode(val);
                        },
                      ),
                      const Divider(height: 16),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('${prefs.city}_${prefs.isDarkMode}'),
                        initialValue: prefs.city,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: TextStyle(color: AppColors.text, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Thành phố hiện tại',
                          filled: true,
                          fillColor: AppColors.iceSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: UserPreferences.supportedCities.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.name,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            store.updateCity(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Hiển thị nhiệt độ theo độ C (°C)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          prefs.useCelsius
                              ? 'Đang dùng thang đo Celsius (°C)'
                              : 'Đang dùng thang đo Fahrenheit (°F)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        value: prefs.useCelsius,
                        activeThumbColor: AppColors.white,
                        onChanged: (val) {
                          store.setTemperatureUnit(useCelsius: val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Trạng thái Dịch vụ (Trung thực, rõ ràng)
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trạng thái Dịch vụ & Tích hợp',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                _isTestingConnection ? null : _retestServices,
                            icon: _isTestingConnection
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 17),
                            label: const Text('Kiểm tra'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _serviceRow(
                        title: 'Backend API (.NET / SQL Server)',
                        subtitle: clothingService.statusMessage.value,
                        isHealthy: isBackendLive,
                        badgeLabel: isBackendLive ? 'Trực tuyến' : 'Offline',
                      ),
                      const Divider(height: 20),
                      _serviceRow(
                        title: 'Dịch vụ Thời tiết',
                        subtitle: weather != null
                            ? '${weather.sourceLabel} · ${weather.city}'
                            : 'Đang kiểm tra...',
                        isHealthy: weather?.isLive ?? false,
                        badgeLabel:
                            (weather?.isLive ?? false) ? 'Trực tuyến' : 'Mẫu',
                      ),
                      const Divider(height: 20),
                      _serviceRow(
                        title: 'Supabase Cloud (Tuỳ chọn mở rộng)',
                        subtitle: ConfigUrl.hasSupabaseConfig
                            ? 'Đã nhận cấu hình SUPABASE_URL trong .env'
                            : 'Chưa cấu hình trong .env (Sẵn sàng tích hợp sau)',
                        isHealthy: ConfigUrl.hasSupabaseConfig,
                        badgeLabel: ConfigUrl.hasSupabaseConfig
                            ? 'Đã khai báo'
                            : 'Chưa cấu hình',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _serviceRow({
    required String title,
    required String subtitle,
    required bool isHealthy,
    required String badgeLabel,
  }) {
    final badgeColor = isHealthy ? AppColors.success : AppColors.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color:
                  isHealthy ? AppColors.successText : AppColors.warningText,
            ),
          ),
        ),
      ],
    );
  }
}
